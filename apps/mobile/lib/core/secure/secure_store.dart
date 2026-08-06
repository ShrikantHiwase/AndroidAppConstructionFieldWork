import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sensitive prefs keys that should not stay in plaintext SharedPreferences.
abstract final class SecureKeys {
  static const sessionEmail = 'auth.session_email';
  static const biometricsEnabled = 'auth.biometrics_enabled';
  static const fcmToken = 'fcm.token';

  static const all = <String>[
    sessionEmail,
    biometricsEnabled,
    fcmToken,
  ];
}

/// Gate for platform encrypted storage.
///
/// Default is off so CI / `flutter test` use [FakeSecureStore].
/// Enable on device: `flutter run --dart-define=USE_SECURE_STORAGE=true`
abstract final class SecureStoreGate {
  static const bool usePlatform = bool.fromEnvironment(
    'USE_SECURE_STORAGE',
    defaultValue: false,
  );
}

/// Small encrypted (or fake) key-value store for sensitive session secrets.
abstract class SecureStore {
  /// `fake` or `flutter_secure_storage`.
  String get backendLabel;

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Copies plaintext SharedPreferences values into secure storage once.
  Future<void> migrateFromPrefs(SharedPreferences prefs);
}

SecureStore createSecureStore(SharedPreferences prefs) {
  if (SecureStoreGate.usePlatform) {
    return PlatformSecureStore();
  }
  return FakeSecureStore(prefs);
}

/// Prefs-backed stand-in for Linux CI / demo (prefix `secure.`).
class FakeSecureStore implements SecureStore {
  FakeSecureStore(this._prefs);

  final SharedPreferences _prefs;
  var _migrated = false;

  @override
  String get backendLabel => 'fake';

  String _namespaced(String key) => 'secure.$key';

  @override
  Future<String?> read(String key) async {
    await migrateFromPrefs(_prefs);
    return _prefs.getString(_namespaced(key));
  }

  @override
  Future<void> write(String key, String value) async {
    await migrateFromPrefs(_prefs);
    await _prefs.setString(_namespaced(key), value);
  }

  @override
  Future<void> delete(String key) async {
    await migrateFromPrefs(_prefs);
    await _prefs.remove(_namespaced(key));
  }

  @override
  Future<void> migrateFromPrefs(SharedPreferences prefs) async {
    if (_migrated) return;
    _migrated = true;
    for (final key in SecureKeys.all) {
      final already = prefs.getString(_namespaced(key));
      if (already != null) {
        await prefs.remove(key);
        continue;
      }
      if (!prefs.containsKey(key)) continue;

      if (key == SecureKeys.biometricsEnabled) {
        final boolVal = prefs.getBool(key);
        if (boolVal != null) {
          await prefs.setString(_namespaced(key), boolVal ? 'true' : 'false');
          await prefs.remove(key);
          continue;
        }
      }

      final strVal = prefs.getString(key);
      if (strVal != null) {
        await prefs.setString(_namespaced(key), strVal);
        await prefs.remove(key);
      }
    }
  }
}

/// Device Keychain / EncryptedSharedPreferences via flutter_secure_storage.
class PlatformSecureStore implements SecureStore {
  PlatformSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  var _migrated = false;

  @override
  String get backendLabel => 'flutter_secure_storage';

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> migrateFromPrefs(SharedPreferences prefs) async {
    if (_migrated) return;
    _migrated = true;
    for (final key in SecureKeys.all) {
      final existing = await _storage.read(key: key);
      if (existing != null) {
        await prefs.remove(key);
        continue;
      }
      if (!prefs.containsKey(key)) continue;

      if (key == SecureKeys.biometricsEnabled) {
        final boolVal = prefs.getBool(key);
        if (boolVal != null) {
          await _storage.write(key: key, value: boolVal ? 'true' : 'false');
          await prefs.remove(key);
          continue;
        }
      }

      final strVal = prefs.getString(key);
      if (strVal != null) {
        await _storage.write(key: key, value: strVal);
        await prefs.remove(key);
      }
    }
  }
}
