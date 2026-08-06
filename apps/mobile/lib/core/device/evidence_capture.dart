import '../../features/issues/domain/issue_models.dart';

abstract class EvidenceCapture {
  Future<MediaAttachment?> capturePhoto();
}
