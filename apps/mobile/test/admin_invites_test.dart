import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/constants/app_constants.dart';
import 'package:construction_field_app/features/admin/data/local_admin_invites_repository.dart';
import 'package:construction_field_app/features/admin/domain/admin_invite_models.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/auth/domain/auth_models.dart';
import 'package:construction_field_app/features/auth/domain/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalAdminInvitesRepository invites;
  late FakeAuthRepository auth;
  late AuthSession admin;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    invites = LocalAdminInvitesRepository(prefs);
    auth = FakeAuthRepository(prefs, invites: invites);
    admin = await auth.signInWithEmail(
      email: 'admin@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
  });

  test('admin creates invite; invitee signs in with scoped memberships', () async {
    final invite = await invites.createInvite(
      session: admin,
      email: 'new.eng@demo.rayns',
      role: AppRole.siteEngineer,
      projectIds: const ['proj_pune_tower'],
    );
    expect(invite.status, InviteStatus.pending);

    await auth.signOut();
    final session = await auth.signInWithEmail(
      email: 'new.eng@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(session.activeRole, AppRole.siteEngineer);
    expect(session.projects, hasLength(1));
    expect(session.projects.first.id, 'proj_pune_tower');
    expect(RolePermissions.canCreateIssues(session.activeRole), isTrue);

    final listed = await invites.listInvites();
    expect(listed.single.status, InviteStatus.accepted);

    await auth.signOut();
    final restored = await auth.signInWithEmail(
      email: 'new.eng@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(restored.projects, hasLength(1));
  });

  test('demo accounts still work unchanged', () async {
    await auth.signOut();
    final engineer = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(engineer.projects, hasLength(2));
    expect(engineer.activeRole, AppRole.siteEngineer);
  });

  test('non-admin cannot create invites', () async {
    await auth.signOut();
    final engineer = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(
      () => invites.createInvite(
        session: engineer,
        email: 'x@demo.rayns',
        role: AppRole.client,
        projectIds: const ['proj_pune_tower'],
      ),
      throwsA(isA<AdminInvitesException>()),
    );
  });

  test('unknown email without invite fails', () async {
    await auth.signOut();
    expect(
      () => auth.signInWithEmail(
        email: 'nobody@demo.rayns',
        password: FakeAuthRepository.demoPassword,
      ),
      throwsA(isA<AuthFailure>()),
    );
  });
}
