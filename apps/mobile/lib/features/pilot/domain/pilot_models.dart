import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';

/// Canonical UAT item ids — keep in sync with docs/UAT_Checklist.md.
abstract final class UatItemIds {
  /// Checkbox count must match docs/UAT_Checklist.md (excluding sign-off table).
  static const expectedDocCount = 35;

  static const all = <String>[
    // Environment
    'env_install',
    'env_warm_start',
    'env_offline_badge',
    'env_banner',
    // Auth & roles
    'auth_roles',
    'auth_project_switch',
    'auth_biometric',
    'auth_client_readonly',
    // Issues & RFIs
    'issues_create',
    'issues_offline_sync',
    'issues_status',
    'issues_assign',
    'issues_rfi',
    'issues_voice',
    // Documents
    'docs_browse',
    'docs_viewer',
    'docs_upload_gate',
    // DPR & drawings
    'dpr_submit',
    'dpr_activity_evidence',
    'dpr_share',
    'dpr_voice',
    'dpr_pin',
    // Site ops
    'ops_safety',
    'ops_qa',
    'ops_labour_material',
    'ops_client_block',
    // Digests & sync
    'digest_nudge',
    'digest_pm',
    'sync_status',
    'sync_conflict',
    'pilot_share_pdf',
    'client_weekly_pdf',
    // Firebase (when configured)
    'firebase_gate',
    'firebase_membership',
    'firebase_rules',
  ];

  static String label(String id) => switch (id) {
        'env_install' => 'App installs / launches on pilot device (API 24+)',
        'env_warm_start' => 'Warm start feels <2s on pilot hardware',
        'env_offline_badge' => 'Offline badge visible on home',
        'env_banner' => 'DEMO / FIREBASE banner correct',
        'auth_roles' => 'All roles can sign in (demo or Firebase)',
        'auth_project_switch' => 'Project switcher changes active project',
        'auth_biometric' => 'Biometric unlock stub works',
        'auth_client_readonly' =>
          'Client cannot create issues, edit DPR, or mutate site ops',
        'issues_create' =>
          'Create issue with GPS + compressed photo; Pilot median updates',
        'issues_offline_sync' => 'Offline create then sync online',
        'issues_status' => 'Status workflow + audit trail',
        'issues_assign' => 'PM can assign; engineer cannot',
        'issues_rfi' => 'RFI + threaded comment',
        'issues_voice' => 'Voice note on issue detail',
        'docs_browse' => 'Browse Project → Discipline → Type → Files',
        'docs_viewer' => 'Open seeded PDF (pdfrx) / TXT / CSV viewer',
        'docs_upload_gate' => 'Engineer upload; client blocked',
        'dpr_submit' =>
          "Today's DPR submit <3 min; Pilot median updates after Submit",
        'dpr_activity_evidence' =>
          'Optional DPR activity evidence photo uploads on flush',
        'dpr_share' => 'Share DPR PDF via system sheet; text share works',
        'dpr_voice' => 'Voice note on DPR after first save',
        'dpr_pin' =>
          'Drawing pin linked to issue; optional evidence photo on flush',
        'ops_safety' =>
          'Safety toolbox / observation photo rules (flush to Storage)',
        'ops_qa' => 'QA fail requires photo; pass allowed',
        'ops_labour_material' =>
          'Labour muster + material logs (optional evidence photos)',
        'ops_client_block' => 'Client blocked from site ops mutations',
        'digest_nudge' => '5 PM DPR nudge prefs + Simulate (local tray)',
        'digest_pm' => 'PM digest + Share digest PDF',
        'sync_status' =>
          'Sync status logs, cache meter, telemetry, cleanup',
        'sync_conflict' => 'Conflict policy labels on flush',
        'pilot_share_pdf' => 'Pilot hub Share pilot PDF (PM/Admin)',
        'client_weekly_pdf' =>
          'Client Weekly progress → Share weekly PDF',
        'firebase_gate' => 'Firebase configured + FIREBASE banner',
        'firebase_membership' => 'Membership Auth sign-in',
        'firebase_rules' => 'Rules deny cross-project reads',
        _ => id,
      };
}

class PilotChecklistState {
  const PilotChecklistState({this.checkedIds = const {}});

