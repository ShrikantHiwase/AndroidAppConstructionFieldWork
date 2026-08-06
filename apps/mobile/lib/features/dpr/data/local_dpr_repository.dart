import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../sync/outbox/outbox_entry.dart';
import '../../../sync/remote/module_remote_pull.dart';
import '../../../sync/remote/outbox_remote_sink.dart';
import '../../../sync/remote/prefs_outbox_queue.dart';
import '../../../sync/remote/syncable_store.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/dpr_models.dart';
import '../domain/dpr_repository.dart';

class LocalDprRepository implements DprRepository, SyncableStore {
  LocalDprRepository(
    this._prefs, {
    OutboxRemoteSink? remoteSink,
    ModuleRemotePull? remotePull,
  })  : _remoteSink = remoteSink ?? const NoOpOutboxRemoteSink(),
        _remotePull = remotePull ?? const NoOpModuleRemotePull(),
        _outbox = PrefsOutboxQueue(_prefs, _outboxKey) {
    _load();
  }

  final SharedPreferences _prefs;
  final OutboxRemoteSink _remoteSink;
  final ModuleRemotePull _remotePull;
  final PrefsOutboxQueue _outbox;

  static const _key = 'dpr.reports';
  static const _outboxKey = 'dpr.outbox';

  final _items = <String, DailyProgressReport>{};
  final _controller = StreamController<List<DailyProgressReport>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      final dpr = DailyProgressReport.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _items[dpr.id] = dpr;
    }
    _outbox.load();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _outbox.persist();
    _controller.add(_items.values.toList());
  }

  String _dayKey(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).toIso8601String();

  List<DailyProgressReport> _forProject(String projectId) {
    final list = _items.values.where((d) => d.projectId == projectId).toList()
      ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
    return list;
  }

  void _enqueueUpsert(DailyProgressReport dpr) {
    _outbox.enqueue(
      collection: FirestoreCollections.dprs,
      documentId: dpr.id,
      operation: OutboxOperation.create,
      payload: dpr.toJson(),
    );
  }

  @override
  Stream<List<DailyProgressReport>> watchDprs(String projectId) async* {
    yield _forProject(projectId);
    yield* _controller.stream.map((_) => _forProject(projectId));
  }

  @override
  Future<DailyProgressReport?> todayDpr(String projectId, DateTime day) async {
    final key = _dayKey(day.toUtc());
    for (final dpr in _items.values) {
      if (dpr.projectId == projectId && _dayKey(dpr.reportDate) == key) {
        return dpr;
      }
    }
    return null;
  }

  @override
  Future<DailyProgressReport> createOrUpdateToday({
    required AuthSession session,
    required CreateDprInput input,
  }) async {
    if (!canEditDpr(session.activeRole)) {
      throw DprException('Client accounts cannot edit DPR');
    }
    final day = (input.reportDate ?? DateTime.now()).toUtc();
    final existing = await todayDpr(session.activeProjectId, day);
    final now = DateTime.now().toUtc();
    if (existing != null) {
      if (existing.submitted) {
        throw DprException('Today\'s DPR is already submitted');
      }
      final updated = existing.copyWith(
        weather: input.weather.trim(),
        manpowerSummary: input.manpowerSummary.trim(),
        activities: input.activities,
        blockers: input.blockers.trim(),
        synced: false,
        updatedAt: now,
      );
      _items[existing.id] = updated;
      _enqueueUpsert(updated);
      await _persist();
      return updated;
    }

    final dpr = DailyProgressReport(
      id: 'dpr_${now.microsecondsSinceEpoch}_${++_seq}',
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      reportDate: DateTime.utc(day.year, day.month, day.day),
      weather: input.weather.trim(),
      manpowerSummary: input.manpowerSummary.trim(),
      activities: input.activities,
      blockers: input.blockers.trim(),
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      updatedAt: now,
    );
    _items[dpr.id] = dpr;
    _enqueueUpsert(dpr);
    await _persist();
    return dpr;
  }

  @override
  Future<DailyProgressReport> submit({
    required AuthSession session,
    required String dprId,
  }) async {
    if (!canEditDpr(session.activeRole)) {
      throw DprException('Client accounts cannot submit DPR');
    }
    final current = _items[dprId];
    if (current == null) throw DprException('DPR not found');
    if (current.projectId != session.activeProjectId) {
      throw DprException('DPR is not in the active project');
    }
    if (current.activities.isEmpty) {
      throw DprException('Add at least one activity before submit');
    }
    final updated = current.copyWith(
      submitted: true,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    _items[dprId] = updated;
    _enqueueUpsert(updated);
    await _persist();
    return updated;
  }

  @override
  Stream<int> watchPendingSyncCount() => _outbox.watchPending();

  @override
  Future<void> flushOutbox({required bool isOnline}) async {
    await _outbox.flush(
      isOnline: isOnline,
      sink: _remoteSink,
      onApplied: (entry) async {
        final current = _items[entry.documentId];
        if (current != null) {
          _items[entry.documentId] = current.copyWith(synced: true);
        }
      },
    );
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _controller.add(_items.values.toList());
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    final remote = await _remotePull.pullDprs(projectId);
    var changed = 0;
    for (final r in remote) {
      final local = _items[r.id];
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        _items[r.id] = DailyProgressReport(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          reportDate: r.reportDate,
          weather: r.weather,
          manpowerSummary: r.manpowerSummary,
          activities: r.activities,
          blockers: r.blockers,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          submitted: r.submitted,
          synced: true,
        );
        changed += 1;
      }
    }
    if (changed > 0) {
      await _prefs.setStringList(
        _key,
        _items.values.map((e) => jsonEncode(e.toJson())).toList(),
      );
      _controller.add(_items.values.toList());
    }
    return changed;
  }
}

