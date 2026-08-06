import 'package:image_picker/image_picker.dart';

import '../../features/issues/domain/issue_models.dart';
import 'evidence_capture.dart';
import 'evidence_image_policy.dart';
import 'fake_evidence_capture.dart';
import 'image_compressor.dart';

/// Camera/gallery via image_picker + [ImageCompressor]; falls back to Fake.
class DeviceEvidenceCapture implements EvidenceCapture {
  DeviceEvidenceCapture({
    ImagePicker? picker,
    EvidenceCapture? fallback,
    ImageCompressor compressor = const FileImageCompressor(),
  })  : _picker = picker ?? ImagePicker(),
        _fallback = fallback ?? FakeEvidenceCapture(),
        _compressor = compressor;

  final ImagePicker _picker;
  final EvidenceCapture _fallback;
  final ImageCompressor _compressor;

  @override
  Future<MediaAttachment?> capturePhoto({
    EvidencePhotoSource source = EvidencePhotoSource.camera,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: source == EvidencePhotoSource.gallery
            ? ImageSource.gallery
            : ImageSource.camera,
        imageQuality: EvidenceImagePolicy.jpegQuality,
        maxWidth: EvidenceImagePolicy.maxWidthPx.toDouble(),
      );
      if (file == null) return null;
      final compressed = await _compressor.compressFile(file.path);
      final name = file.name.isEmpty ? 'site_photo.jpg' : file.name;
      return MediaAttachment(
        id: 'media_${DateTime.now().microsecondsSinceEpoch}',
        fileName: name,
        contentType: 'image/jpeg',
        localPath: compressed.path,
        byteSizeBytes: compressed.byteSizeBytes,
        widthPx: compressed.widthPx,
      );
    } catch (_) {
      return _fallback.capturePhoto(source: source);
    }
  }
}
