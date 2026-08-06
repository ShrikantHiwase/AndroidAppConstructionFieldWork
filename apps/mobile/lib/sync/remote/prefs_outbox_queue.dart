import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../outbox/outbox_entry.dart';
import 'outbox_remote_sink.dart';

/// Shared Preferences-backed outbox helper for feature repositories.
class PrefsOutboxQueue {
  PrefsOutboxQueue(this._prefs, this._key);

  final SharedPreferences _prefs;
  final String _key;
  final entries = <OutboxEntry>[];
  final pendingController = StreamController<int>.broadcast();
  int _seq = 0;

  void load() {
    entries.clear();
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      final map = Map<String, Object?>.from(jsonDecode(raw) as Map);
      entries.add(
        OutboxEntry(
          id: map['id'] as String,
          collection: map['collection'] as String,
          documentId: map['documentId'] as String,
          operation: OutboxOperation.values
              .byName(map['operation'] as String? ?? 'create'),
          payload: Map<String, Object?>.from(map['payload'] as Map? ?? {}),
          createdAt: DateTime.parse(map['createdAt'] as String),
          attempts: map['attempts'] as int? ?? 0,
          lastError: map['lastError'] as String?,
        ),
      );
    }
  }

  Future<void> persist() async {
    await _prefs.setStringList(
      _key,
      entries
          .map(
            (e) => jsonEncode({
              'id': e.id,
              'collection': e.collection,
              'documentId': e.documentId,
              'operation': e.operation.name,
              'payload': e.payload,
              'createdAt': e.createdAt.toIso8601String(),
              'attempts': e.attempts,
              'lastError': e.lastError,
            }),
          )
          .toList(),
    );
    pendingController.add(entries.length);
  }

  void enqueue({
    required String collection,
    required String documentId,
    required OutboxOperation operation,
    required Map<String, Object?> payload,
  }) {
    _seq += 1;
    entries.add(
      OutboxEntry(
        id: 'outbox_${DateTime.now().microsecondsSinceEpoch}_$_seq',
        collection: collection,
        documentId: documentId,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Stream<int> watchPending() async* {
    yield entries.length;
    yield* pendingController.stream;
  }

  /// Applies each entry via [sink]; [onApplied] marks local docs synced.
  /// Failed entries stay in the queue with incremented attempts.
  Future<void> flush({
    required bool isOnline,
    required OutboxRemoteSink sink,
    required FutureOr<void> Function(OutboxEntry entry) onApplied,
  }) async {
    if (!isOnline || entries.isEmpty) {
      pendingController.add(entries.length);
      return;
    }
    final remaining = <OutboxEntry>[];
    for (final entry in List<OutboxEntry>.from(entries)) {
      try {
        await sink.apply(entry);
        await onApplied(entry);
      } catch (e) {
        remaining.add(
          OutboxEntry(
            id: entry.id,
            collection: entry.collection,
            documentId: entry.documentId,
            operation: entry.operation,
            payload: entry.payload,
            createdAt: entry.createdAt,
            attempts: entry.attempts + 1,
            lastError: e.toString(),
          ),
        );
      }
    }
    entries
      ..clear()
      ..addAll(remaining);
    await persist();
  }
}
