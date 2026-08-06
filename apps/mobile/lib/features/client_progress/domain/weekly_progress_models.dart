import '../../../core/constants/app_constants.dart';

/// One submitted DPR day summarized for the client weekly pack.
class WeeklyProgressDayLine {
  const WeeklyProgressDayLine({
    required this.reportDate,
    required this.weather,
    required this.manpowerSummary,
    required this.activitySummaries,
    this.blockers,
  });

  final DateTime reportDate;
  final String weather;
  final String manpowerSummary;
  final List<String> activitySummaries;
  final String? blockers;

  String get dateLabel => reportDate.toIso8601String().split('T').first;
}

/// ISO-week progress pack for client self-serve share (no PM compile).
class WeeklyProgressSnapshot {
  const WeeklyProgressSnapshot({
    required this.generatedAt,
    required this.weekStart,
    required this.weekEndExclusive,
    required this.submittedDprDays,
    required this.days,
    required this.openIssueCount,
    required this.openIssueTitles,
    required this.weekBlockers,
  });

  final DateTime generatedAt;
  final DateTime weekStart;
  final DateTime weekEndExclusive;
  final int submittedDprDays;
  final List<WeeklyProgressDayLine> days;
  final int openIssueCount;
  final List<String> openIssueTitles;
  final List<String> weekBlockers;

  String get weekRangeLabel {
    final start = weekStart.toIso8601String().split('T').first;
    final endInclusive = weekEndExclusive
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;
    return '$start to $endInclusive';
  }

  bool get isEmptyWeek => days.isEmpty;

  String toShareText({required String projectName}) {
    final buf = StringBuffer()
      ..writeln('WEEKLY PROGRESS — $projectName')
      ..writeln('Week: $weekRangeLabel')
      ..writeln('Generated: ${generatedAt.toIso8601String()}')
      ..writeln('Submitted DPR days: $submittedDprDays / 7')
      ..writeln('Open issues: $openIssueCount')
      ..writeln('---');
    if (days.isEmpty) {
      buf.writeln('No submitted DPRs in this ISO week yet.');
    } else {
      for (final day in days) {
        buf.writeln('${day.dateLabel} · weather ${day.weather} · '
            'manpower ${day.manpowerSummary}');
        for (final a in day.activitySummaries) {
          buf.writeln('  - $a');
        }
        if (day.blockers != null && day.blockers!.isNotEmpty) {
          buf.writeln('  Blockers: ${day.blockers}');
        }
      }
    }
    if (weekBlockers.isNotEmpty) {
      buf.writeln('---');
      buf.writeln('Blockers this week:');
      for (final b in weekBlockers) {
        buf.writeln('• $b');
      }
    }
    if (openIssueTitles.isNotEmpty) {
      buf.writeln('---');
      buf.writeln('Open issues:');
      for (final t in openIssueTitles) {
        buf.writeln('• $t');
      }
    }
    return buf.toString();
  }
}

/// Client is primary; PM/Admin may open the same pack when demoing handoff.
bool canViewWeeklyProgress(AppRole role) => switch (role) {
      AppRole.client ||
      AppRole.projectManager ||
      AppRole.admin =>
        true,
      _ => false,
    };
