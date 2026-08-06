import '../../features/issues/domain/issue_models.dart';

/// Pulls remote field documents into the local cache (optional).
abstract class FieldRemotePull {
  Future<List<Issue>> pullIssues(String projectId);
  Future<List<Rfi>> pullRfis(String projectId);
}

class NoOpFieldRemotePull implements FieldRemotePull {
  const NoOpFieldRemotePull();

  @override
  Future<List<Issue>> pullIssues(String projectId) async => const [];

  @override
  Future<List<Rfi>> pullRfis(String projectId) async => const [];
}
