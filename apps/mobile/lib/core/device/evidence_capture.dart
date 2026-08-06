import '../../features/issues/domain/issue_models.dart';

enum EvidencePhotoSource { camera, gallery }

abstract class EvidenceCapture {
  Future<MediaAttachment?> capturePhoto({
    EvidencePhotoSource source = EvidencePhotoSource.camera,
  });
}
