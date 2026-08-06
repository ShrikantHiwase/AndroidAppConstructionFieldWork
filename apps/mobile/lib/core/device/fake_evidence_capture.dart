import '../../features/issues/domain/issue_models.dart';
import 'evidence_capture.dart';

class FakeEvidenceCapture implements EvidenceCapture {
  FakeEvidenceCapture({int startIndex = 0}) : _index = startIndex;

  int _index;

  @override
  Future<MediaAttachment?> capturePhoto() async {
    _index += 1;
    return MediaAttachment(
      id: 'media_demo_$_index',
      fileName: 'site_photo_$_index.jpg',
      contentType: 'image/jpeg',
      localPath: 'local://demo/site_photo_$_index.jpg',
    );
  }
}
