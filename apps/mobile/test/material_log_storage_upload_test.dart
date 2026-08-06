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

  test('material photo enqueues upload then create; flush sets remoteUrl',
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

    final log = await repo.addMaterial(
      session: session,
      kind: MaterialLogKind.inward,
      material: 'OPC Cement',
      quantity: 200,
      unit: 'bags',
      activityRef: 'Slab Bay 3',
      photoLocalPath: 'local://demo/material.jpg',
      photoByteSizeBytes: 150 * 1024,
    );
    expect(log.pendingPhotoUpload, isTrue);
    expect(log.hasPhoto, isTrue);
    expect(log.photoOptional, isTrue);
    expect(await repo.watchPendingSyncCount().first, 2);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(
      uploader.uploads.first.storagePath,
      contains('material_logs/${log.id}/'),
    );
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    expect(sink.applied.first.payload['photoRemoteUrl'], contains('https://'));
    expect(sink.applied.first.payload['pendingPhotoUpload'], isFalse);

    final saved = (await repo.watchMaterials(session.activeProjectId).first)
        .firstWhere((r) => r.id == log.id);
    expect(saved.photoRemoteUrl, startsWith('https://'));
    expect(saved.pendingPhotoUpload, isFalse);
    expect(await repo.watchPendingSyncCount().first, 0);
  });

  test('failed material upload keeps create in outbox', () async {
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

    await repo.addMaterial(
      session: session,
      kind: MaterialLogKind.inward,
      material: 'Steel',
      quantity: 10,
      unit: 'tons',
      photoLocalPath: 'local://demo/material_fail.jpg',
    );
    await repo.flushOutbox(isOnline: true);
    expect(sink.applied, isEmpty);
    expect(await repo.watchPendingSyncCount().first, greaterThan(0));
  });

  test('material without photo enqueues create only', () async {
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

    final log = await repo.addMaterial(
      session: session,
      kind: MaterialLogKind.consumption,
      material: 'Cement',
      quantity: 40,
      unit: 'bags',
      activityRef: 'Columns',
    );
    expect(log.hasPhoto, isFalse);
    expect(await repo.watchPendingSyncCount().first, 1);

    await repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, isEmpty);
    expect(sink.applied.single.operation, OutboxOperation.create);
  });
}
