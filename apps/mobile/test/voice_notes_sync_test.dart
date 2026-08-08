import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/dpr/data/local_dpr_repository.dart';
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

  test('voice note enqueues upload + create; flush syncs and resolves transcript',
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

    final note = await voices.addDemoVoiceNote(
      session: session,
      parentType: VoiceParentType.issue,
      parentId: 'issue_1',
      offline: true,
    );
    expect(note.transcriptPending, isTrue);
    expect(note.synced, isFalse);
    expect(await voices.watchPendingSyncCount().first, 2);

    await voices.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(uploader.uploads.first.parentType, 'voice');
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.collection, 'voice_notes');
    expect(sink.applied.first.payload['transcriptPending'], isFalse);
    expect(sink.applied.first.payload['remoteAudioUrl'], startsWith('https://'));
    expect(sink.applied.first.payload.containsKey('audioLocalPath'), isFalse);
    expect(await voices.watchPendingSyncCount().first, 0);

    final listed = await voices.listForParent(
      parentType: VoiceParentType.issue,
      parentId: 'issue_1',
    );
    expect(listed.single.synced, isTrue);
    expect(listed.single.transcriptPending, isFalse);
    expect(listed.single.remoteAudioUrl, isNotNull);
  });

  test('ensureSeedVoiceNotes attaches transcript to yesterday DPR without outbox',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final voices = LocalVoiceNotesRepository(prefs);
    final dprs = LocalDprRepository(prefs);
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await dprs.ensureSeedDprs(session);
    await voices.ensureSeedVoiceNotes(session);

    final now = DateTime.now().toUtc();
    final yesterday = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final dprId =
        'dpr_seed_${session.activeProjectId}_${yesterday.toIso8601String().split('T').first}';

    final notes = await voices.listForParent(
      parentType: VoiceParentType.dpr,
      parentId: dprId,
    );
    expect(notes, hasLength(1));
    expect(notes.single.id, 'voice_seed_dpr');
    expect(notes.single.transcript, contains('Slab shuttering 80'));
    expect(notes.single.synced, isTrue);
    expect(notes.single.remoteAudioUrl, startsWith('demo://'));
    expect(await voices.watchPendingSyncCount().first, 0);

    await voices.ensureSeedVoiceNotes(session);
    expect(
      await voices.listForParent(
        parentType: VoiceParentType.dpr,
        parentId: dprId,
      ),
      hasLength(1),
    );
  });
}
