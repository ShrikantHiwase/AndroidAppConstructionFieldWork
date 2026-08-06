import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/auth/domain/auth_models.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalFieldRecordsRepository repo;
  late AuthSession engineer;
  late AuthSession client;
  late AuthSession pm;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = LocalFieldRecordsRepository(prefs);
    final auth = FakeAuthRepository(prefs);
    engineer = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await auth.signOut();
    client = await auth.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await auth.signOut();
    pm = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
  });

  test('create issue offline then sync marks synced', () async {
    final issue = await repo.createIssue(
      session: engineer,
      input: const CreateIssueInput(
        title: 'Cracked slab',
        description: 'Bay 3',
        location: GeoLocation(latitude: 18.5, longitude: 73.7),
        attachments: [
          MediaAttachment(
            id: 'm1',
            fileName: 'a.jpg',
            contentType: 'image/jpeg',
            localPath: 'local://a.jpg',
          ),
        ],
      ),
    );
    expect(issue.synced, isFalse);
    expect(issue.status, IssueStatus.open);

    var pending = await repo.watchPendingSyncCount().first;
    expect(pending, greaterThan(0));

    await repo.flushOutbox(isOnline: false);
    pending = await repo.watchPendingSyncCount().first;
    expect(pending, greaterThan(0));

    await repo.flushOutbox(isOnline: true);
    pending = await repo.watchPendingSyncCount().first;
    expect(pending, 0);

    final issues = await repo.watchIssues(engineer.activeProjectId).first;
    expect(issues.single.synced, isTrue);
    expect(issues.single.attachments, hasLength(1));
    expect(issues.single.attachments.single.pendingUpload, isFalse);
    expect(issues.single.attachments.single.remoteUrl, startsWith('demo://'));
    expect(issues.single.location, isNotNull);
  });

  test('client cannot create issues', () async {
    expect(
      () => repo.createIssue(
        session: client,
        input: const CreateIssueInput(title: 'Nope', description: ''),
      ),
      throwsA(isA<FieldRecordsException>()),
    );
  });

  test('status workflow and audit trail', () async {
    final issue = await repo.createIssue(
      session: engineer,
      input: const CreateIssueInput(title: 'Leak', description: 'Shaft'),
    );
    final moved = await repo.updateIssueStatus(
      session: engineer,
      issueId: issue.id,
      status: IssueStatus.inProgress,
    );
    expect(moved.status, IssueStatus.inProgress);
    expect(moved.statusHistory, hasLength(1));
    expect(moved.statusHistory.single.to, IssueStatus.inProgress);
  });

  test('pm can assign; engineer cannot', () async {
    final issue = await repo.createIssue(
      session: engineer,
      input: const CreateIssueInput(title: 'Assign me', description: ''),
    );
    expect(
      () => repo.assignIssue(
        session: engineer,
        issueId: issue.id,
        assigneeId: 'u_x',
        assigneeName: 'X',
      ),
      throwsA(isA<FieldRecordsException>()),
    );

    final assigned = await repo.assignIssue(
      session: pm,
      issueId: issue.id,
      assigneeId: 'u_engineer',
      assigneeName: 'Asha Patil',
    );
    expect(assigned.assigneeName, 'Asha Patil');
    expect(RolePermissions.canAssignWork(pm.activeRole), isTrue);
  });

  test('pm can assign RFI; engineer cannot', () async {
    final rfi = await repo.createRfi(
      session: engineer,
      input: const CreateRfiInput(
        subject: 'Assign RFI',
        question: 'Who owns this?',
      ),
    );
    expect(
      () => repo.assignRfi(
        session: engineer,
        rfiId: rfi.id,
        assigneeId: 'u_x',
        assigneeName: 'X',
      ),
      throwsA(isA<FieldRecordsException>()),
    );

    final assigned = await repo.assignRfi(
      session: pm,
      rfiId: rfi.id,
      assigneeId: 'u_engineer',
      assigneeName: 'Asha Patil',
    );
    expect(assigned.assigneeId, 'u_engineer');
    expect(assigned.assigneeName, 'Asha Patil');
    expect(assigned.synced, isFalse);
  });

  test('rfi comments are append-only via create', () async {
    final rfi = await repo.createRfi(
      session: engineer,
      input: const CreateRfiInput(
        subject: 'Beam size',
        question: 'Confirm B2 rebar?',
      ),
    );
    await repo.addComment(
      session: engineer,
      parentType: 'rfi',
      parentId: rfi.id,
      body: 'Need drawing revision',
    );
    await repo.addComment(
      session: pm,
      parentType: 'rfi',
      parentId: rfi.id,
      body: 'Use 16mm as per IFC',
    );
    final comments = await repo
        .watchComments(parentType: 'rfi', parentId: rfi.id)
        .first;
    expect(comments, hasLength(2));
    expect(comments.first.body, contains('drawing'));
  });
}
