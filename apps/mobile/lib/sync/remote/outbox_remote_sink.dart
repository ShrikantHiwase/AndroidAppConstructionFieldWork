import '../outbox/outbox_entry.dart';

/// Applies a local outbox entry to a remote backend (Firestore when enabled).
abstract class OutboxRemoteSink {
  Future<void> apply(OutboxEntry entry);
}

/// Demo / CI path — flush only marks local docs synced.
class NoOpOutboxRemoteSink implements OutboxRemoteSink {
  const NoOpOutboxRemoteSink();

  @override
  Future<void> apply(OutboxEntry entry) async {}
}
