import '../../dpr/domain/dpr_models.dart';
import '../../issues/domain/issue_models.dart';
import 'weekly_progress_models.dart';

/// Monday 00:00 local of the ISO week containing [day].
DateTime isoWeekStart(DateTime day) {
  final local = DateTime(day.year, day.month, day.day);
  return local.subtract(Duration(days: local.weekday - 1));
}

WeeklyProgressSnapshot buildWeeklyProgress({
  required String projectId,
  required List<DailyProgressReport> dprs,
  required List<Issue> issues,
  DateTime? now,
  int maxActivitiesPerDay = 5,
  int maxOpenIssueTitles = 8,
}) {
  final clock = now ?? DateTime.now();
  final weekStart = isoWeekStart(clock);
  final weekEnd = weekStart.add(const Duration(days: 7));

  final weekDprs = dprs.where((d) {
    if (d.projectId != projectId || !d.submitted) return false;
    final day = DateTime(
      d.reportDate.year,
      d.reportDate.month,
      d.reportDate.day,
    );
    return !day.isBefore(weekStart) && day.isBefore(weekEnd);
  }).toList()
    ..sort((a, b) => a.reportDate.compareTo(b.reportDate));

  final byDay = <String, DailyProgressReport>{};
  for (final d in weekDprs) {
    final key = DateTime(
      d.reportDate.year,
      d.reportDate.month,
      d.reportDate.day,
    ).toIso8601String();
    // Prefer latest update if multiple submitted for same calendar day.
    final existing = byDay[key];
    if (existing == null || d.updatedAt.isAfter(existing.updatedAt)) {
      byDay[key] = d;
    }
  }

  final days = byDay.values.map((d) {
    final activities = d.activities
        .take(maxActivitiesPerDay)
        .map((a) {
          final loc = a.location;
          return loc == null || loc.isEmpty
              ? a.description
              : '${a.description} @ $loc';
        })
        .toList();
    final blockers = d.blockers.trim();
    return WeeklyProgressDayLine(
      reportDate: DateTime(
        d.reportDate.year,
        d.reportDate.month,
        d.reportDate.day,
      ),
      weather: d.weather.trim().isEmpty ? '—' : d.weather.trim(),
      manpowerSummary:
          d.manpowerSummary.trim().isEmpty ? '—' : d.manpowerSummary.trim(),
      activitySummaries: activities,
      blockers: blockers.isEmpty ? null : blockers,
    );
  }).toList()
    ..sort((a, b) => a.reportDate.compareTo(b.reportDate));

  final openIssues = issues
      .where(
        (i) =>
            i.projectId == projectId &&
            (i.status == IssueStatus.open ||
                i.status == IssueStatus.inProgress),
      )
      .toList();

  final weekBlockers = days
      .where((d) => d.blockers != null && d.blockers!.isNotEmpty)
      .map((d) => '${d.dateLabel}: ${d.blockers}')
      .toList();

  return WeeklyProgressSnapshot(
    generatedAt: clock.toUtc(),
    weekStart: weekStart,
    weekEndExclusive: weekEnd,
    submittedDprDays: days.length,
    days: days,
    openIssueCount: openIssues.length,
    openIssueTitles: openIssues
        .take(maxOpenIssueTitles)
        .map((i) => '${i.title} (${i.status.label})')
        .toList(),
    weekBlockers: weekBlockers,
  );
}