  final Set<String> checkedIds;

  int get completedCount =>
      checkedIds.where(UatItemIds.all.contains).length;

  int get totalCount => UatItemIds.all.length;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  bool isChecked(String id) => checkedIds.contains(id);

  PilotChecklistState toggle(String id) {
    final next = Set<String>.from(checkedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return PilotChecklistState(checkedIds: next);
  }

  Map<String, Object?> toJson() => {
        'checkedIds': checkedIds.toList()..sort(),
      };

  factory PilotChecklistState.fromJson(Map<String, Object?> json) {
    final raw = json['checkedIds'] as List? ?? const [];
    return PilotChecklistState(
      checkedIds: raw.map((e) => e.toString()).toSet(),
    );
  }
}

class PilotMetricsSnapshot {
  const PilotMetricsSnapshot({
    required this.generatedAt,
    required this.projectId,
    required this.dprSubmittedDaysThisWeek,
    required this.openIssueCount,
    required this.pendingSyncCount,
    required this.syncLogCount,
    required this.syncErrorCount,
    required this.checklistCompleted,
    required this.checklistTotal,
    this.issueCreateSampleCount = 0,
    this.issueCreateMedianMs,
    this.dprSubmitSampleCount = 0,
    this.dprSubmitMedianMs,
  });

  final DateTime generatedAt;
  final String projectId;
  final int dprSubmittedDaysThisWeek;
  final int openIssueCount;
  final int pendingSyncCount;
  final int syncLogCount;
  final int syncErrorCount;
  final int checklistCompleted;
  final int checklistTotal;
  final int issueCreateSampleCount;
  final int? issueCreateMedianMs;
  final int dprSubmitSampleCount;
  final int? dprSubmitMedianMs;

  /// Minimum successful creates before median counts toward Hypercare.
  static const int issueCreateMinSamples = 3;

  /// Hypercare target: median create duration under 90 seconds.
  static const int issueCreateTargetMs = 90 * 1000;

  /// Minimum successful DPR submits before median counts.
  static const int dprSubmitMinSamples = 3;

  /// UAT / training target: submit Today's DPR under 3 minutes.
  static const int dprSubmitTargetMs = 3 * 60 * 1000;

  /// Error rate 0..1; null when no sync samples yet.
  double? get syncFailureRate =>
      syncLogCount == 0 ? null : syncErrorCount / syncLogCount;

  bool get dprTargetMet => dprSubmittedDaysThisWeek >= 4;

  bool get syncTargetMet {
    final rate = syncFailureRate;
    if (rate == null) return syncLogCount == 0;
    return rate < 0.02;
  }

  /// Null when fewer than [issueCreateMinSamples] samples for this project.
  bool? get issueCreateTargetMet {
    if (issueCreateSampleCount < issueCreateMinSamples) return null;
    final median = issueCreateMedianMs;
    if (median == null) return null;
    return median < issueCreateTargetMs;
  }

  /// Null when fewer than [dprSubmitMinSamples] samples for this project.
  bool? get dprSubmitTargetMet {
    if (dprSubmitSampleCount < dprSubmitMinSamples) return null;
    final median = dprSubmitMedianMs;
    if (median == null) return null;
    return median < dprSubmitTargetMs;
  }

  String get issueCreateMedianLabel =>
      _medianLabel(issueCreateMedianMs, issueCreateSampleCount);

  String get dprSubmitMedianLabel =>
      _medianLabel(dprSubmitMedianMs, dprSubmitSampleCount);

