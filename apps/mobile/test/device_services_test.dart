import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/device/device_sensors_gate.dart';
import 'package:construction_field_app/core/device/fake_biometric_service.dart';
import 'package:construction_field_app/core/device/fake_evidence_capture.dart';
import 'package:construction_field_app/core/device/fake_location_service.dart';

void main() {
  test('DeviceSensorsGate defaults to fake (CI-safe)', () {
    expect(DeviceSensorsGate.useNative, isFalse);
  });

  test('FakeLocationService returns demo Hinjewadi fix', () async {
    const svc = FakeLocationService();
    final pos = await svc.currentPosition();
    expect(pos, isNotNull);
    expect(pos!.latitude, FakeLocationService.demoSite.latitude);
    expect(
      await svc.isWithinGeofence(
        site: FakeLocationService.demoSite,
        radiusMeters: 100,
      ),
      isTrue,
    );
  });

  test('FakeEvidenceCapture returns local demo path', () async {
    final capture = FakeEvidenceCapture();
    final shot = await capture.capturePhoto();
    expect(shot, isNotNull);
    expect(shot!.localPath, startsWith('local://demo/'));
    expect(shot.contentType, 'image/jpeg');
  });

  test('FakeBiometricService always unlocks', () async {
    const bio = FakeBiometricService();
    expect(await bio.canCheckBiometrics, isTrue);
    expect(await bio.authenticate(reason: 'test'), isTrue);
  });
}
