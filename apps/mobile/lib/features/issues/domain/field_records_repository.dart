import '../../auth/domain/auth_models.dart';
import 'issue_models.dart';

abstract class FieldRecordsRepository {
  Stream<List<Issue>> watchIssues(String projectId);
  Stream<List<Rfi>> watchRfis(String projectId);
  Stream<List<FieldComment>> watchComments({
    required String parentType,
    required String parentId,
  });
  Stream<int> watchPendingSyncCount();

  Future<Issue> createIssue({
    required AuthSession session,
    required CreateIssueInput input,
  });

  Future<Issue> updateIssueStatus({
    required AuthSession session,
    required String issueId,
    required IssueStatus status,
  });

  Future<Issue> assignIssue({
    required AuthSession session,
    required String issueId,
    required String assigneeId,
    required String assigneeName,
  });

  Future<Rfi> createRfi({
    required AuthSession session,
    required CreateRfiInput input,
  });

  Future<Rfi> updateRfiStatus({
    required AuthSession session,
    required String rfiId,
    required IssueStatus status,
  });

  Future<FieldComment> addComment({
    required AuthSession session,
    required String parentType,
    required String parentId,
    required String body,
  });

  /// Flush outbox to remote sink (Firestore when enabled) then mark local synced.
  Future<void> flushOutbox({required bool isOnline});

  /// Pull remote issues/RFIs into the local cache (no-op in demo mode).
  Future<({int issues, int rfis})> pullRemote({required String projectId});
}
