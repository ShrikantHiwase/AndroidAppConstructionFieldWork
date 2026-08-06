import '../../auth/domain/auth_models.dart';
import 'document_models.dart';

abstract class DocumentsRepository {
  Stream<List<DocFolder>> watchFolders(String projectId);
  Stream<List<ProjectDocument>> watchDocuments({
    required String projectId,
    String? folderId,
  });

  Future<void> ensureSeedData(AuthSession session);

  Future<ProjectDocument> uploadDocument({
    required AuthSession session,
    required UploadDocumentInput input,
  });

  Future<ProjectDocument> markDownloaded(String documentId);

  Future<DocFolder> createFolder({
    required AuthSession session,
    required String name,
    required FolderKind kind,
    String? parentId,
  });

  Future<ProjectDocument?> getDocument(String documentId);
}
