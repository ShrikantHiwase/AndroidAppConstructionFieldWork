import 'auth_models.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Auth + membership port. Firebase implementation replaces the fake in Phase 1
/// once `flutterfire configure` is complete.
abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthSession> switchProject(String projectId);

  Future<void> setBiometricsEnabled(bool enabled);

  /// Local unlock after app resume when biometrics are enabled.
  Future<bool> unlockWithBiometrics();
}