  static String _medianLabel(int? median, int sampleCount) {
    if (median == null || sampleCount == 0) return 'n/a';
    if (median < 1000) return '${median}ms';
    final seconds = median / 1000;
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
    }
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(minutes < 10 ? 1 : 0)}m';
  }

  String toShareText({
    required String projectName,
    required AppLocalizations l10n,
  }) {
    final rate = syncFailureRate;
    final createStatus = switch (issueCreateTargetMet) {
      true => l10n.pilotStatusOk,
      false => l10n.pilotStatusBelow,
      null => l10n.pilotStatusNeedSamples(issueCreateMinSamples),
    };
    final dprSubmitStatus = switch (dprSubmitTargetMet) {
      true => l10n.pilotStatusOk,
      false => l10n.pilotStatusBelow,
      null => l10n.pilotStatusNeedSamples(dprSubmitMinSamples),
    };
    final buf = StringBuffer()
      ..writeln(l10n.pilotShareHeader(projectName))
      ..writeln(l10n.pilotShareGenerated(generatedAt.toIso8601String()))
      ..writeln(
        l10n.pilotShareDprDays(
          dprSubmittedDaysThisWeek,
          dprTargetMet ? l10n.pilotStatusOk : l10n.pilotStatusBelow,
        ),
      )
      ..writeln(
        l10n.pilotShareDprSubmitMedian(
          dprSubmitMedianLabel,
          dprSubmitSampleCount,
          dprSubmitStatus,
        ),
      )
      ..writeln(
        l10n.pilotShareIssueCreateMedian(
          issueCreateMedianLabel,
          issueCreateSampleCount,
          createStatus,
        ),
      )
      ..writeln(l10n.pilotShareOpenIssues(openIssueCount))
      ..writeln(l10n.pilotSharePendingSync(pendingSyncCount))
      ..writeln(
        l10n.pilotShareSyncErrors(
          syncErrorCount,
          syncLogCount,
          rate == null
              ? ''
              : l10n.pilotShareSyncRatePart(
                  (rate * 100).toStringAsFixed(1),
                ),
          syncTargetMet ? l10n.pilotStatusOk : l10n.pilotStatusWatch,
        ),
      )
      ..writeln(l10n.pilotShareUat(checklistCompleted, checklistTotal));
    return buf.toString();
  }
}

/// Duration sample for Pilot hypercare (issue create / DPR submit).
class PilotDurationSample {
  const PilotDurationSample({
    required this.durationMs,
    required this.projectId,
    required this.recordedAt,
  });

  final int durationMs;
  final String projectId;
  final DateTime recordedAt;

  Map<String, Object?> toJson() => {
        'durationMs': durationMs,
        'projectId': projectId,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory PilotDurationSample.fromJson(Map<String, Object?> json) =>
      PilotDurationSample(
        durationMs: json['durationMs'] as int? ?? 0,
        projectId: json['projectId'] as String? ?? '',
        recordedAt: DateTime.parse(
          json['recordedAt'] as String? ??
              DateTime.now().toUtc().toIso8601String(),
        ),
      );
}

/// Alias names for call-site clarity (same shape / JSON).
typedef IssueCreateTimingSample = PilotDurationSample;
typedef DprSubmitTimingSample = PilotDurationSample;

/// Median of [values] (ms). Empty → null.
int? medianDurationMs(List<int> values) {
  if (values.isEmpty) return null;
  final sorted = List<int>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// Median duration for [projectId] from persisted samples.
int? durationMedianMsForProject(
  List<PilotDurationSample> samples, {
  required String projectId,
}) {
  final durations = samples
      .where((s) => s.projectId == projectId && s.durationMs > 0)
      .map((s) => s.durationMs)
      .toList();
  return medianDurationMs(durations);
}

int durationSampleCountForProject(
  List<PilotDurationSample> samples, {
  required String projectId,
}) {
  return samples
      .where((s) => s.projectId == projectId && s.durationMs > 0)
      .length;
}

/// Median create duration for [projectId] from persisted samples.
int? issueCreateMedianMsForProject(
  List<IssueCreateTimingSample> samples, {
  required String projectId,
}) =>
    durationMedianMsForProject(samples, projectId: projectId);

int issueCreateSampleCountForProject(
  List<IssueCreateTimingSample> samples, {
  required String projectId,
}) =>
    durationSampleCountForProject(samples, projectId: projectId);

int? dprSubmitMedianMsForProject(
  List<DprSubmitTimingSample> samples, {
  required String projectId,
}) =>
    durationMedianMsForProject(samples, projectId: projectId);

int dprSubmitSampleCountForProject(
  List<DprSubmitTimingSample> samples, {
  required String projectId,
}) =>
    durationSampleCountForProject(samples, projectId: projectId);

bool canAccessPilotHub(AppRole role) => switch (role) {
      AppRole.admin || AppRole.projectManager => true,
      _ => false,
    };
