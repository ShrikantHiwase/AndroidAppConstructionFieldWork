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

  /// Demo capture: stores a stub audio path + transcript (or pending flag).
  Future<VoiceNote> addDemoVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    String? transcript,
    bool offline = false,
  });
}
