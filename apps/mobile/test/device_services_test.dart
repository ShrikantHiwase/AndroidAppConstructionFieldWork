import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/device/device_sensors_gate.dart';
import 'package:construction_field_app/core/device/evidence_capture.dart';
import 'package:construction_field_app/core/device/evidence_image_policy.dart';
import 'package:construction_field_app/core/device/fake_biometric_service.dart';
import 'package:construction_field_app/core/device/fake_evidence_capture.dart';
import 'package:construction_field_app/core/device/fake_location_service.dart';
import 'package:construction_field_app/core/device/image_compressor.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('FakeEvidenceCapture returns compressed demo metadata', () async {
    final capture = FakeEvidenceCapture();
    final shot = await capture.capturePhoto();
    expect(shot, isNotNull);
    expect(shot!.localPath, startsWith('local://demo/'));
    expect(shot.contentType, 'image/jpeg');
    expect(shot.byteSizeBytes, EvidenceImagePolicy.demoByteSize);
    expect(shot.widthPx, EvidenceImagePolicy.maxWidthPx);

    final gallery = await capture.capturePhoto(
      source: EvidencePhotoSource.gallery,
    );
    expect(gallery!.fileName, contains('gallery'));
  });

  test('FakeBiometricService always unlocks', () async {
    const bio = FakeBiometricService();
    expect(await bio.canCheckBiometrics, isTrue);
    expect(await bio.authenticate(reason: 'test'), isTrue);
  });

  test('FileImageCompressor resizes wide JPEG under target', () async {
    final file = await writeTestJpeg(width: 2400, height: 1400, quality: 95);
    final before = await file.length();
    expect(before, greaterThan(50 * 1024));

    const compressor = FileImageCompressor();
    final result = await compressor.compressFile(file.path);
    expect(result.byteSizeBytes, greaterThan(0));
    expect(result.byteSizeBytes, lessThanOrEqualTo(before));
    expect(result.widthPx, lessThanOrEqualTo(EvidenceImagePolicy.maxWidthPx));
    expect(
      result.byteSizeBytes,
      lessThanOrEqualTo(EvidenceImagePolicy.targetMaxBytes),
    );
    expect(await File(file.path).length(), result.byteSizeBytes);
  });

  test('EvidenceImagePolicy.formatBytes is human readable', () {
    expect(EvidenceImagePolicy.formatBytes(500), '500 B');
    expect(EvidenceImagePolicy.formatBytes(150 * 1024), contains('KB'));
  });

  test('MediaAttachment round-trips byteSizeBytes', () {
    const original = MediaAttachment(
      id: 'm1',
      fileName: 'a.jpg',
      contentType: 'image/jpeg',
      localPath: 'local://x',
      byteSizeBytes: 12345,
      widthPx: 1600,
    );
    final restored = MediaAttachment.fromJson(original.toJson());
    expect(restored.byteSizeBytes, 12345);
    expect(restored.widthPx, 1600);
  });
}
