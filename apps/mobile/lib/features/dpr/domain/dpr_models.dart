import '../../../core/constants/app_constants.dart';

class DprActivity {
  const DprActivity({
    required this.id,
    required this.description,
    this.location,
    this.photoCount = 0,
  });

  final String id;
  final String description;
  final String? location;
  final int photoCount;

  Map<String, Object?> toJson() => {
        'id': id,
        'description': description,
        'location': location,
        'photoCount': photoCount,
      };

  factory DprActivity.fromJson(Map<String, Object?> json) => DprActivity(
        id: json['id'] as String,
        description: json['description'] as String,
        location: json['location'] as String?,
        photoCount: json['photoCount'] as int? ?? 0,
      );
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

  String toShareText({required String projectName}) {
    final buf = StringBuffer()
      ..writeln('DAILY PROGRESS REPORT')
      ..writeln('Project: $projectName')
      ..writeln('Date: ${reportDate.toIso8601String().split('T').first}')
      ..writeln('By: $createdByName')
      ..writeln('Weather: $weather')
      ..writeln('Manpower: $manpowerSummary')
      ..writeln('Activities:');
    for (final a in activities) {
      buf.writeln(
        '- ${a.description}'
        '${a.location == null ? '' : ' @ ${a.location}'}'
        '${a.photoCount == 0 ? '' : ' (${a.photoCount} photo)'}',
      );
    }
    buf.writeln('Blockers: ${blockers.isEmpty ? 'None' : blockers}');
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
  DprException(this.message);
  final String message;
  @override
  String toString() => message;
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
  final bool synced;

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
  });

  final String drawingId;
  final int page;
  final double x;
  final double y;
  final String issueId;
  final String issueTitle;
  final String? note;
}

class DrawingException implements Exception {
  DrawingException(this.message);
  final String message;
  @override
  String toString() => message;
}

bool canPinDrawings(AppRole role) => role != AppRole.client;
