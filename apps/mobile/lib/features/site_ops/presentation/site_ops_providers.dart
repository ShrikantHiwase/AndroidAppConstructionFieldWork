import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/local_site_ops_repository.dart';
import '../domain/site_ops_models.dart';

final siteOpsRepositoryProvider = Provider<SiteOpsRepository>((ref) {
  return LocalSiteOpsRepository(ref.watch(sharedPreferencesProvider));
});

final safetyProvider = StreamProvider<List<SafetyRecord>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref.watch(siteOpsRepositoryProvider).watchSafety(session.activeProjectId);
});

final inspectionsProvider = StreamProvider<List<QaInspection>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref
      .watch(siteOpsRepositoryProvider)
      .watchInspections(session.activeProjectId);
});

final musterProvider = StreamProvider<List<LabourMuster>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref.watch(siteOpsRepositoryProvider).watchMuster(session.activeProjectId);
});

final materialsProvider = StreamProvider<List<MaterialLog>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref
      .watch(siteOpsRepositoryProvider)
      .watchMaterials(session.activeProjectId);
});
