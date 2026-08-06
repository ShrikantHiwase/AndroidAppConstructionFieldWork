import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/device/document_file_policy.dart';
import 'package:construction_field_app/core/device/fake_document_file_picker.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/documents/data/local_documents_repository.dart';
import 'package:construction_field_app/features/documents/domain/document_models.dart';
import 'package:construction_field_app/features/documents/domain/pdf_open_source.dart';
import 'package:construction_field_app/sync/remote/outbox_remote_sink.dart';
import 'package:construction_field_app/sync/remote/storage_uploader.dart';
import 'package:construction_field_app/sync/outbox/outbox_entry.dart';

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

  test('FakeDocumentFilePicker returns typed stubs with sizes', () async {
    final picker = FakeDocumentFilePicker();
    final txt = await picker.pick(preferredType: DocContentType.txt);
    expect(txt, isNotNull);
    expect(txt!.localPath, startsWith('local://demo/documents/'));
    expect(txt.byteSizeBytes, DocumentFilePolicy.demoTxtBytes);
    expect(txt.textContent, isNotEmpty);

    final pdf = await picker.pick(preferredType: DocContentType.pdf);
    expect(pdf!.contentType, 'application/pdf');
    expect(pdf.localPath, DemoDocumentAssets.gaPlanAssetUri);
    expect(pdf.byteSizeBytes, DocumentFilePolicy.demoPdfBytes);
  });

  test('picked stub upload joins soft cache and reclaim clears path', () async {
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

    final picked = await FakeDocumentFilePicker().pick(
      preferredType: DocContentType.csv,
    );
    final doc = await docs.uploadDocument(
      session: session,
      input: UploadDocumentInput(
        folderId: folder.id,
        name: picked!.fileName,
        contentType: picked.contentType,
        textContent: picked.textContent,
        localFilePath: picked.localPath,
        sizeBytes: picked.byteSizeBytes,
      ),
    );
    expect(doc.localFilePath, startsWith('local://'));
    expect(doc.sizeBytes, DocumentFilePolicy.demoCsvBytes);

    final before = docs.estimateLocalCache();
    expect(before.label, 'docs');
    expect(before.estimatedBytes, greaterThan(0));

    await docs.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(sink.applied.single.payload['remoteUrl'], contains('https://'));

    final reclaimable = docs.estimateLocalCache().reclaimableBytes;
    expect(reclaimable, greaterThan(0));
    final freed = await docs.reclaimUploadedLocalPaths();
    expect(freed, reclaimable);
    expect(
      (await docs
              .watchDocuments(
                projectId: session.activeProjectId,
                folderId: folder.id,
              )
              .first)
          .firstWhere((d) => d.id == doc.id)
          .localFilePath,
      isNull,
    );
  });
}
