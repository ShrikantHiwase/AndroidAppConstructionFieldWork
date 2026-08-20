import '../../../core/errors/app_error_codes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';

class DprActivity {
  const DprActivity({
    required this.id,
    required this.description,
    this.location,
    this.hasPhoto = false,
    this.photoLocalPath,
    this.photoByteSizeBytes,
    this.photoRemoteUrl,
    this.pendingPhotoUpload = false,
  });

  final String id;
  final String description;
  final String? location;
  final bool hasPhoto;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
  final String? photoRemoteUrl;
  final bool pendingPhotoUpload;

  /// Derived from [hasPhoto] (at most one evidence photo per activity).
  int get photoCount => hasPhoto ? 1 : 0;

  DprActivity copyWith({
    String? description,
    String? location,
    bool? hasPhoto,
    String? photoLocalPath,
    int? photoByteSizeBytes,
    String? photoRemoteUrl,
    bool? pendingPhotoUpload,
    bool clearPhotoLocalPath = false,
  }) {
    return DprActivity(
      id: id,
      description: description ?? this.description,
      location: location ?? this.location,
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
        'description': description,
        'location': location,
        'photoCount': photoCount,
        'hasPhoto': hasPhoto,
        'photoLocalPath': photoLocalPath,
        'photoByteSizeBytes': photoByteSizeBytes,
        'photoRemoteUrl': photoRemoteUrl,
        'pendingPhotoUpload': pendingPhotoUpload,
      };

  factory DprActivity.fromJson(Map<String, Object?> json) {
    final path = json['photoLocalPath'] as String?;
    final remote = json['photoRemoteUrl'] as String?;
    final hasPhoto = json['hasPhoto'] as bool? ??
        ((path?.isNotEmpty ?? false) || (remote?.isNotEmpty ?? false));
    return DprActivity(
      id: json['id'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      hasPhoto: hasPhoto,
      photoLocalPath: path,
      photoByteSizeBytes: json['photoByteSizeBytes'] as int?,
      photoRemoteUrl: remote,
      pendingPhotoUpload: json['pendingPhotoUpload'] as bool? ?? false,
    );
  }
}

class DailyProgressReport {
  const DailyProgressReport({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.reportDate,
    required this.weather,
    required this.manpowerSummary,
    required this.activities,
    required this.blockers,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.submitted = false,
    this.synced = false,
  });

  final String id;
  final String orgId;
  final String projectId;
  final DateTime reportDate;
  final String weather;
  final String manpowerSummary;
  final List<DprActivity> activities;
  final String blockers;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool submitted;
  final bool synced;

  DailyProgressReport copyWith({
    String? weather,
    String? manpowerSummary,
    List<DprActivity>? activities,
    String? blockers,
    bool? submitted,
    bool? synced,
    DateTime? updatedAt,
  }) {
    return DailyProgressReport(
      id: id,
      orgId: orgId,
      projectId: projectId,
      reportDate: reportDate,
      weather: weather ?? this.weather,
      manpowerSummary: manpowerSummary ?? this.manpowerSummary,
      activities: activities ?? this.activities,
      blockers: blockers ?? this.blockers,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submitted: submitted ?? this.submitted,
      synced: synced ?? this.synced,
    );
  }

  String toShareText({
    required String projectName,
    required AppLocalizations l10n,
  }) {
    final buf = StringBuffer()
      ..writeln(l10n.dprShareHeader)
      ..writeln(l10n.dprShareProject(projectName))
      ..writeln(
        l10n.dprShareDate(reportDate.toIso8601String().split('T').first),
      )
      ..writeln(l10n.dprShareBy(createdByName))
      ..writeln(l10n.dprShareWeather(weather))
      ..writeln(l10n.dprShareManpower(manpowerSummary))
      ..writeln(l10n.dprShareActivities);
    for (final a in activities) {
      final locationPart = a.location == null || a.location!.isEmpty
          ? ''
          : l10n.dprShareLocationPart(a.location!);
      final photoPart =
          a.photoCount == 0 ? '' : l10n.dprSharePhotoPart(a.photoCount);
      buf.writeln('- ${a.description}$locationPart$photoPart');
    }
    buf.writeln(
      l10n.dprShareBlockers(blockers.isEmpty ? l10n.noneLabel : blockers),
    );
    return buf.toString();
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'reportDate': reportDate.toIso8601String(),
        'weather': weather,
        'manpowerSummary': manpowerSummary,
        'activities': activities.map((a) => a.toJson()).toList(),
        'blockers': blockers,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'submitted': submitted,
        'synced': synced,
      };

  factory DailyProgressReport.fromJson(Map<String, Object?> json) =>
      DailyProgressReport(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        reportDate: DateTime.parse(json['reportDate'] as String),
        weather: json['weather'] as String? ?? '',
        manpowerSummary: json['manpowerSummary'] as String? ?? '',
        activities: (json['activities'] as List? ?? [])
            .map((e) => DprActivity.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
        blockers: json['blockers'] as String? ?? '',
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        submitted: json['submitted'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
      );
}

class CreateDprInput {
  const CreateDprInput({
    required this.weather,
    required this.manpowerSummary,
    required this.activities,
    required this.blockers,
    this.reportDate,
  });

  final String weather;
  final String manpowerSummary;
  final List<DprActivity> activities;
  final String blockers;
  final DateTime? reportDate;
}

class DprException implements Exception {
  DprException(this.code, {this.arg1, this.arg2});

  final String code;
  final String? arg1;
  final String? arg2;

  String get englishMessage =>
      englishAppErrorMessage(code, arg1: arg1, arg2: arg2);

  @override
  String toString() => englishMessage;
}

bool canEditDpr(AppRole role) => role != AppRole.client;

/// Drawing sheet that can host punch pins.
class DrawingSheet {
  const DrawingSheet({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.title,
    required this.version,
    required this.pageCount,
  });

  final String id;
  final String orgId;
  final String projectId;
  final String title;
  final String version;
  final int pageCount;

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'projectId': projectId,
        'title': title,
        'version': version,
        'pageCount': pageCount,
      };

  factory DrawingSheet.fromJson(Map<String, Object?> json) => DrawingSheet(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        version: json['version'] as String,
        pageCount: json['pageCount'] as int? ?? 1,
      );
}

class DrawingPin {
  const DrawingPin({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.drawingId,
    required this.page,
    required this.x,
    required this.y,
    required this.issueId,
    required this.issueTitle,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.note,
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
  final String drawingId;
  final int page;
  /// Normalized 0..1 coordinates on the drawing page.
  final double x;
  final double y;
  final String issueId;
  final String issueTitle;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? note;
  final bool hasPhoto;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
  final String? photoRemoteUrl;
  final bool pendingPhotoUpload;
  final bool synced;

  DrawingPin copyWith({
    bool? synced,
    bool? hasPhoto,
    String? photoLocalPath,
    int? photoByteSizeBytes,
    String? photoRemoteUrl,
    bool? pendingPhotoUpload,
    bool clearPhotoLocalPath = false,
  }) {
    return DrawingPin(
      id: id,
      orgId: orgId,
      projectId: projectId,
      drawingId: drawingId,
      page: page,
      x: x,
      y: y,
      issueId: issueId,
      issueTitle: issueTitle,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      note: note,
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
        'drawingId': drawingId,
        'page': page,
        'x': x,
        'y': y,
        'issueId': issueId,
        'issueTitle': issueTitle,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
        'hasPhoto': hasPhoto,
        'photoLocalPath': photoLocalPath,
        'photoByteSizeBytes': photoByteSizeBytes,
        'photoRemoteUrl': photoRemoteUrl,
        'pendingPhotoUpload': pendingPhotoUpload,
        'synced': synced,
      };

  factory DrawingPin.fromJson(Map<String, Object?> json) => DrawingPin(
        id: json['id'] as String,
        orgId: json['orgId'] as String,
        projectId: json['projectId'] as String,
        drawingId: json['drawingId'] as String,
        page: json['page'] as int? ?? 1,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        issueId: json['issueId'] as String,
        issueTitle: json['issueTitle'] as String,
        createdBy: json['createdBy'] as String,
        createdByName: json['createdByName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        note: json['note'] as String?,
        hasPhoto: json['hasPhoto'] as bool? ??
            ((json['photoLocalPath'] as String?)?.isNotEmpty ?? false),
        photoLocalPath: json['photoLocalPath'] as String?,
        photoByteSizeBytes: json['photoByteSizeBytes'] as int?,
        photoRemoteUrl: json['photoRemoteUrl'] as String?,
        pendingPhotoUpload: json['pendingPhotoUpload'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
      );
}

class CreatePinInput {
  const CreatePinInput({
    required this.drawingId,
    required this.page,
    required this.x,
    required this.y,
    required this.issueId,
    required this.issueTitle,
    this.note,
    this.photoLocalPath,
    this.photoByteSizeBytes,
  });

  final String drawingId;
  final int page;
  final double x;
  final double y;
  final String issueId;
  final String issueTitle;
  final String? note;
  final String? photoLocalPath;
  final int? photoByteSizeBytes;
}

class DrawingException implements Exception {
  DrawingException(this.code, {this.arg1, this.arg2});

  final String code;
  final String? arg1;
  final String? arg2;

  String get englishMessage =>
      englishAppErrorMessage(code, arg1: arg1, arg2: arg2);

  @override
  String toString() => englishMessage;
}

bool canPinDrawings(AppRole role) => role != AppRole.client;
