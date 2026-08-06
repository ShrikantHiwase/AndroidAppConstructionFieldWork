import '../../features/issues/domain/issue_models.dart';
import 'evidence_capture.dart';
import 'evidence_image_policy.dart';
import 'image_compressor.dart';

class FakeEvidenceCapture implements EvidenceCapture {
  FakeEvidenceCapture({
    int startIndex = 0,
    ImageCompressor compressor = const FakeImageCompressor(),
  })  : _index = startIndex,
        _compressor = compressor;

  int _index;
  final ImageCompressor _compressor;

  @override
  Future<MediaAttachment?> capturePhoto({
    EvidencePhotoSource source = EvidencePhotoSource.camera,
  }) async {
    _index += 1;
    final path = 'local://demo/site_photo_$_index.jpg';
    final compressed = await _compressor.compressFile(path);
    final label = source == EvidencePhotoSource.gallery ? 'gallery' : 'camera';
    return MediaAttachment(
      id: 'media_demo_$_index',
      fileName: 'site_photo_${label}_$_index.jpg',
      contentType: 'image/jpeg',
      localPath: path,
      byteSizeBytes: compressed.byteSizeBytes,
      widthPx: compressed.widthPx ?? EvidenceImagePolicy.maxWidthPx,
    );
  }
}
