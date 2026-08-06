abstract class BiometricService {
  Future<bool> authenticate({required String reason});
  Future<bool> get canCheckBiometrics;
}
