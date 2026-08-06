import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_service.dart';
import 'device_biometric_service.dart';
import 'device_document_file_picker.dart';
import 'device_evidence_capture.dart';
import 'device_location_service.dart';
import 'device_sensors_gate.dart';
import 'device_voice_capture.dart';
import 'document_file_picker.dart';
import 'evidence_capture.dart';
import 'fake_biometric_service.dart';
import 'fake_document_file_picker.dart';
import 'fake_evidence_capture.dart';
import 'fake_location_service.dart';
import 'fake_voice_capture.dart';
import 'location_service.dart';
import 'voice_capture.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceLocationService();
  return const FakeLocationService();
});

final evidenceCaptureProvider = Provider<EvidenceCapture>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceEvidenceCapture();
  return FakeEvidenceCapture();
});

final voiceCaptureProvider = Provider<VoiceCapture>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceVoiceCapture();
  return FakeVoiceCapture();
});

final documentFilePickerProvider = Provider<DocumentFilePicker>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceDocumentFilePicker();
  return FakeDocumentFilePicker();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  if (DeviceSensorsGate.useNative) return DeviceBiometricService();
  return const FakeBiometricService();
});

final usingNativeSensorsProvider = Provider<bool>((ref) {
  return DeviceSensorsGate.useNative;
});
