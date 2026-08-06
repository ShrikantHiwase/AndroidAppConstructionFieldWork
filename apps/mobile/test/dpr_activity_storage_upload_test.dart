import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/dpr/data/local_dpr_repository.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
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

class _FailingUploader implements StorageUploader {
  @override
  Future<String> upload(StorageUploadRequest request) async {
    throw StateError('storage down');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activity photo enqueues upload then create; flush sets remoteUrl',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final repo = LocalDprRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final draft = await repo.createOrUpdateToday(
      session: session,
      input: CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '40',
        activities: [
          DprActivity(
            id: 'act_1',
            description: 'Slab pour',
            hasPhoto: true,
            photoLocalPath: 'local://demo/dpr_act.jpg',
            photoByteSizeBytes: 150 * 1024,
          ),
        ],
        blockers: '',
      ),
    );
    expect(draft.activities.single.pendingPhotoUpload, isTrue);
    expect(draft.activities.single.hasPhoto, isTrue);
    expect(await repo.watchPendingSyncCount().first, 2);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(
      uploader.uploads.first.storagePath,
      contains('dprs/${draft.id}/'),
    );
    expect(uploader.uploads.first.attachmentId, 'act_1');
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    final activities =
        sink.applied.first.payload['activities'] as List<dynamic>;
    final first = Map<String, Object?>.from(activities.first as Map);
    expect(first['photoRemoteUrl'], contains('https://'));
    expect(first['pendingPhotoUpload'], isFalse);

    final saved = (await repo.watchDprs(session.activeProjectId).first)
        .firstWhere((r) => r.id == draft.id);
    expect(saved.activities.single.photoRemoteUrl, startsWith('https://'));
    expect(saved.activities.single.pendingPhotoUpload, isFalse);
    expect(await repo.watchPendingSyncCount().first, 0);
  });

  test('failed activity upload keeps create in outbox', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final repo = LocalDprRepository(
      prefs,
      remoteSink: sink,
      storageUploader: _FailingUploader(),
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await repo.createOrUpdateToday(
      session: session,
      input: CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '40',
        activities: [
          DprActivity(
            id: 'act_fail',
            description: 'Formwork',
            hasPhoto: true,
            photoLocalPath: 'local://demo/dpr_fail.jpg',
          ),
        ],
        blockers: '',
      ),
    );
    await repo.flushOutbox(isOnline: true);
    expect(sink.applied, isEmpty);
    expect(await repo.watchPendingSyncCount().first, greaterThan(0));
  });

  test('activity without photo enqueues create only', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final repo = LocalDprRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final draft = await repo.createOrUpdateToday(
      session: session,
      input: const CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '40',
        activities: [
          DprActivity(id: 'act_plain', description: 'Curing'),
        ],
        blockers: '',
      ),
    );
    expect(draft.activities.single.hasPhoto, isFalse);
    expect(await repo.watchPendingSyncCount().first, 1);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, isEmpty);
    expect(sink.applied.single.operation, OutboxOperation.create);
  });

  test('draft re-save does not duplicate pending activity uploads', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final repo = LocalDprRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    const activity = DprActivity(
      id: 'act_dedupe',
      description: 'Bay 3 pour',
      hasPhoto: true,
      photoLocalPath: 'local://demo/dpr_dedupe.jpg',
      photoByteSizeBytes: 100 * 1024,
    );
    await repo.createOrUpdateToday(
      session: session,
      input: const CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '40',
        activities: [activity],
        blockers: '',
      ),
    );
    await repo.createOrUpdateToday(
      session: session,
      input: const CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '42',
        activities: [activity],
        blockers: '',
      ),
    );

    // One upload + two create upserts (draft saved twice).
    expect(await repo.watchPendingSyncCount().first, 3);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(sink.applied, hasLength(2));
  });
}
