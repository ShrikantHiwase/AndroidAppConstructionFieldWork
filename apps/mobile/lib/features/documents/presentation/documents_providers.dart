import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../data/local_documents_repository.dart';
import '../domain/document_models.dart';
import '../domain/documents_repository.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return LocalDocumentsRepository(
    ref.watch(sharedPreferencesProvider),
    remoteSink: ref.watch(outboxRemoteSinkProvider),
    remotePull: ref.watch(moduleRemotePullProvider),
  );
});

final documentsSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  await ref.read(documentsRepositoryProvider).ensureSeedData(session);
});

final foldersProvider = StreamProvider<List<DocFolder>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(documentsSeedProvider.future);
  yield* ref
      .watch(documentsRepositoryProvider)
      .watchFolders(session.activeProjectId);
});

final documentsInFolderProvider =
    StreamProvider.family<List<ProjectDocument>, String?>((ref, folderId) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(documentsSeedProvider.future);
  yield* ref.watch(documentsRepositoryProvider).watchDocuments(
        projectId: session.activeProjectId,
        folderId: folderId,
      );
});
