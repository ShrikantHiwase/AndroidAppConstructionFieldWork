import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/issues/domain/field_records_repository.dart';
import 'conflict/conflict_policy.dart';
import 'outbox/outbox_entry.dart';
import 'remote/syncable_store.dart';
import 'sync_models.dart';

/// Coordinates outbox flush, sync logging, and local cleanup across modules.
class LocalSyncEngine implements SyncCoordinator {
  LocalSyncEngine({
    required SharedPreferences prefs,
    required FieldRecordsRepository fieldRecords,
    List<SyncableStore> moduleStores = const [],
  })  : _prefs = prefs,
        _fieldRecords = fieldRecords,
        _moduleStores = List.unmodifiable(moduleStores) {
    _loadLogs();
  }

  final SharedPreferences _prefs;
  final FieldRecordsRepository _fieldRecords;
  final List<SyncableStore> _moduleStores;

  static const _logsKey = 'sync.logs';
  static const _lastSyncKey = 'sync.last_success_at';
  static const _lastFailureKey = 'sync.last_failure';

  final _logs = <SyncLogEntry>[];
  final _logsController = StreamController<List<SyncLogEntry>>.broadcast();
  final _pendingController = StreamController<int>.broadcast();

  int _seq = 0;
  DateTime? lastSuccessAt;
  String? lastFailure;

  void _loadLogs() {
    final raw = _prefs.getString(_lastSyncKey);
    if (raw != null) lastSuccessAt = DateTime.tryParse(raw);
    lastFailure = _prefs.getString(_lastFailureKey);
    for (final row in _prefs.getStringList(_logsKey) ?? const []) {
      _logs.add(
        SyncLogEntry.fromJson(Map<String, Object?>.from(jsonDecode(row) as Map)),
      );
    }
  }

  Future<void> _persistMeta() async {
    if (lastSuccessAt != null) {
      await _prefs.setString(_lastSyncKey, lastSuccessAt!.toIso8601String());
    }
    if (lastFailure == null) {
      await _prefs.remove(_lastFailureKey);
    } else {
      await _prefs.setString(_lastFailureKey, lastFailure!);
    }
    await _prefs.setStringList(
      _logsKey,
      _logs.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _logsController.add(List.unmodifiable(_logs));
  }

  Future<void> _appendLog(SyncLogEntry entry) async {
    _logs.insert(0, entry);
    await cleanupLogs(persist: false);
    await _persistMeta();
  }

  Stream<List<SyncLogEntry>> watchLogs() async* {
    yield List.unmodifiable(_logs);
    yield* _logsController.stream;
  }

  Future<int> totalPending() async {
    var n = await _fieldRecords.watchPendingSyncCount().first;
    for (final store in _moduleStores) {
      n += await store.watchPendingSyncCount().first;
    }
    return n;
  }

  @override
  Stream<int> get pendingCount => watchPendingTotal();

  /// Live total pending across field + module stores.
  Stream<int> watchPendingTotal() {
    late StreamController<int> controller;
    final subs = <StreamSubscription<int>>[];

    Future<void> pump() async {
      if (!controller.isClosed) {
        controller.add(await totalPending());
      }
    }

    controller = StreamController<int>.broadcast(
      onListen: () {
        unawaited(pump());
        subs.addAll([
          _fieldRecords.watchPendingSyncCount().listen((_) => pump()),
          ..._moduleStores.map(
            (s) => s.watchPendingSyncCount().listen((_) => pump()),
          ),
          _pendingController.stream.listen(controller.add),
        ]);
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        subs.clear();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    await _appendLog(
      SyncLogEntry(
        id: _id('log'),
        at: DateTime.now().toUtc(),
        message:
            'Queued ${entry.operation.name} ${entry.collection}/${entry.documentId} '
            '(${ConflictPolicy.describe(ConflictPolicy.forCollection(entry.collection))})',
        level: SyncLogLevel.info,
      ),
    );
  }

  @override
  Future<void> flush() async {
    await flushNow(isOnline: true);
  }

  Future<int> flushNow({required bool isOnline, String? projectId}) async {
    final before = await totalPending();
    if (!isOnline) {
      await _appendLog(
        SyncLogEntry(
          id: _id('log'),
          at: DateTime.now().toUtc(),
          message: 'Flush skipped — offline ($before pending)',
          level: SyncLogLevel.warn,
          pendingAfter: before,
        ),
      );
      _pendingController.add(before);
      return 0;
    }

    try {
      await _fieldRecords.flushOutbox(isOnline: true);
      for (final store in _moduleStores) {
        await store.flushOutbox(isOnline: true);
      }
      final after = await totalPending();
      final flushed = (before - after).clamp(0, before);
      lastSuccessAt = DateTime.now().toUtc();
      lastFailure = null;
      var pullNote = '';
      if (projectId != null) {
        final fieldPull =
            await _fieldRecords.pullRemote(projectId: projectId);
        var modulePulled = 0;
        for (final store in _moduleStores) {
          modulePulled += await store.pullRemote(projectId: projectId);
        }
        final parts = <String>[];
        if (fieldPull.issues > 0 || fieldPull.rfis > 0) {
          parts.add(
            '${fieldPull.issues} issue(s), ${fieldPull.rfis} RFI(s)',
          );
        }
        if (modulePulled > 0) {
          parts.add('$modulePulled module row(s)');
        }
        if (parts.isNotEmpty) {
          pullNote = '; pulled ${parts.join('; ')}';
        }
      }
      await _appendLog(
        SyncLogEntry(
          id: _id('log'),
          at: lastSuccessAt!,
          message: flushed == 0
              ? 'Flush complete — nothing pending$pullNote'
              : 'Flushed $flushed outbox item(s)$pullNote',
          level: SyncLogLevel.info,
          pendingAfter: after,
          flushedCount: flushed,
        ),
      );
      _pendingController.add(after);
      return flushed;
    } catch (e) {
      lastFailure = e.toString();
      await _appendLog(
        SyncLogEntry(
          id: _id('log'),
          at: DateTime.now().toUtc(),
          message: 'Flush failed: $e',
          level: SyncLogLevel.error,
          pendingAfter: before,
        ),
      );
      rethrow;
    }
  }

  Future<SyncCleanupResult> cleanupLogs({bool persist = true}) async {
    final before = _logs.length;
    final cutoff = DateTime.now().toUtc().subtract(SyncCleanupPolicy.logRetention);
    _logs.removeWhere((e) => e.at.isBefore(cutoff));
    if (_logs.length > SyncCleanupPolicy.maxLogEntries) {
      _logs.removeRange(SyncCleanupPolicy.maxLogEntries, _logs.length);
    }
    final removed = before - _logs.length;
    if (persist) await _persistMeta();
    return SyncCleanupResult(
      removedLogEntries: removed,
      bytesFreedEstimate: removed * 180,
    );
  }

  /// Manual + auto cleanup entry point for low-end devices.
  Future<SyncCleanupResult> runStorageCleanup() async {
    final result = await cleanupLogs();
    await _appendLog(
      SyncLogEntry(
        id: _id('log'),
        at: DateTime.now().toUtc(),
        message:
            'Cleanup removed ${result.removedLogEntries} log(s); '
            '~${result.bytesFreedEstimate}B freed (estimate)',
        level: SyncLogLevel.info,
      ),
    );
    return result;
  }

  String _id(String prefix) {
    _seq += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }
}
