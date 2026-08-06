import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/sync/outbox/outbox_entry.dart';
import 'package:construction_field_app/sync/remote/field_remote_pull.dart';
import 'package:construction_field_app/sync/remote/outbox_remote_sink.dart';

class _RecordingSink implements OutboxRemoteSink {
  final applied = <OutboxEntry>[];

  @override
  Future<void> apply(OutboxEntry entry) async {
    applied.add(entry);
  }
}

class _StubPull implements FieldRemotePull {
  _StubPull({this.issues = const []});

  final List<Issue> issues;

  @override
  Future<List<Issue>> pullIssues(String projectId) async =>
      issues.where((i) => i.projectId == projectId).toList();

  @override
  Future<List<Rfi>> pullRfis(String projectId) async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('flushOutbox pushes entries to remote sink then clears outbox', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final field = LocalFieldRecordsRepository(prefs, remoteSink: sink);
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await field.createIssue(
      session: session,
      input: const CreateIssueInput(title: 'Cloud pour', description: ''),
    );
    expect(await field.watchPendingSyncCount().first, 1);

    await field.flushOutbox(isOnline: true);
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.collection, 'issues');
    expect(await field.watchPendingSyncCount().first, 0);
  });

  test('pullRemote merges newer remote issues', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.utc(2026, 8, 6);
    final remote = Issue(
      id: 'issue_remote_1',
      orgId: 'org_demo',
      projectId: 'proj_pune_tower',
      title: 'From cloud',
      description: '',
      status: IssueStatus.open,
      createdBy: 'u_x',
      createdByName: 'Cloud',
      createdAt: now,
      updatedAt: now,
      synced: true,
    );
    final field = LocalFieldRecordsRepository(
      prefs,
      remotePull: _StubPull(issues: [remote]),
    );

    final result = await field.pullRemote(projectId: 'proj_pune_tower');
    expect(result.issues, 1);
    final local = await field.watchIssues('proj_pune_tower').first;
    expect(local.any((i) => i.id == 'issue_remote_1'), isTrue);
  });

  test('failed remote apply keeps entry in outbox with attempts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final field = LocalFieldRecordsRepository(
      prefs,
      remoteSink: _FailingSink(),
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await field.createIssue(
      session: session,
      input: const CreateIssueInput(title: 'Retry me', description: ''),
    );
    await field.flushOutbox(isOnline: true);
    expect(await field.watchPendingSyncCount().first, 1);
  });
}

class _FailingSink implements OutboxRemoteSink {
  @override
  Future<void> apply(OutboxEntry entry) async {
    throw StateError('network down');
  }
}
