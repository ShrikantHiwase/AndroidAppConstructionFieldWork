import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../../sync/sync_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dpr/domain/dpr_models.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../../issues/domain/issue_models.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../data/local_pilot_repository.dart';
import '../domain/pilot_models.dart';
import '../domain/pilot_repository.dart';

final pilotRepositoryProvider = Provider<PilotRepository>((ref) {
  return LocalPilotRepository(ref.watch(sharedPreferencesProvider));
});

final pilotChecklistProvider =
    StateNotifierProvider<PilotChecklistController, PilotChecklistState>((ref) {
  return PilotChecklistController(ref.watch(pilotRepositoryProvider));
});

class PilotChecklistController extends StateNotifier<PilotChecklistState> {
  PilotChecklistController(this._repo) : super(_repo.getChecklist());

  final PilotRepository _repo;

  Future<void> toggle(String id) async {
    final next = state.toggle(id);
    await _repo.saveChecklist(next);
    state = next;
  }

  Future<void> reset() async {
    const empty = PilotChecklistState();
    await _repo.saveChecklist(empty);
    state = empty;
  }
}

/// Counts unique calendar days with a submitted DPR in the current ISO week.
int countSubmittedDprDaysThisWeek(
  List<DailyProgressReport> dprs, {
  required String projectId,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final weekStart = _isoWeekStart(clock);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final days = <String>{};
  for (final dpr in dprs) {
    if (dpr.projectId != projectId || !dpr.submitted) continue;
    final day = DateTime(
      dpr.reportDate.year,
      dpr.reportDate.month,
      dpr.reportDate.day,
    );
    if (day.isBefore(weekStart) || !day.isBefore(weekEnd)) continue;
    days.add(day.toIso8601String());
  }
  return days.length;
}

DateTime _isoWeekStart(DateTime day) {
  final local = DateTime(day.year, day.month, day.day);
  // Dart weekday: Mon=1 .. Sun=7
  return local.subtract(Duration(days: local.weekday - 1));
}

PilotMetricsSnapshot buildPilotSnapshot({
  required String projectId,
  required List<DailyProgressReport> dprs,
  required List<Issue> issues,
  required int pendingSyncCount,
  required List<SyncLogEntry> syncLogs,
  required PilotChecklistState checklist,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final openIssues = issues
      .where(
        (i) =>
            i.projectId == projectId &&
            (i.status == IssueStatus.open ||
                i.status == IssueStatus.inProgress),
      )
      .length;
  final errors =
      syncLogs.where((l) => l.level == SyncLogLevel.error).length;

  return PilotMetricsSnapshot(
    generatedAt: clock.toUtc(),
    projectId: projectId,
    dprSubmittedDaysThisWeek: countSubmittedDprDaysThisWeek(
      dprs,
      projectId: projectId,
      now: clock,
    ),
    openIssueCount: openIssues,
    pendingSyncCount: pendingSyncCount,
    syncLogCount: syncLogs.length,
    syncErrorCount: errors,
    checklistCompleted: checklist.completedCount,
    checklistTotal: checklist.totalCount,
  );
}

final pilotSnapshotProvider = FutureProvider<PilotMetricsSnapshot?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null || !canAccessPilotHub(session.activeRole)) {
    return null;
  }
  final checklist = ref.watch(pilotChecklistProvider);
  final dprs = await ref.watch(dprsProvider.future);
  final issues = await ref.watch(issuesProvider.future);
  final pending = await ref.watch(pendingSyncCountProvider.future);
  final logs = await ref.watch(syncLogsProvider.future);

  return buildPilotSnapshot(
    projectId: session.activeProjectId,
    dprs: dprs,
    issues: issues,
    pendingSyncCount: pending,
    syncLogs: logs,
    checklist: checklist,
  );
});
