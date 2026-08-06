import '../../auth/domain/auth_models.dart';
import 'voice_note_models.dart';

abstract class VoiceNotesRepository {
  Stream<List<VoiceNote>> watchForParent({
    required VoiceParentType parentType,
    required String parentId,
  });

  Future<List<VoiceNote>> listForParent({
    required VoiceParentType parentType,
    required String parentId,
  });

  /// Stores a captured clip (Fake stub or on-device path) + transcript.
  Future<VoiceNote> addVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    required String audioLocalPath,
    String? fileName,
    int? audioByteSizeBytes,
    String? transcript,
    bool offline = false,
  });

  /// Convenience Fake stub capture (tests / callers without VoiceCapture).
  Future<VoiceNote> addDemoVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    String? transcript,
    bool offline = false,
  });
}
