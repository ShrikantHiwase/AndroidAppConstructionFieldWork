import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/constants/app_constants.dart';
import 'package:construction_field_app/features/admin/data/firebase_admin_invites_repository.dart';
import 'package:construction_field_app/features/admin/domain/admin_invite_models.dart';
import 'package:construction_field_app/features/auth/domain/auth_models.dart';

void main() {
  AuthSession adminSession() {
    const project = Project(
      id: 'proj_pune_tower',
      orgId: 'org_demo',
      name: 'Pune Tower',
    );
    return AuthSession(
      user: const AppUser(
        id: 'admin_uid',
        email: 'admin@demo.rayns',
        displayName: 'Admin',
      ),
      memberships: const [
        Membership(
          id: 'm1',
          userId: 'admin_uid',
          orgId: 'org_demo',
          projectId: 'proj_pune_tower',
          role: AppRole.admin,
          active: true,
        ),
      ],
      projects: const [project],
      organizations: const [
        Organization(id: 'org_demo', name: 'Demo Org'),
      ],
      activeProjectId: project.id,
    );
  }

  test('createInvite calls inviteMember with expected payload', () async {
    Map<String, dynamic>? seen;
    final repo = FirebaseAdminInvitesRepository(
      inviteMember: (data) async {
        seen = data;
        return {
          'uid': 'new_uid',
          'email': data['email'],
          'inviteId': 'inv_test_1',
          'temporaryPasswordSet': true,
        };
      },
    );

    final invite = await repo.createInvite(
      session: adminSession(),
      email: ' New.Eng@Demo.Rayns ',
      role: AppRole.siteEngineer,
      projectIds: const ['proj_pune_tower'],
    );

    expect(seen, isNotNull);
    expect(seen!['email'], 'new.eng@demo.rayns');
    expect(seen!['role'], 'site_engineer');
    expect(seen!['orgId'], 'org_demo');
    expect(seen!['projectIds'], ['proj_pune_tower']);
    expect(seen!['temporaryPassword'], 'demo1234');
    expect(seen!['invitedByName'], 'Admin');

    expect(invite.id, 'inv_test_1');
    expect(invite.email, 'new.eng@demo.rayns');
    expect(invite.status, InviteStatus.accepted);
    expect(invite.acceptedUserId, 'new_uid');
  });

  test('createInvite rejects non-admin and bad email', () async {
    final engineerSession = AuthSession(
      user: const AppUser(
        id: 'eng',
        email: 'engineer@demo.rayns',
        displayName: 'Eng',
      ),
      memberships: const [
        Membership(
          id: 'm2',
          userId: 'eng',
          orgId: 'org_demo',
          projectId: 'proj_pune_tower',
          role: AppRole.siteEngineer,
          active: true,
        ),
      ],
      projects: const [
        Project(id: 'proj_pune_tower', orgId: 'org_demo', name: 'Pune Tower'),
      ],
      organizations: const [Organization(id: 'org_demo', name: 'Demo Org')],
      activeProjectId: 'proj_pune_tower',
    );

    final repo = FirebaseAdminInvitesRepository(
      inviteMember: (_) async => {},
    );

    expect(
      () => repo.createInvite(
        session: engineerSession,
        email: 'x@demo.rayns',
        role: AppRole.client,
        projectIds: const ['proj_pune_tower'],
      ),
      throwsA(isA<AdminInvitesException>()),
    );

    expect(
      () => repo.createInvite(
        session: adminSession(),
        email: 'not-an-email',
        role: AppRole.client,
        projectIds: const ['proj_pune_tower'],
      ),
      throwsA(isA<AdminInvitesException>()),
    );
  });

  test('InviteAuthBridge methods are no-ops on Firebase path', () async {
    final repo = FirebaseAdminInvitesRepository(
      inviteMember: (_) async => {},
    );
    expect(await repo.consumePendingInvite('a@b.com'), isNull);
    expect(await repo.lookupAcceptedInvite('a@b.com'), isNull);
  });
}
