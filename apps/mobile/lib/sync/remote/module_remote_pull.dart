import '../../features/documents/domain/document_models.dart';
import '../../features/dpr/domain/dpr_models.dart';
import '../../features/site_ops/domain/site_ops_models.dart';

/// Pulls DPR / site-ops / documents / pins from a remote backend.
abstract class ModuleRemotePull {
  Future<List<DailyProgressReport>> pullDprs(String projectId);
  Future<List<SafetyRecord>> pullSafety(String projectId);
  Future<List<QaInspection>> pullInspections(String projectId);
  Future<List<LabourMuster>> pullMuster(String projectId);
  Future<List<MaterialLog>> pullMaterials(String projectId);
  Future<List<DocFolder>> pullFolders(String projectId);
  Future<List<ProjectDocument>> pullDocuments(String projectId);
  Future<List<DrawingPin>> pullPins(String projectId);
}

/// Demo / offline — never contacts the network.
class NoOpModuleRemotePull implements ModuleRemotePull {
  const NoOpModuleRemotePull();

  @override
  Future<List<DailyProgressReport>> pullDprs(String projectId) async =>
      const [];

  @override
  Future<List<SafetyRecord>> pullSafety(String projectId) async => const [];

  @override
  Future<List<QaInspection>> pullInspections(String projectId) async =>
      const [];

  @override
  Future<List<LabourMuster>> pullMuster(String projectId) async => const [];

  @override
  Future<List<MaterialLog>> pullMaterials(String projectId) async => const [];

  @override
  Future<List<DocFolder>> pullFolders(String projectId) async => const [];

  @override
  Future<List<ProjectDocument>> pullDocuments(String projectId) async =>
      const [];

  @override
  Future<List<DrawingPin>> pullPins(String projectId) async => const [];
}
