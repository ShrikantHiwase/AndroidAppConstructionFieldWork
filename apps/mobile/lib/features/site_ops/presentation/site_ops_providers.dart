import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../data/local_site_ops_repository.dart';
import '../domain/site_ops_models.dart';

final siteOpsRepositoryProvider = Provider<SiteOpsRepository>((ref) {
  return LocalSiteOpsRepository(
    ref.watch(sharedPreferencesProvider),
    remoteSink: ref.watch(outboxRemoteSinkProvider),
    remotePull: ref.watch(moduleRemotePullProvider),
    storageUploader: ref.watch(storageUploaderProvider),
  );
});

final siteOpsSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  await ref.read(siteOpsRepositoryProvider).ensureSeedSiteOps(session);
});

final safetyProvider = StreamProvider<List<SafetyRecord>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(siteOpsSeedProvider.future);
  yield* ref.watch(siteOpsRepositoryProvider).watchSafety(session.activeProjectId);
});

final inspectionsProvider = StreamProvider<List<QaInspection>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(siteOpsSeedProvider.future);
  yield* ref
      .watch(siteOpsRepositoryProvider)
      .watchInspections(session.activeProjectId);
});

final musterProvider = StreamProvider<List<LabourMuster>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(siteOpsSeedProvider.future);
  yield* ref.watch(siteOpsRepositoryProvider).watchMuster(session.activeProjectId);
});

final materialsProvider = StreamProvider<List<MaterialLog>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(siteOpsSeedProvider.future);
  yield* ref
      .watch(siteOpsRepositoryProvider)
      .watchMaterials(session.activeProjectId);
});
