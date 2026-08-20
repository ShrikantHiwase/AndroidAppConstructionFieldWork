import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/documents/data/local_documents_repository.dart';
import 'package:construction_field_app/features/documents/domain/document_models.dart';
import 'package:construction_field_app/features/documents/domain/pdf_open_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDocumentsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = LocalDocumentsRepository(prefs);
  });

  test('seed creates Project > Discipline > Type hierarchy with files', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await repo.ensureSeedData(session);
    final folders = await repo.watchFolders(session.activeProjectId).first;
    expect(folders.where((f) => f.kind == FolderKind.discipline), isNotEmpty);
    expect(folders.where((f) => f.kind == FolderKind.documentType), isNotEmpty);

    final docs = await repo
        .watchDocuments(projectId: session.activeProjectId)
        .first;
    expect(docs, isNotEmpty);
    final pdf = docs.firstWhere((d) => d.kind == DocContentType.pdf);
    expect(pdf.localFilePath, DemoDocumentAssets.gaPlanAssetUri);
    expect(docs.any((d) => d.kind == DocContentType.txt), isTrue);
    expect(docs.any((d) => d.kind == DocContentType.csv), isTrue);

    // Pune demo uses firebase/seed stable ids + remoteUrl.
    expect(session.activeProjectId, 'proj_pune_tower');
    expect(
      folders.map((f) => f.id),
      containsAll([
        'folder_seed_structural',
        'folder_seed_mep',
        'folder_seed_drawings',
        'folder_seed_specs',
        'folder_seed_schedules',
      ]),
    );
    expect(pdf.id, 'doc_seed_ga_plan');
    expect(pdf.remoteUrl, 'demo://seed/ga-plan-level-02.pdf');
    expect(
      docs.map((d) => d.id),
      containsAll(['doc_seed_ga_plan', 'doc_seed_mix_notes', 'doc_seed_cable_csv']),
    );
  });

  test('client cannot upload; engineer can', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final client = await auth.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await repo.ensureSeedData(client);
    final typeFolder = (await repo.watchFolders(client.activeProjectId).first)
        .firstWhere((f) => f.kind == FolderKind.documentType);

    expect(
      () => repo.uploadDocument(
        session: client,
        input: UploadDocumentInput(
          folderId: typeFolder.id,
          name: 'secret.txt',
          contentType: 'text/plain',
          textContent: 'nope',
        ),
      ),
      throwsA(isA<DocumentsException>()),
    );

    await auth.signOut();
    final engineer = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    // Engineer may be on same project id from demo data.
    await repo.ensureSeedData(engineer);
    final engFolder = (await repo.watchFolders(engineer.activeProjectId).first)
        .firstWhere((f) => f.kind == FolderKind.documentType);

    final uploaded = await repo.uploadDocument(
      session: engineer,
      input: UploadDocumentInput(
        folderId: engFolder.id,
        name: 'field_note.txt',
        contentType: 'text/plain',
        textContent: 'Pour delayed',
      ),
    );
    expect(uploaded.downloaded, isTrue);
    expect(uploaded.synced, isFalse);
    expect(uploaded.pendingUpload, isTrue);
    expect(uploaded.localFilePath, startsWith('local://demo/documents/'));

    await repo.flushOutbox(isOnline: true);
    expect(await repo.watchPendingSyncCount().first, 0);
    final after = await repo.getDocument(uploaded.id);
    expect(after!.synced, isTrue);
    expect(after.pendingUpload, isFalse);
    expect(after.remoteUrl, startsWith('demo://storage/'));
  });

  test('markDownloaded flips on-device flag', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await repo.ensureSeedData(session);
    final cloudDoc = (await repo
            .watchDocuments(projectId: session.activeProjectId)
            .first)
        .firstWhere((d) => !d.downloaded);
    final updated = await repo.markDownloaded(cloudDoc.id);
    expect(updated.downloaded, isTrue);
  });
}
