import '../../../core/constants/app_constants.dart';

enum SafetyKind { toolboxTalk, observation, incident }

class SafetyRecord {
  const SafetyRecord({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.kind,
    required this.title,
    required this.notes,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.photoRequired = false,
    this.hasPhoto = false,
    this.photoLocalPath,
    this.photoByteSizeBytes,
    this.photoRemoteUrl,
    this.pendingPhotoUpload = false,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final SafetyKind kind;
  final String title;
  final String notes;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool photoRequired;
  final bool hasPhoto;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
  final String? photoRemoteUrl;
  final bool pendingPhotoUpload;
  final bool synced;

  SafetyRecord copyWith({
    bool? synced,
    bool? hasPhoto,
    String? photoLocalPath,
    int? photoByteSizeBytes,
    String? photoRemoteUrl,
    bool? pendingPhotoUpload,
    bool clearPhotoLocalPath = false,
  }) {
    return SafetyRecord(
      id: id,
      orgId: orgId,
      projectId: projectId,
      kind: kind,
      title: title,
      notes: notes,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      photoRequired: photoRequired,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      photoLocalPath:
          clearPhotoLocalPath ? null : (photoLocalPath ?? this.photoLocalPath),
      photoByteSizeBytes: photoByteSizeBytes ?? this.photoByteSizeBytes,
      photoRemoteUrl: photoRemoteUrl ?? this.photoRemoteUrl,
      pendingPhotoUpload: pendingPhotoUpload ?? this.pendingPhotoUpload,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'kind': kind.name,
        'title': title,
        'notes': notes,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'photoRequired': photoRequired,
        'hasPhoto': hasPhoto,
        'photoLocalPath': photoLocalPath,
        'photoByteSizeBytes': photoByteSizeBytes,
        'photoRemoteUrl': photoRemoteUrl,
        'pendingPhotoUpload': pendingPhotoUpload,
        'synced': synced,
      };

  factory SafetyRecord.fromJson(Map<String, Object?> json) => SafetyRecord(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        kind: SafetyKind.values.byName(json['kind'] as String),
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        photoRequired: json['photoRequired'] as bool? ?? false,
        hasPhoto: json['hasPhoto'] as bool? ??
            ((json['photoLocalPath'] as String?)?.isNotEmpty ?? false),
        photoLocalPath: json['photoLocalPath'] as String?,
        photoByteSizeBytes: json['photoByteSizeBytes'] as int?,
        photoRemoteUrl: json['photoRemoteUrl'] as String?,
        pendingPhotoUpload: json['pendingPhotoUpload'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
      );
}

enum InspectionResult { pass, fail, na }

class InspectionItem {
  const InspectionItem({
    required this.id,
    required this.label,
    required this.result,
    this.photoOnFail = true,
    this.hasPhoto = false,
    this.photoLocalPath,
    this.photoByteSizeBytes,
    this.photoRemoteUrl,
    this.pendingPhotoUpload = false,
  });

  final String id;
  final String label;
  final InspectionResult result;
  final bool photoOnFail;
  final bool hasPhoto;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
  final String? photoRemoteUrl;
  final bool pendingPhotoUpload;

  InspectionItem copyWith({
    InspectionResult? result,
    bool? hasPhoto,
    String? photoLocalPath,
    int? photoByteSizeBytes,
    String? photoRemoteUrl,
    bool? pendingPhotoUpload,
    bool clearPhotoLocalPath = false,
  }) {
    return InspectionItem(
      id: id,
      label: label,
      result: result ?? this.result,
      photoOnFail: photoOnFail,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      photoLocalPath:
          clearPhotoLocalPath ? null : (photoLocalPath ?? this.photoLocalPath),
      photoByteSizeBytes: photoByteSizeBytes ?? this.photoByteSizeBytes,
      photoRemoteUrl: photoRemoteUrl ?? this.photoRemoteUrl,
      pendingPhotoUpload: pendingPhotoUpload ?? this.pendingPhotoUpload,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'result': result.name,
        'photoOnFail': photoOnFail,
        'hasPhoto': hasPhoto,
        'photoLocalPath': photoLocalPath,
        'photoByteSizeBytes': photoByteSizeBytes,
        'photoRemoteUrl': photoRemoteUrl,
        'pendingPhotoUpload': pendingPhotoUpload,
      };

  factory InspectionItem.fromJson(Map<String, Object?> json) => InspectionItem(
        id: json['id'] as String,
        label: json['label'] as String,
        result: InspectionResult.values.byName(json['result'] as String),
        photoOnFail: json['photoOnFail'] as bool? ?? true,
        hasPhoto: json['hasPhoto'] as bool? ??
            ((json['photoLocalPath'] as String?)?.isNotEmpty ?? false),
        photoLocalPath: json['photoLocalPath'] as String?,
        photoByteSizeBytes: json['photoByteSizeBytes'] as int?,
        photoRemoteUrl: json['photoRemoteUrl'] as String?,
        pendingPhotoUpload: json['pendingPhotoUpload'] as bool? ?? false,
      );
}

class QaInspection {
  const QaInspection({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.title,
    required this.items,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String title;
  final List<InspectionItem> items;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool synced;

  bool get hasFailures =>
      items.any((i) => i.result == InspectionResult.fail);

  QaInspection copyWith({bool? synced}) {
    return QaInspection(
      id: id,
      orgId: orgId,
      projectId: projectId,
      title: title,
      items: items,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'title': title,
        'items': items.map((e) => e.toJson()).toList(),
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
      };

  factory QaInspection.fromJson(Map<String, Object?> json) => QaInspection(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        items: (json['items'] as List? ?? [])
            .map((e) => InspectionItem.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        synced: json['synced'] as bool? ?? false,
      );
}

class LabourMuster {
  const LabourMuster({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.musterDate,
    required this.trade,
    required this.subcontractor,
    required this.headcount,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.geofenceOk = true,
    this.photoOptional = true,
    this.hasPhoto = false,
    this.photoLocalPath,
    this.photoByteSizeBytes,
    this.photoRemoteUrl,
    this.pendingPhotoUpload = false,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final DateTime musterDate;
  final String trade;
  final String subcontractor;
  final int headcount;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool geofenceOk;

  /// Muster evidence photo is optional (India supervisor-led muster).
  final bool photoOptional;
  final bool hasPhoto;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
  final String? photoRemoteUrl;
  final bool pendingPhotoUpload;
  final bool synced;

  LabourMuster copyWith({
    bool? synced,
    bool? hasPhoto,
    String? photoLocalPath,
    int? photoByteSizeBytes,
    String? photoRemoteUrl,
    bool? pendingPhotoUpload,
    bool clearPhotoLocalPath = false,
  }) {
    return LabourMuster(
      id: id,
      orgId: orgId,
      projectId: projectId,
      musterDate: musterDate,
      trade: trade,
      subcontractor: subcontractor,
      headcount: headcount,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      geofenceOk: geofenceOk,
      photoOptional: photoOptional,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      photoLocalPath:
          clearPhotoLocalPath ? null : (photoLocalPath ?? this.photoLocalPath),
      photoByteSizeBytes: photoByteSizeBytes ?? this.photoByteSizeBytes,
      photoRemoteUrl: photoRemoteUrl ?? this.photoRemoteUrl,
      pendingPhotoUpload: pendingPhotoUpload ?? this.pendingPhotoUpload,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'musterDate': musterDate.toIso8601String(),
        'trade': trade,
        'subcontractor': subcontractor,
        'headcount': headcount,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'geofenceOk': geofenceOk,
        'photoOptional': photoOptional,
        'hasPhoto': hasPhoto,
        'photoLocalPath': photoLocalPath,
        'photoByteSizeBytes': photoByteSizeBytes,
        'photoRemoteUrl': photoRemoteUrl,
        'pendingPhotoUpload': pendingPhotoUpload,
        'synced': synced,
      };

  factory LabourMuster.fromJson(Map<String, Object?> json) => LabourMuster(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        musterDate: DateTime.parse(json['musterDate'] as String),
        trade: json['trade'] as String,
        subcontractor: json['subcontractor'] as String,
        headcount: json['headcount'] as int? ?? 0,
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        geofenceOk: json['geofenceOk'] as bool? ?? true,
        photoOptional: json['photoOptional'] as bool? ?? true,
        hasPhoto: json['hasPhoto'] as bool? ??
            ((json['photoLocalPath'] as String?)?.isNotEmpty ?? false),
        photoLocalPath: json['photoLocalPath'] as String?,
        photoByteSizeBytes: json['photoByteSizeBytes'] as int?,
        photoRemoteUrl: json['photoRemoteUrl'] as String?,
        pendingPhotoUpload: json['pendingPhotoUpload'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
      );
}

enum MaterialLogKind { inward, consumption }

class MaterialLog {
  const MaterialLog({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.kind,
    required this.material,
    required this.quantity,
    required this.unit,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.activityRef,
    this.photoOptional = true,
    this.hasPhoto = false,
    this.photoLocalPath,
    this.photoByteSizeBytes,
    this.photoRemoteUrl,
    this.pendingPhotoUpload = false,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final MaterialLogKind kind;
  final String material;
  final double quantity;
  final String unit;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? activityRef;

  /// GRN / consumption evidence photo is optional.
  final bool photoOptional;
  final bool hasPhoto;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
  final String? photoRemoteUrl;
  final bool pendingPhotoUpload;
  final bool synced;

  MaterialLog copyWith({
    bool? synced,
    bool? hasPhoto,
    String? photoLocalPath,
    int? photoByteSizeBytes,
    String? photoRemoteUrl,
    bool? pendingPhotoUpload,
    bool clearPhotoLocalPath = false,
  }) {
    return MaterialLog(
      id: id,
      orgId: orgId,
      projectId: projectId,
      kind: kind,
      material: material,
      quantity: quantity,
      unit: unit,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      activityRef: activityRef,
      photoOptional: photoOptional,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      photoLocalPath:
          clearPhotoLocalPath ? null : (photoLocalPath ?? this.photoLocalPath),
      photoByteSizeBytes: photoByteSizeBytes ?? this.photoByteSizeBytes,
      photoRemoteUrl: photoRemoteUrl ?? this.photoRemoteUrl,
      pendingPhotoUpload: pendingPhotoUpload ?? this.pendingPhotoUpload,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'kind': kind.name,
        'material': material,
        'quantity': quantity,
        'unit': unit,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'activityRef': activityRef,
        'photoOptional': photoOptional,
        'hasPhoto': hasPhoto,
        'photoLocalPath': photoLocalPath,
        'photoByteSizeBytes': photoByteSizeBytes,
        'photoRemoteUrl': photoRemoteUrl,
        'pendingPhotoUpload': pendingPhotoUpload,
        'synced': synced,
      };

  factory MaterialLog.fromJson(Map<String, Object?> json) => MaterialLog(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        kind: MaterialLogKind.values.byName(json['kind'] as String),
        material: json['material'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String? ?? 'bags',
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        activityRef: json['activityRef'] as String?,
        photoOptional: json['photoOptional'] as bool? ?? true,
        hasPhoto: json['hasPhoto'] as bool? ??
            ((json['photoLocalPath'] as String?)?.isNotEmpty ?? false),
        photoLocalPath: json['photoLocalPath'] as String?,
        photoByteSizeBytes: json['photoByteSizeBytes'] as int?,
        photoRemoteUrl: json['photoRemoteUrl'] as String?,
        pendingPhotoUpload: json['pendingPhotoUpload'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
      );
}

class SiteOpsException implements Exception {
  SiteOpsException(this.message);
  final String message;
  @override
  String toString() => message;
}

bool canMutateSiteOps(AppRole role) => role != AppRole.client;
