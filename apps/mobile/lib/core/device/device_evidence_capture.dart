import 'package:image_picker/image_picker.dart';

import '../../features/issues/domain/issue_models.dart';
import 'evidence_capture.dart';
import 'fake_evidence_capture.dart';

/// Camera/gallery via image_picker; falls back to [FakeEvidenceCapture].
class DeviceEvidenceCapture implements EvidenceCapture {
  DeviceEvidenceCapture({
    ImagePicker? picker,
    EvidenceCapture? fallback,
  })  : _picker = picker ?? ImagePicker(),
        _fallback = fallback ?? FakeEvidenceCapture();

  final ImagePicker _picker;
  final EvidenceCapture _fallback;

  @override
  Future<MediaAttachment?> capturePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file == null) return null;
      final name = file.name.isEmpty ? 'site_photo.jpg' : file.name;
      return MediaAttachment(
        id: 'media_${DateTime.now().microsecondsSinceEpoch}',
        fileName: name,
        contentType: 'image/jpeg',
        localPath: file.path,
      );
    } catch (_) {
      return _fallback.capturePhoto();
    }
  }
}
