import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
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

  test('issue with photo enqueues upload then create; flush sets remoteUrl',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final field = LocalFieldRecordsRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final issue = await field.createIssue(
      session: session,
      input: CreateIssueInput(
        title: 'Crack at column',
        description: '',
        attachments: const [
          MediaAttachment(
            id: 'media_1',
            fileName: 'crack.jpg',
            contentType: 'image/jpeg',
            localPath: 'local://demo/crack.jpg',
          ),
        ],
      ),
    );
    expect(await field.watchPendingSyncCount().first, 2);

    await field.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(uploader.uploads.first.storagePath, contains('issues/${issue.id}/'));
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    final attachments =
        sink.applied.first.payload['attachments'] as List<dynamic>;
    final first = Map<String, Object?>.from(attachments.first as Map);
    expect(first['pendingUpload'], isFalse);
    expect(first['remoteUrl'], startsWith('https://example.test/'));
    expect(await field.watchPendingSyncCount().first, 0);

    final local = await field.watchIssues(session.activeProjectId).first;
    final saved = local.firstWhere((i) => i.id == issue.id);
    expect(saved.attachments.single.pendingUpload, isFalse);
    expect(saved.attachments.single.remoteUrl, isNotNull);
  });

  test('failed storage upload keeps upload entry in outbox', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final field = LocalFieldRecordsRepository(
      prefs,
      storageUploader: _FailingUploader(),
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await field.createIssue(
      session: session,
      input: const CreateIssueInput(
        title: 'Retry photo',
        description: '',
        attachments: [
          MediaAttachment(
            id: 'media_x',
            fileName: 'x.jpg',
            contentType: 'image/jpeg',
            localPath: '/tmp/missing.jpg',
          ),
        ],
      ),
    );
    await field.flushOutbox(isOnline: true);
    // Upload failed; create never ran → still 2 pending (upload + create).
    expect(await field.watchPendingSyncCount().first, 2);
  });

  test('NoOpStorageUploader returns demo URL for Fake paths', () async {
    const uploader = NoOpStorageUploader();
    final url = await uploader.upload(
      const StorageUploadRequest(
        orgId: 'org',
        projectId: 'proj',
        parentType: 'issues',
        parentId: 'issue_1',
        attachmentId: 'media_1',
        fileName: 'a.jpg',
        contentType: 'image/jpeg',
        localPath: 'local://demo/a.jpg',
      ),
    );
    expect(url, startsWith('demo://storage/'));
  });
}