class LocalDrawingPinsRepository
    implements DrawingPinsRepository, SyncableStore {
  LocalDrawingPinsRepository(
    this._prefs, {
    OutboxRemoteSink? remoteSink,
    ModuleRemotePull? remotePull,
  })  : _remoteSink = remoteSink ?? const NoOpOutboxRemoteSink(),
        _remotePull = remotePull ?? const NoOpModuleRemotePull(),
        _outbox = PrefsOutboxQueue(_prefs, _outboxKey) {
    _load();
  }

  final SharedPreferences _prefs;
  final OutboxRemoteSink _remoteSink;
  final ModuleRemotePull _remotePull;
  final PrefsOutboxQueue _outbox;

  static const _drawingsKey = 'drawings.sheets';
  static const _pinsKey = 'drawings.pins';
  static const _seededKey = 'drawings.seeded';
  static const _outboxKey = 'drawings.outbox';

  final _drawings = <String, DrawingSheet>{};
  final _pins = <String, DrawingPin>{};
  final _drawingsController = StreamController<List<DrawingSheet>>.broadcast();
  final _pinsController = StreamController<List<DrawingPin>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_drawingsKey) ?? const []) {
      final sheet = DrawingSheet.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _drawings[sheet.id] = sheet;
    }
    for (final raw in _prefs.getStringList(_pinsKey) ?? const []) {
      final pin = DrawingPin.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _pins[pin.id] = pin;
    }
    _outbox.load();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _drawingsKey,
      _drawings.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _pinsKey,
      _pins.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _outbox.persist();
    _drawingsController.add(_drawings.values.toList());
    _pinsController.add(_pins.values.toList());
  }

  @override
  Future<void> ensureSeedDrawings(AuthSession session) async {
    final seeded = _prefs.getStringList(_seededKey) ?? [];
    if (seeded.contains(session.activeProjectId)) return;
    final sheet = DrawingSheet(
      id: 'drawing_${session.activeProjectId}_ga02',
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      title: 'GA Plan Level 02',
      version: 'Rev B',
      pageCount: 3,
    );
    _drawings[sheet.id] = sheet;
    seeded.add(session.activeProjectId);
    await _prefs.setStringList(_seededKey, seeded);
    await _persist();
  }

  @override
  Stream<List<DrawingSheet>> watchDrawings(String projectId) async* {
    List<DrawingSheet> filter() =>
        _drawings.values.where((d) => d.projectId == projectId).toList();
    yield filter();
    yield* _drawingsController.stream.map((_) => filter());
  }

  @override
  Stream<List<DrawingPin>> watchPins(String drawingId) async* {
    List<DrawingPin> filter() => _pins.values
        .where((p) => p.drawingId == drawingId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    yield filter();
    yield* _pinsController.stream.map((_) => filter());
  }

  @override
  Future<DrawingPin> addPin({
    required AuthSession session,
    required CreatePinInput input,
  }) async {
    if (!canPinDrawings(session.activeRole)) {
      throw DrawingException('Client accounts cannot pin drawings');
    }
    final sheet = _drawings[input.drawingId];
    if (sheet == null || sheet.projectId != session.activeProjectId) {
      throw DrawingException('Drawing not found');
    }
    if (input.page < 1 || input.page > sheet.pageCount) {
      throw DrawingException('Page out of range');
    }
    if (input.x < 0 || input.x > 1 || input.y < 0 || input.y > 1) {
      throw DrawingException('Pin must be within the drawing page');
    }
    final pin = DrawingPin(
      id: 'pin_${DateTime.now().microsecondsSinceEpoch}_${++_seq}',
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      drawingId: input.drawingId,
      page: input.page,
      x: input.x,
      y: input.y,
      issueId: input.issueId,
      issueTitle: input.issueTitle,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
      note: input.note,
    );
    _pins[pin.id] = pin;
    _outbox.enqueue(
      collection: FirestoreCollections.drawingPins,
      documentId: pin.id,
      operation: OutboxOperation.create,
      payload: pin.toJson(),
    );
    await _persist();
    return pin;
  }

  @override
  Stream<int> watchPendingSyncCount() => _outbox.watchPending();

  @override
  Future<void> flushOutbox({required bool isOnline}) async {
    await _outbox.flush(
      isOnline: isOnline,
      sink: _remoteSink,
      onApplied: (entry) async {
        final current = _pins[entry.documentId];
        if (current != null) {
          _pins[entry.documentId] = current.copyWith(synced: true);
        }
      },
    );
    await _prefs.setStringList(
      _pinsKey,
      _pins.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _pinsController.add(_pins.values.toList());
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    final remote = await _remotePull.pullPins(projectId);
    var changed = 0;
    for (final r in remote) {
      if (!_pins.containsKey(r.id)) {
        _pins[r.id] = DrawingPin(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          drawingId: r.drawingId,
          page: r.page,
          x: r.x,
          y: r.y,
          issueId: r.issueId,
          issueTitle: r.issueTitle,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          note: r.note,
          synced: true,
        );
        changed += 1;
      }
    }
    if (changed > 0) {
      await _prefs.setStringList(
        _pinsKey,
        _pins.values.map((e) => jsonEncode(e.toJson())).toList(),
      );
      _pinsController.add(_pins.values.toList());
    }
    return changed;
  }
}
