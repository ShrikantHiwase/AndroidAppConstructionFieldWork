import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/documents/data/local_documents_repository.dart';
import 'package:construction_field_app/features/documents/domain/document_models.dart';

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
    expect(docs.any((d) => d.kind == DocContentType.pdf), isTrue);
    expect(docs.any((d) => d.kind == DocContentType.txt), isTrue);
    expect(docs.any((d) => d.kind == DocContentType.csv), isTrue);
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
