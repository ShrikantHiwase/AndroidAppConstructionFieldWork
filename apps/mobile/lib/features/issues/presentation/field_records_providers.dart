import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sync/remote/field_remote_pull.dart';
import '../../../sync/remote/firestore_field_remote_pull.dart';
import '../../../sync/remote/firestore_outbox_remote_sink.dart';
import '../../../sync/remote/outbox_remote_sink.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/local_field_records_repository.dart';
import '../domain/field_records_repository.dart';
import '../domain/issue_models.dart';

final outboxRemoteSinkProvider = Provider<OutboxRemoteSink>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return FirestoreOutboxRemoteSink();
  }
  return const NoOpOutboxRemoteSink();
});

final fieldRemotePullProvider = Provider<FieldRemotePull>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return FirestoreFieldRemotePull();
  }
  return const NoOpFieldRemotePull();
});

final fieldRecordsRepositoryProvider = Provider<FieldRecordsRepository>((ref) {
  return LocalFieldRecordsRepository(
    ref.watch(sharedPreferencesProvider),
    remoteSink: ref.watch(outboxRemoteSinkProvider),
    remotePull: ref.watch(fieldRemotePullProvider),
  );
});

final issuesProvider = StreamProvider<List<Issue>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref
      .watch(fieldRecordsRepositoryProvider)
      .watchIssues(session.activeProjectId);
});

final rfisProvider = StreamProvider<List<Rfi>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref
      .watch(fieldRecordsRepositoryProvider)
      .watchRfis(session.activeProjectId);
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(fieldRecordsRepositoryProvider).watchPendingSyncCount();
});

final commentsProvider = StreamProvider.family<List<FieldComment>, ({String type, String id})>((ref, key) {
  return ref.watch(fieldRecordsRepositoryProvider).watchComments(
        parentType: key.type,
        parentId: key.id,
      );
});
