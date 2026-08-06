import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_service.dart';
import 'device_biometric_service.dart';
import 'device_evidence_capture.dart';
import 'device_location_service.dart';
import 'device_sensors_gate.dart';
import 'evidence_capture.dart';
import 'fake_biometric_service.dart';
import 'fake_evidence_capture.dart';
import 'fake_location_service.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceLocationService();
  return const FakeLocationService();
});

final evidenceCaptureProvider = Provider<EvidenceCapture>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceEvidenceCapture();
  return FakeEvidenceCapture();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceBiometricService();
  return const FakeBiometricService();
});

final usingNativeSensorsProvider = Provider<bool>((ref) {
  return DeviceSensorsGate.useNative;
});
