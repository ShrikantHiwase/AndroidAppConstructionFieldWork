import 'biometric_service.dart';

/// Always succeeds — used in CI and until USE_NATIVE_SENSORS=true.
class FakeBiometricService implements BiometricService {
  const FakeBiometricService();

  @override
  Future<bool> get canCheckBiometrics async => true;

  @override
  Future<bool> authenticate({required String reason}) async => true;
}
