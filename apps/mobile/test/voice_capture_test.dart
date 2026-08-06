import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/device/fake_voice_capture.dart';
import 'package:construction_field_app/core/device/voice_audio_policy.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/voice_notes/data/local_voice_notes_repository.dart';
import 'package:construction_field_app/features/voice_notes/domain/voice_note_models.dart';
import 'package:construction_field_app/sync/outbox/outbox_entry.dart';
import 'package:construction_field_app/sync/remote/outbox_remote_sink.dart';
import 'package:construction_field_app/sync/remote/storage_uploader.dart';

class _RecordingSink implements OutboxRemoteSink {
  final applied = <OutboxEntry>[];

  @override
  Future<void> apply(OutboxEntry entry) async {
    applied.add(entry);
  }
}

class _RecordingUploader implements StorageUploader {
  final uploads = <StorageUploadRequest>[];

  @override
  Future<String> upload(StorageUploadRequest request) async {
    uploads.add(request);
    return 'https://example.test/${request.storagePath}';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FakeVoiceCapture returns demo stub with size and transcript hint',
      () async {
    final clip = await FakeVoiceCapture().record();
    expect(clip, isNotNull);
    expect(clip!.localPath, startsWith('local://demo/voice_'));
    expect(clip.byteSizeBytes, VoiceAudioPolicy.demoByteSize);
    expect(clip.transcriptHint, contains('Voice stub'));
  });

  test('addVoiceNote from Fake clip enqueues upload and joins soft cache',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final voices = LocalVoiceNotesRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final clip = await FakeVoiceCapture().record();
    final note = await voices.addVoiceNote(
      session: session,
      parentType: VoiceParentType.dpr,
      parentId: 'dpr_1',
      audioLocalPath: clip!.localPath,
      fileName: clip.fileName,
      audioByteSizeBytes: clip.byteSizeBytes,
      transcript: '${clip.transcriptHint} (${session.user.displayName})',
    );
    expect(note.audioByteSizeBytes, VoiceAudioPolicy.demoByteSize);
    expect(note.audioLocalPath, startsWith('local://'));

    final slice = voices.estimateLocalCache();
    expect(slice.label, 'voice');
    expect(slice.estimatedBytes, greaterThan(0));
    expect(slice.itemCount, 1);

    await voices.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(sink.applied.single.payload['remoteAudioUrl'], contains('https://'));

    final after = (await voices.listForParent(
      parentType: VoiceParentType.dpr,
      parentId: 'dpr_1',
    ))
        .single;
    expect(after.remoteAudioUrl, startsWith('https://'));

    final reclaimable = voices.estimateLocalCache().reclaimableBytes;
    expect(reclaimable, greaterThan(0));
    final freed = await voices.reclaimUploadedLocalPaths();
    expect(freed, reclaimable);
    expect(
      (await voices.listForParent(
        parentType: VoiceParentType.dpr,
        parentId: 'dpr_1',
      ))
          .single
          .audioLocalPath,
      isNull,
    );
  });
}
