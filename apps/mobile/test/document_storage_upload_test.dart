import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/documents/data/local_documents_repository.dart';
import 'package:construction_field_app/features/documents/domain/document_models.dart';
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

  test('document upload enqueues Storage then create with remoteUrl', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final docs = LocalDocumentsRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await docs.ensureSeedData(session);
    final folder = (await docs.watchFolders(session.activeProjectId).first)
        .firstWhere((f) => f.kind == FolderKind.documentType);

    final doc = await docs.uploadDocument(
      session: session,
      input: UploadDocumentInput(
        folderId: folder.id,
        name: 'pour_log.txt',
        contentType: 'text/plain',
        textContent: 'M30 poured',
      ),
    );
    expect(await docs.watchPendingSyncCount().first, 2);

    await docs.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(uploader.uploads.first.parentType, 'documents');
    expect(uploader.uploads.first.storagePath, contains('documents/${doc.id}/'));
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    expect(sink.applied.first.payload['remoteUrl'], startsWith('https://'));
    expect(sink.applied.first.payload['pendingUpload'], isFalse);
    expect(sink.applied.first.payload.containsKey('textContent'), isFalse);
    expect(await docs.watchPendingSyncCount().first, 0);
  });
}
