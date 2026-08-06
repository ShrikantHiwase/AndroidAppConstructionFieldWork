/// Local store that participates in offline outbox flush + remote pull.
abstract class SyncableStore {
  Stream<int> watchPendingSyncCount();

  Future<void> flushOutbox({required bool isOnline});

  /// Merge remote docs for [projectId]; returns how many local rows changed.
  Future<int> pullRemote({required String projectId});
}
