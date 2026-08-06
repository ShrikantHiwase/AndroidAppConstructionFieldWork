/// Local outbox entry waiting for background sync to Firestore/Storage.
///
/// Conflict policy (plan default):
/// - scalar fields → last-write-wins
/// - comments / photos → append-only
/// - status changes → audited
///
/// See [ConflictPolicy] in `sync/conflict/conflict_policy.dart`.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final String collection;
  final String documentId;
  final OutboxOperation operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
}

enum OutboxOperation { create, update, delete, upload }

/// Sync coordinator contract. [LocalSyncEngine] implements logging + flush;
/// Drift + Workmanager replace the persistence layer after Firebase configure.
abstract class SyncCoordinator {
  Future<void> enqueue(OutboxEntry entry);
  Future<void> flush();
  Stream<int> get pendingCount;
}
