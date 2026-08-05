import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/constants/app_constants.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/auth/domain/auth_models.dart';
import 'package:construction_field_app/features/auth/domain/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = FakeAuthRepository(prefs);
  });

  test('demo engineer signs in and gets site_engineer role', () async {
    final session = await repo.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(session.activeRole, AppRole.siteEngineer);
    expect(session.projects, hasLength(2));
    expect(RolePermissions.canCreateIssues(session.activeRole), isTrue);
    expect(RolePermissions.isReadOnly(session.activeRole), isFalse);
  });

  test('client is read-only', () async {
    final session = await repo.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(RolePermissions.isReadOnly(session.activeRole), isTrue);
    expect(RolePermissions.canCreateIssues(session.activeRole), isFalse);
  });

  test('invalid credentials throw AuthFailure', () async {
    expect(
      () => repo.signInWithEmail(email: 'x@y.com', password: 'nope'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('switchProject updates active project and persists', () async {
    await repo.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final switched = await repo.switchProject('proj_mumbai_metro');
    expect(switched.activeProjectId, 'proj_mumbai_metro');

    final restored = await repo.restoreSession();
    expect(restored?.activeProjectId, 'proj_mumbai_metro');
    expect(restored?.activeRole, AppRole.projectManager);
  });

  test('biometrics lock gate requires unlock', () async {
    await repo.signInWithEmail(
      email: 'admin@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await repo.setBiometricsEnabled(true);
    await repo.markLockedForResume();
    expect(repo.requiresUnlock, isTrue);
    expect(await repo.unlockWithBiometrics(), isTrue);
    expect(repo.requiresUnlock, isFalse);
  });
}
