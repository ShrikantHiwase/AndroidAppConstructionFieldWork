import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../data/local_voice_notes_repository.dart';
import '../domain/voice_note_models.dart';
import '../domain/voice_notes_repository.dart';

final voiceNotesRepositoryProvider = Provider<VoiceNotesRepository>((ref) {
  return LocalVoiceNotesRepository(
    ref.watch(sharedPreferencesProvider),
    remoteSink: ref.watch(outboxRemoteSinkProvider),
    remotePull: ref.watch(moduleRemotePullProvider),
    storageUploader: ref.watch(storageUploaderProvider),
  );
});

final voiceNotesSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  // DPR seed first so parent id matches yesterday's submitted report.
  await ref.watch(dprSeedProvider.future);
  await ref.read(voiceNotesRepositoryProvider).ensureSeedVoiceNotes(session);
});

final voiceNotesForParentProvider = StreamProvider.family<List<VoiceNote>,
    ({VoiceParentType type, String id})>((ref, key) async* {
  final session = ref.watch(authSessionProvider);
  if (session != null) {
    await ref.watch(voiceNotesSeedProvider.future);
  }
  yield* ref.watch(voiceNotesRepositoryProvider).watchForParent(
        parentType: key.type,
        parentId: key.id,
      );
});
