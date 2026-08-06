import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/site_ops/data/local_site_ops_repository.dart';
import 'package:construction_field_app/features/site_ops/domain/site_ops_models.dart';
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

  test('safety photo enqueues upload then create; flush sets remoteUrl',
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
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final record = await repo.addSafety(
      session: session,
      kind: SafetyKind.observation,
      title: 'Open edge',
      notes: 'Missing rail',
      photoLocalPath: 'local://demo/safety.jpg',
      photoByteSizeBytes: 150 * 1024,
    );
    expect(record.pendingPhotoUpload, isTrue);
    expect(await repo.watchPendingSyncCount().first, 2);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(
      uploader.uploads.first.storagePath,
      contains('safety_records/${record.id}/'),
    );
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    expect(sink.applied.first.payload['photoRemoteUrl'], contains('https://'));
    expect(sink.applied.first.payload['pendingPhotoUpload'], isFalse);

    final saved = (await repo.watchSafety(session.activeProjectId).first)
        .firstWhere((r) => r.id == record.id);
    expect(saved.photoRemoteUrl, startsWith('https://'));
    expect(saved.pendingPhotoUpload, isFalse);
    expect(await repo.watchPendingSyncCount().first, 0);
  });

  test('failed safety upload keeps create in outbox', () async {
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
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await repo.addSafety(
      session: session,
      kind: SafetyKind.incident,
      title: 'Fall',
      notes: '',
      photoLocalPath: 'local://demo/incident.jpg',
    );
    await repo.flushOutbox(isOnline: true);
    expect(sink.applied, isEmpty);
    expect(await repo.watchPendingSyncCount().first, greaterThan(0));
  });

  test('QA fail photo enqueues upload under inspections path', () async {
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
    final qa = await auth.signInWithEmail(
      email: 'qa@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final insp = await repo.addInspection(
      session: qa,
      title: 'WIR',
      items: const [
        InspectionItem(
          id: 'cover',
          label: 'Cover',
          result: InspectionResult.fail,
          hasPhoto: true,
          photoLocalPath: 'local://demo/qa_fail.jpg',
          photoByteSizeBytes: 120 * 1024,
        ),
      ],
    );
    expect(insp.items.single.pendingPhotoUpload, isTrue);
    expect(await repo.watchPendingSyncCount().first, 2);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads.single.parentType, 'inspections');
    expect(uploader.uploads.single.attachmentId, 'cover');
    expect(sink.applied.single.operation, OutboxOperation.create);
    final items = sink.applied.single.payload['items'] as List<dynamic>;
    final item = Map<String, Object?>.from(items.single as Map);
    expect(item['photoRemoteUrl'], contains('https://'));
    expect(item['pendingPhotoUpload'], isFalse);
  });
}
