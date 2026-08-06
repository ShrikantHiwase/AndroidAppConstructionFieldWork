import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/local_voice_notes_repository.dart';
import '../domain/voice_note_models.dart';
import '../domain/voice_notes_repository.dart';

final voiceNotesRepositoryProvider = Provider<VoiceNotesRepository>((ref) {
  return LocalVoiceNotesRepository(ref.watch(sharedPreferencesProvider));
});

final voiceNotesForParentProvider = StreamProvider.family<List<VoiceNote>,
    ({VoiceParentType type, String id})>((ref, key) {
  return ref.watch(voiceNotesRepositoryProvider).watchForParent(
        parentType: key.type,
        parentId: key.id,
      );
});
