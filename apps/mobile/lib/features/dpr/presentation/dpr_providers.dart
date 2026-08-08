import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sync/remote/firestore_module_pull.dart';
import '../../../sync/remote/module_remote_pull.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../data/local_dpr_repository.dart';
import '../domain/dpr_models.dart';
import '../domain/dpr_repository.dart';

final moduleRemotePullProvider = Provider<ModuleRemotePull>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return FirestoreModulePull();
  }
  return const NoOpModuleRemotePull();
});

final dprRepositoryProvider = Provider<DprRepository>((ref) {
  return LocalDprRepository(
    ref.watch(sharedPreferencesProvider),
    remoteSink: ref.watch(outboxRemoteSinkProvider),
    remotePull: ref.watch(moduleRemotePullProvider),
    storageUploader: ref.watch(storageUploaderProvider),
  );
});

final drawingPinsRepositoryProvider = Provider<DrawingPinsRepository>((ref) {
  return LocalDrawingPinsRepository(
    ref.watch(sharedPreferencesProvider),
    remoteSink: ref.watch(outboxRemoteSinkProvider),
    remotePull: ref.watch(moduleRemotePullProvider),
    storageUploader: ref.watch(storageUploaderProvider),
  );
});

final dprSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  await ref.read(dprRepositoryProvider).ensureSeedDprs(session);
});

final dprsProvider = StreamProvider<List<DailyProgressReport>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(dprSeedProvider.future);
  yield* ref.watch(dprRepositoryProvider).watchDprs(session.activeProjectId);
});

final drawingsSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  await ref.read(drawingPinsRepositoryProvider).ensureSeedDrawings(session);
});

final drawingsProvider = StreamProvider<List<DrawingSheet>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(drawingsSeedProvider.future);
  yield* ref
      .watch(drawingPinsRepositoryProvider)
      .watchDrawings(session.activeProjectId);
});

final pinsProvider =
    StreamProvider.family<List<DrawingPin>, String>((ref, drawingId) {
  return ref.watch(drawingPinsRepositoryProvider).watchPins(drawingId);
});
