import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';

enum IssueStatus {
  open,
  inProgress,
  resolved,
  closed,
}

extension IssueStatusX on IssueStatus {
  /// English label (errors / logs / legacy callers).
  String get label => switch (this) {
        IssueStatus.open => 'Open',
        IssueStatus.inProgress => 'In Progress',
        IssueStatus.resolved => 'Resolved',
        IssueStatus.closed => 'Closed',
      };

  /// Locale-aware label for UI chrome.
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        IssueStatus.open => l10n.issueStatusOpen,
        IssueStatus.inProgress => l10n.issueStatusInProgress,
        IssueStatus.resolved => l10n.issueStatusResolved,
        IssueStatus.closed => l10n.issueStatusClosed,
      };

  String get firestoreValue => switch (this) {
        IssueStatus.open => 'open',
        IssueStatus.inProgress => 'in_progress',
        IssueStatus.resolved => 'resolved',
        IssueStatus.closed => 'closed',
      };

  static IssueStatus fromFirestore(String value) => switch (value) {
        'in_progress' => IssueStatus.inProgress,
        'resolved' => IssueStatus.resolved,
        'closed' => IssueStatus.closed,
        _ => IssueStatus.open,
      };

  /// Allowed next statuses (RAYNS workflow).
  List<IssueStatus> get nextStatuses => switch (this) {
        IssueStatus.open => const [IssueStatus.inProgress, IssueStatus.closed],
        IssueStatus.inProgress => const [
            IssueStatus.resolved,
            IssueStatus.open,
          ],
        IssueStatus.resolved => const [IssueStatus.closed, IssueStatus.inProgress],
        IssueStatus.closed => const [],
      };
}

class GeoLocation {
  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.label,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? label;

  Map<String, Object?> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'label': label,
      };

  factory GeoLocation.fromJson(Map<String, Object?> json) => GeoLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
        label: json['label'] as String?,
      );
}

class MediaAttachment {
  const MediaAttachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    this.localPath,
    this.remoteUrl,
    this.pendingUpload = true,
    this.byteSizeBytes,
    this.widthPx,
  });

  final String id;
  final String fileName;
  final String contentType;
  final String? localPath;
  final String? remoteUrl;
  final bool pendingUpload;

  /// Compressed JPEG size when known (nullable for legacy JSON).
  final int? byteSizeBytes;

  /// Longest-edge width after resize when known.
  final int? widthPx;

  MediaAttachment copyWith({
    String? localPath,
    String? remoteUrl,
    bool? pendingUpload,
    int? byteSizeBytes,
    int? widthPx,
    bool clearLocalPath = false,
  }) {
    return MediaAttachment(
      id: id,
      fileName: fileName,
      contentType: contentType,
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      remoteUrl: remoteUrl ?? this.remoteUrl,
      pendingUpload: pendingUpload ?? this.pendingUpload,
      byteSizeBytes: byteSizeBytes ?? this.byteSizeBytes,
      widthPx: widthPx ?? this.widthPx,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'fileName': fileName,
        'contentType': contentType,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'pendingUpload': pendingUpload,
        'byteSizeBytes': byteSizeBytes,
        'widthPx': widthPx,
      };

  factory MediaAttachment.fromJson(Map<String, Object?> json) =>
      MediaAttachment(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        contentType: json['contentType'] as String,
        localPath: json['localPath'] as String?,
        remoteUrl: json['remoteUrl'] as String?,
        pendingUpload: json['pendingUpload'] as bool? ?? true,
        byteSizeBytes: json['byteSizeBytes'] as int?,
        widthPx: json['widthPx'] as int?,
      );
}

class StatusAuditEntry {
  const StatusAuditEntry({
    required this.from,
    required this.to,
    required this.changedBy,
    required this.changedAt,
  });

  final IssueStatus from;
  final IssueStatus to;
  final String changedBy;
  final DateTime changedAt;

  Map<String, Object?> toJson() => {
        'from': from.firestoreValue,
        'to': to.firestoreValue,
        'changedBy': changedBy,
        'changedAt': changedAt.toIso8601String(),
      };

