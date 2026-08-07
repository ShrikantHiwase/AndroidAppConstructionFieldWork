import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sync/remote/field_remote_pull.dart';
import '../../../sync/remote/firestore_field_remote_pull.dart';
import '../../../sync/remote/firestore_outbox_remote_sink.dart';
import '../../../sync/remote/firebase_storage_uploader.dart';
import '../../../sync/remote/outbox_remote_sink.dart';
import '../../../sync/remote/storage_uploader.dart';
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

final storageUploaderProvider = Provider<StorageUploader>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return FirebaseStorageUploader();
  }
  return const NoOpStorageUploader();
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
    storageUploader: ref.watch(storageUploaderProvider),
  );
});

final fieldRecordsSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  await ref
      .read(fieldRecordsRepositoryProvider)
      .ensureSeedFieldRecords(session);
});

final issuesProvider = StreamProvider<List<Issue>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(fieldRecordsSeedProvider.future);
  yield* ref
      .watch(fieldRecordsRepositoryProvider)
      .watchIssues(session.activeProjectId);
});

final rfisProvider = StreamProvider<List<Rfi>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(fieldRecordsSeedProvider.future);
  yield* ref
      .watch(fieldRecordsRepositoryProvider)
      .watchRfis(session.activeProjectId);
});

final commentsProvider = StreamProvider.family<List<FieldComment>, ({String type, String id})>((ref, key) {
  return ref.watch(fieldRecordsRepositoryProvider).watchComments(
        parentType: key.type,
        parentId: key.id,
      );
});
