/// Request to push a local evidence file to Firebase Storage (or demo no-op).
class StorageUploadRequest {
  const StorageUploadRequest({
    required this.orgId,
    required this.projectId,
    required this.parentType,
    required this.parentId,
    required this.attachmentId,
    required this.fileName,
    required this.contentType,
    required this.localPath,
  });

  final String orgId;
  final String projectId;
  /// e.g. `issues`
  final String parentType;
  final String parentId;
  final String attachmentId;
  final String fileName;
  final String contentType;
  final String localPath;

  /// Storage object path under the bucket.
  String get storagePath =>
      'org/$orgId/project/$projectId/$parentType/$parentId/'
      '${attachmentId}_$fileName';

  factory StorageUploadRequest.fromPayload(Map<String, Object?> payload) {
    return StorageUploadRequest(
      orgId: payload['orgId'] as String,
      projectId: payload['projectId'] as String,
      parentType: payload['parentType'] as String? ?? 'issues',
      parentId: payload['parentId'] as String,
      attachmentId: payload['attachmentId'] as String,
      fileName: payload['fileName'] as String,
      contentType: payload['contentType'] as String? ?? 'application/octet-stream',
      localPath: payload['localPath'] as String,
    );
  }

  Map<String, Object?> toPayload() => {
        'orgId': orgId,
        'projectId': projectId,
        'parentType': parentType,
        'parentId': parentId,
        'attachmentId': attachmentId,
        'fileName': fileName,
        'contentType': contentType,
        'localPath': localPath,
      };
}

abstract class StorageUploader {
  /// Uploads [request] and returns a download URL (or demo URL).
  Future<String> upload(StorageUploadRequest request);
}

/// Demo / Firebase-off — never touches the network.
class NoOpStorageUploader implements StorageUploader {
  const NoOpStorageUploader();

  @override
  Future<String> upload(StorageUploadRequest request) async {
    return 'demo://storage/${request.storagePath}';
  }
}
