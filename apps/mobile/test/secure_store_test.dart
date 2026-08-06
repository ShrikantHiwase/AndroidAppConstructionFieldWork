import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/secure/secure_store.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FakeSecureStore round-trips and reports fake backend', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FakeSecureStore(prefs);
    expect(store.backendLabel, 'fake');

    await store.write(SecureKeys.sessionEmail, 'engineer@demo.rayns');
    expect(await store.read(SecureKeys.sessionEmail), 'engineer@demo.rayns');
    await store.delete(SecureKeys.sessionEmail);
    expect(await store.read(SecureKeys.sessionEmail), isNull);
  });

  test('migrateFromPrefs moves plaintext sensitive keys into secure namespace',
      () async {
    SharedPreferences.setMockInitialValues({
      SecureKeys.sessionEmail: 'pm@demo.rayns',
      SecureKeys.biometricsEnabled: true,
      SecureKeys.fcmToken: 'tok_plain',
      'auth.active_project': 'proj_pune_tower',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = FakeSecureStore(prefs);
    await store.migrateFromPrefs(prefs);

    expect(prefs.containsKey(SecureKeys.sessionEmail), isFalse);
    expect(prefs.containsKey(SecureKeys.biometricsEnabled), isFalse);
    expect(prefs.containsKey(SecureKeys.fcmToken), isFalse);
    expect(prefs.getString('auth.active_project'), 'proj_pune_tower');

    expect(await store.read(SecureKeys.sessionEmail), 'pm@demo.rayns');
    expect(await store.read(SecureKeys.biometricsEnabled), 'true');
    expect(await store.read(SecureKeys.fcmToken), 'tok_plain');
  });

  test('FakeAuth restores session email from secure store after migrate',
      () async {
    SharedPreferences.setMockInitialValues({
      SecureKeys.sessionEmail: 'engineer@demo.rayns',
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.restoreSession();
    expect(session, isNotNull);
    expect(session!.user.email, 'engineer@demo.rayns');
    expect(prefs.containsKey(SecureKeys.sessionEmail), isFalse);
    expect(prefs.getString('secure.${SecureKeys.sessionEmail}'), isNotNull);
  });

  test('createSecureStore defaults to Fake when platform gate is off', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = createSecureStore(prefs);
    expect(store, isA<FakeSecureStore>());
    expect(SecureStoreGate.usePlatform, isFalse);
  });
}
