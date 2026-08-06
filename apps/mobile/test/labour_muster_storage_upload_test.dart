import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/site_ops/data/local_site_ops_repository.dart';
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

  test('muster photo enqueues upload then create; flush sets remoteUrl',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final repo = LocalSiteOpsRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final muster = await repo.addMuster(
      session: session,
      trade: 'Civil',
      subcontractor: 'Shree',
      headcount: 18,
      photoLocalPath: 'local://demo/muster.jpg',
      photoByteSizeBytes: 150 * 1024,
    );
    expect(muster.pendingPhotoUpload, isTrue);
    expect(muster.hasPhoto, isTrue);
    expect(muster.photoOptional, isTrue);
    expect(await repo.watchPendingSyncCount().first, 2);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(
      uploader.uploads.first.storagePath,
      contains('attendance_logs/${muster.id}/'),
    );
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    expect(sink.applied.first.payload['photoRemoteUrl'], contains('https://'));
    expect(sink.applied.first.payload['pendingPhotoUpload'], isFalse);

    final saved = (await repo.watchMuster(session.activeProjectId).first)
        .firstWhere((r) => r.id == muster.id);
    expect(saved.photoRemoteUrl, startsWith('https://'));
    expect(saved.pendingPhotoUpload, isFalse);
    expect(await repo.watchPendingSyncCount().first, 0);
  });

  test('failed muster upload keeps create in outbox', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final repo = LocalSiteOpsRepository(
      prefs,
      remoteSink: sink,
      storageUploader: _FailingUploader(),
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await repo.addMuster(
      session: session,
      trade: 'Civil',
      subcontractor: 'Shree',
      headcount: 10,
      photoLocalPath: 'local://demo/muster_fail.jpg',
    );
    await repo.flushOutbox(isOnline: true);
    expect(sink.applied, isEmpty);
    expect(await repo.watchPendingSyncCount().first, greaterThan(0));
  });

  test('muster without photo enqueues create only', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final repo = LocalSiteOpsRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final muster = await repo.addMuster(
      session: session,
      trade: 'Civil',
      subcontractor: 'Shree',
      headcount: 8,
    );
    expect(muster.hasPhoto, isFalse);
    expect(await repo.watchPendingSyncCount().first, 1);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, isEmpty);
    expect(sink.applied.single.operation, OutboxOperation.create);
  });
}
