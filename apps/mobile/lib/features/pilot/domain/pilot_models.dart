import '../../../core/constants/app_constants.dart';

/// Canonical UAT item ids — keep in sync with docs/UAT_Checklist.md.
abstract final class UatItemIds {
  static const all = <String>[
    'env_install',
    'env_warm_start',
    'env_offline_badge',
    'env_banner',
    'auth_roles',
    'auth_project_switch',
    'auth_biometric',
    'auth_client_readonly',
    'issues_create',
    'issues_offline_sync',
    'issues_status',
    'issues_assign',
    'issues_rfi',
    'issues_voice',
    'docs_browse',
    'docs_viewer',
    'docs_upload_gate',
    'dpr_submit',
    'dpr_share',
    'dpr_voice',
    'dpr_pin',
    'ops_safety',
    'ops_qa',
    'ops_labour_material',
    'ops_client_block',
    'digest_nudge',
    'digest_pm',
    'sync_status',
    'sync_conflict',
    'firebase_gate',
    'firebase_membership',
    'firebase_rules',
  ];

  static String label(String id) => switch (id) {
        'env_install' => 'App installs on pilot device',
        'env_warm_start' => 'Warm start acceptable on low-end Android',
        'env_offline_badge' => 'Offline badge visible',
        'env_banner' => 'DEMO / FIREBASE banner correct',
        'auth_roles' => 'All roles can sign in',
        'auth_project_switch' => 'Project switcher works',
        'auth_biometric' => 'Biometric unlock stub works',
        'auth_client_readonly' => 'Client is read-only',
        'issues_create' => 'Create issue with GPS/photo',
        'issues_offline_sync' => 'Offline create then sync',
        'issues_status' => 'Status workflow + audit',
        'issues_assign' => 'PM assign / engineer blocked',
        'issues_rfi' => 'RFI + comment',
        'issues_voice' => 'Voice note on issue',
        'docs_browse' => 'Document hierarchy browse',
        'docs_viewer' => 'PDF/TXT/CSV viewer',
        'docs_upload_gate' => 'Upload role gate',
        'dpr_submit' => "Today's DPR submit <3 min",
        'dpr_share' => 'DPR WhatsApp/PDF copy',
        'dpr_voice' => 'Voice note on DPR',
        'dpr_pin' => 'Drawing pin to issue',
        'ops_safety' => 'Safety photo rules',
        'ops_qa' => 'QA photo-on-fail',
        'ops_labour_material' => 'Labour + materials',
        'ops_client_block' => 'Client blocked on site ops',
        'digest_nudge' => '5 PM DPR nudge',
        'digest_pm' => 'PM digest + copy',
        'sync_status' => 'Sync status + cleanup',
        'sync_conflict' => 'Conflict policy labels',
        'firebase_gate' => 'Firebase configured (when ready)',
        'firebase_membership' => 'Membership sign-in',
        'firebase_rules' => 'Rules deny cross-project',
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

  /// Error rate 0..1; null when no sync samples yet.
  double? get syncFailureRate =>
      syncLogCount == 0 ? null : syncErrorCount / syncLogCount;

  bool get dprTargetMet => dprSubmittedDaysThisWeek >= 4;

  bool get syncTargetMet {
    final rate = syncFailureRate;
    if (rate == null) return syncLogCount == 0;
    return rate < 0.02;
  }

  String toShareText({required String projectName}) {
    final rate = syncFailureRate;
    final buf = StringBuffer()
      ..writeln('PILOT SNAPSHOT — $projectName')
      ..writeln('Generated: ${generatedAt.toIso8601String()}')
      ..writeln(
        'DPR days submitted (ISO week): $dprSubmittedDaysThisWeek '
        '(target ≥4) ${dprTargetMet ? 'OK' : 'BELOW'}',
      )
      ..writeln('Open issues: $openIssueCount')
      ..writeln('Pending sync: $pendingSyncCount')
      ..writeln(
        'Sync errors: $syncErrorCount / $syncLogCount'
        '${rate == null ? '' : ' (${(rate * 100).toStringAsFixed(1)}%)'} '
        '(target <2%) ${syncTargetMet ? 'OK' : 'WATCH'}',
      )
      ..writeln(
        'UAT checklist: $checklistCompleted / $checklistTotal',
      );
    return buf.toString();
  }
}

bool canAccessPilotHub(AppRole role) => switch (role) {
      AppRole.admin || AppRole.projectManager => true,
      _ => false,
    };
