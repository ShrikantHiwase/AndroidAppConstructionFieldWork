import '../../../core/errors/app_error_codes.dart';
import '../../../core/constants/app_constants.dart';

/// Hierarchy level in Project → Discipline → Document Type → Files.
enum FolderKind { discipline, documentType }

class DocFolder {
  const DocFolder({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.name,
    required this.kind,
    this.parentId,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String name;
  final FolderKind kind;
  final String? parentId;
  final bool synced;

  DocFolder copyWith({bool? synced}) {
    return DocFolder(
      id: id,
      orgId: orgId,
      projectId: projectId,
      name: name,
      kind: kind,
      parentId: parentId,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'name': name,
        'kind': kind.name,
        'parentId': parentId,
        'synced': synced,
      };

  factory DocFolder.fromJson(Map<String, Object?> json) => DocFolder(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        name: json['name'] as String,
        kind: FolderKind.values.byName(json['kind'] as String),
        parentId: json['parentId'] as String?,
        synced: json['synced'] as bool? ?? true,
      );
}

enum DocContentType { pdf, txt, csv, other }

extension DocContentTypeX on DocContentType {
  String get label => name.toUpperCase();

  static DocContentType fromMimeOrName(String contentType, String fileName) {
    final lower = '${contentType.toLowerCase()}|${fileName.toLowerCase()}';
    if (lower.contains('pdf')) return DocContentType.pdf;
    if (lower.contains('csv')) return DocContentType.csv;
    if (lower.contains('text') || lower.contains('.txt')) {
      return DocContentType.txt;
    }
    return DocContentType.other;
  }
}

class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.folderId,
    required this.name,
    required this.contentType,
    required this.kind,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.sizeBytes = 0,
    this.downloaded = false,
    this.synced = true,
    this.textContent,
    this.pdfPages = const [],
    this.localFilePath,
    this.remoteUrl,
    this.pendingUpload = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String folderId;
  final String name;
  final String contentType;
  final DocContentType kind;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sizeBytes;
  final bool downloaded;
  final bool synced;
  /// Inline body for TXT/CSV demo viewing.
  final String? textContent;
  /// Optional text pages when no asset/file path is available for pdfrx.
  final List<String> pdfPages;
  /// On-device path (or `local://demo/...` for Fake uploads).
  final String? localFilePath;
  final String? remoteUrl;
  final bool pendingUpload;

  ProjectDocument copyWith({
    bool? downloaded,
    bool? synced,
    DateTime? updatedAt,
    String? localFilePath,
    String? remoteUrl,
    bool? pendingUpload,
    int? sizeBytes,
    bool clearLocalFilePath = false,
  }) {
    return ProjectDocument(
      id: id,
      orgId: orgId,
      projectId: projectId,
      folderId: folderId,
      name: name,
      contentType: contentType,
      kind: kind,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloaded: downloaded ?? this.downloaded,
      synced: synced ?? this.synced,
      textContent: textContent,
      pdfPages: pdfPages,
      localFilePath: clearLocalFilePath
          ? null
          : (localFilePath ?? this.localFilePath),
      remoteUrl: remoteUrl ?? this.remoteUrl,
      pendingUpload: pendingUpload ?? this.pendingUpload,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'folderId': folderId,
        'name': name,
        'contentType': contentType,
        'kind': kind.name,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'downloaded': downloaded,
        'synced': synced,
        'textContent': textContent,
        'pdfPages': pdfPages,
        'localFilePath': localFilePath,
        'remoteUrl': remoteUrl,
        'pendingUpload': pendingUpload,
      };

  factory ProjectDocument.fromJson(Map<String, Object?> json) =>
      ProjectDocument(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        folderId: json['folderId'] as String,
        name: json['name'] as String,
        contentType: json['contentType'] as String,
        kind: DocContentType.values.byName(json['kind'] as String? ?? 'other'),
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        downloaded: json['downloaded'] as bool? ?? false,
        synced: json['synced'] as bool? ?? true,
        textContent: json['textContent'] as String?,
        pdfPages: (json['pdfPages'] as List? ?? []).cast<String>(),
        localFilePath: json['localFilePath'] as String?,
        remoteUrl: json['remoteUrl'] as String?,
        pendingUpload: json['pendingUpload'] as bool? ?? false,
      );
}

class UploadDocumentInput {
  const UploadDocumentInput({
    required this.folderId,
    required this.name,
    required this.contentType,
    this.textContent,
    this.pdfPages = const [],
    this.localFilePath,
    this.sizeBytes,
  });

  final String folderId;
  final String name;
  final String contentType;
  final String? textContent;
  final List<String> pdfPages;
  /// Real path or omit — repo assigns a demo `local://` path when null.
  final String? localFilePath;
  final int? sizeBytes;
}

class DocumentsException implements Exception {
  DocumentsException(this.code, {this.arg1, this.arg2});

  final String code;
  final String? arg1;
  final String? arg2;

  String get englishMessage =>
      englishAppErrorMessage(code, arg1: arg1, arg2: arg2);

  @override
  String toString() => englishMessage;
}

bool canUploadDocuments(AppRole role) => switch (role) {
      AppRole.admin ||
      AppRole.projectManager ||
      AppRole.siteEngineer ||
      AppRole.qaQc =>
        true,
      AppRole.client => false,
    };

bool canManageFolders(AppRole role) =>
    role == AppRole.admin || role == AppRole.projectManager;