  factory StatusAuditEntry.fromJson(Map<String, Object?> json) =>
      StatusAuditEntry(
        from: IssueStatusX.fromFirestore(json['from'] as String),
        to: IssueStatusX.fromFirestore(json['to'] as String),
        changedBy: json['changedBy'] as String,
        changedAt: DateTime.parse(json['changedAt'] as String),
      );
}

class FieldComment {
  const FieldComment({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.parentType,
    required this.parentId,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String parentType; // issue | rfi
  final String parentId;
  final String body;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'parentType': parentType,
        'parentId': parentId,
        'body': body,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
      };

  factory FieldComment.fromJson(Map<String, Object?> json) => FieldComment(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        parentType: json['parentType'] as String,
        parentId: json['parentId'] as String,
        body: json['body'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        synced: json['synced'] as bool? ?? false,
      );
}

class Issue {
  const Issue({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.assigneeName,
    this.location,
    this.attachments = const [],
    this.statusHistory = const [],
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String title;
  final String description;
  final IssueStatus status;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assigneeId;
  final String? assigneeName;
  final GeoLocation? location;
  final List<MediaAttachment> attachments;
  final List<StatusAuditEntry> statusHistory;
  final bool synced;

  Issue copyWith({
    IssueStatus? status,
    String? assigneeId,
    String? assigneeName,
    List<MediaAttachment>? attachments,
    List<StatusAuditEntry>? statusHistory,
    DateTime? updatedAt,
    bool? synced,
    GeoLocation? location,
  }) {
    return Issue(
      id: id,
      orgId: orgId,
      projectId: projectId,
      title: title,
      description: description,
      status: status ?? this.status,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      location: location ?? this.location,
      attachments: attachments ?? this.attachments,
      statusHistory: statusHistory ?? this.statusHistory,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status.firestoreValue,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'location': location?.toJson(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'statusHistory': statusHistory.map((h) => h.toJson()).toList(),
        'synced': synced,
      };

  factory Issue.fromJson(Map<String, Object?> json) => Issue(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        status: IssueStatusX.fromFirestore(json['status'] as String),
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        assigneeId: json['assigneeId'] as String?,
        assigneeName: json['assigneeName'] as String?,
        location: json['location'] == null
            ? null
            : GeoLocation.fromJson(
                Map<String, Object?>.from(json['location'] as Map),
              ),
        attachments: (json['attachments'] as List? ?? [])
            .map((e) => MediaAttachment.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
        statusHistory: (json['statusHistory'] as List? ?? [])
            .map((e) => StatusAuditEntry.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
        synced: json['synced'] as bool? ?? false,
      );
}

class Rfi {
  const Rfi({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.subject,
    required this.question,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.assigneeName,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String subject;
  final String question;
  final IssueStatus status;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assigneeId;
  final String? assigneeName;
  final bool synced;

  Rfi copyWith({
    IssueStatus? status,
    String? assigneeId,
    String? assigneeName,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Rfi(
      id: id,
      orgId: orgId,
      projectId: projectId,
      subject: subject,
      question: question,
      status: status ?? this.status,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'subject': subject,
        'question': question,
        'status': status.firestoreValue,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'synced': synced,
      };

  factory Rfi.fromJson(Map<String, Object?> json) => Rfi(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        subject: json['subject'] as String,
        question: json['question'] as String,
        status: IssueStatusX.fromFirestore(json['status'] as String),
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        assigneeId: json['assigneeId'] as String?,
        assigneeName: json['assigneeName'] as String?,
        synced: json['synced'] as bool? ?? false,
      );
}

class CreateIssueInput {
  const CreateIssueInput({
    required this.title,
    required this.description,
    this.assigneeId,
    this.assigneeName,
    this.location,
    this.attachments = const [],
  });

  final String title;
  final String description;
  final String? assigneeId;
  final String? assigneeName;
  final GeoLocation? location;
  final List<MediaAttachment> attachments;
}

class CreateRfiInput {
  const CreateRfiInput({
    required this.subject,
    required this.question,
    this.assigneeId,
    this.assigneeName,
  });

  final String subject;
  final String question;
  final String? assigneeId;
  final String? assigneeName;
}

class FieldRecordsException implements Exception {
  FieldRecordsException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Who can mutate field records for the active role.
bool canMutateFieldRecords(AppRole role) =>
    role != AppRole.client;
