import 'package:local_auth/local_auth.dart';

import 'biometric_service.dart';
import 'fake_biometric_service.dart';

class DeviceBiometricService implements BiometricService {
  DeviceBiometricService({
    LocalAuthentication? auth,
    BiometricService? fallback,
  })  : _auth = auth ?? LocalAuthentication(),
        _fallback = fallback ?? const FakeBiometricService();

  final LocalAuthentication _auth;
  final BiometricService _fallback;

  @override
  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return _fallback.canCheckBiometrics;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      final supported = await canCheckBiometrics;
      if (!supported) return _fallback.authenticate(reason: reason);
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return _fallback.authenticate(reason: reason);
    }
  }
}
