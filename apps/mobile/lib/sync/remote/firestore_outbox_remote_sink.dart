import 'package:cloud_firestore/cloud_firestore.dart';

import '../outbox/outbox_entry.dart';
import 'outbox_remote_sink.dart';

/// Writes outbox payloads to Cloud Firestore.
///
/// Used only when Firebase is bootstrapped (`firebaseEnabledProvider == true`).
/// Payload maps come from local `toJson()` (ISO strings, nested maps).
class FirestoreOutboxRemoteSink implements OutboxRemoteSink {
  FirestoreOutboxRemoteSink({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> apply(OutboxEntry entry) async {
    final ref = _db.collection(entry.collection).doc(entry.documentId);
    switch (entry.operation) {
      case OutboxOperation.create:
      case OutboxOperation.update:
        final data = Map<String, Object?>.from(entry.payload)
          ..['synced'] = true
          ..['updatedAt'] = entry.payload['updatedAt'] ??
              DateTime.now().toUtc().toIso8601String();
        await ref.set(_sanitize(data), SetOptions(merge: true));
      case OutboxOperation.delete:
        await ref.delete();
      case OutboxOperation.upload:
        // Storage upload path is separate; treat as acknowledged for outbox.
        return;
    }
  }

  /// Drop top-level nulls — Firestore merge treats null as delete.
  Map<String, Object?> _sanitize(Map<String, Object?> input) {
    final out = <String, Object?>{};
    for (final e in input.entries) {
      if (e.value == null) continue;
      out[e.key] = e.value;
    }
    return out;
  }
}
