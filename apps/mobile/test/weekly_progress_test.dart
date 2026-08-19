import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/constants/app_constants.dart';
import 'package:construction_field_app/features/client_progress/domain/weekly_progress_builder.dart';
import 'package:construction_field_app/features/client_progress/domain/weekly_progress_models.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('isoWeekStart is Monday of the containing week', () {
    // 2026-08-05 is Wednesday
    final start = isoWeekStart(DateTime(2026, 8, 5));
    expect(start, DateTime(2026, 8, 3));
    expect(start.weekday, DateTime.monday);
  });

  test('buildWeeklyProgress aggregates submitted days and open issues', () {
    final now = DateTime(2026, 8, 5, 15); // Wed in week Mon 3 – Sun 9
    final pack = buildWeeklyProgress(
      projectId: 'p1',
      now: now,
      l10n: en,
      dprs: [
        _dpr(
          id: 'in-week',
          projectId: 'p1',
          day: DateTime(2026, 8, 4),
          submitted: true,
          activities: const [
            DprActivity(id: 'a1', description: 'Slab pour', location: 'L3'),
          ],
          blockers: 'Crane delay',
        ),
        _dpr(
          id: 'draft',
          projectId: 'p1',
          day: DateTime(2026, 8, 5),
          submitted: false,
        ),
        _dpr(
          id: 'other-project',
          projectId: 'p2',
          day: DateTime(2026, 8, 4),
          submitted: true,
        ),
        _dpr(
          id: 'prior-week',
          projectId: 'p1',
          day: DateTime(2026, 7, 28),
          submitted: true,
        ),
      ],
      issues: [
        _issue(id: 'i1', projectId: 'p1', title: 'Crack', status: IssueStatus.open),
        _issue(
          id: 'i2',
          projectId: 'p1',
          title: 'Closed one',
          status: IssueStatus.closed,
        ),
      ],
    );

    expect(pack.submittedDprDays, 1);
    expect(pack.days, hasLength(1));
    expect(pack.days.single.activitySummaries.single, 'Slab pour @ L3');
    expect(pack.weekBlockers.single, contains('Crane delay'));
    expect(pack.openIssueCount, 1);
    expect(pack.openIssueTitles.single, 'Crack (Open)');
    expect(pack.weekRangeLabel, '2026-08-03 to 2026-08-09');

    final text = pack.toShareText(projectName: 'Pune Tower', l10n: en);
    expect(text, contains('WEEKLY PROGRESS — Pune Tower'));
    expect(text, contains('Slab pour @ L3'));
    expect(text, contains('Crane delay'));
  });

  test('empty ISO week still builds a shareable pack', () {
    final pack = buildWeeklyProgress(
      projectId: 'p1',
      now: DateTime(2026, 8, 5),
      l10n: en,
      dprs: const [],
      issues: const [],
    );
    expect(pack.isEmptyWeek, isTrue);
    expect(pack.submittedDprDays, 0);
    expect(
      pack.toShareText(projectName: 'Pune Tower', l10n: en),
      contains('No submitted DPRs'),
    );
  });

  test('canViewWeeklyProgress allows client, PM, admin only', () {
    expect(canViewWeeklyProgress(AppRole.client), isTrue);
    expect(canViewWeeklyProgress(AppRole.projectManager), isTrue);
    expect(canViewWeeklyProgress(AppRole.admin), isTrue);
    expect(canViewWeeklyProgress(AppRole.siteEngineer), isFalse);
    expect(canViewWeeklyProgress(AppRole.qaQc), isFalse);
  });
}

DailyProgressReport _dpr({
  required String id,
  required String projectId,
  required DateTime day,
  required bool submitted,
  List<DprActivity> activities = const [],
  String blockers = '',
}) {
  return DailyProgressReport(
    id: id,
    orgId: 'o',
    projectId: projectId,
    reportDate: day,
    weather: 'Clear',
    manpowerSummary: '40',
    activities: activities,
    blockers: blockers,
    createdBy: 'u',
    createdByName: 'Asha',
    createdAt: day.toUtc(),
    updatedAt: day.toUtc(),
    submitted: submitted,
  );
}

Issue _issue({
  required String id,
  required String projectId,
  required String title,
  required IssueStatus status,
}) {
  final now = DateTime.utc(2026, 8, 5);
  return Issue(
    id: id,
    orgId: 'o',
    projectId: projectId,
    title: title,
    description: '',
    status: status,
    createdBy: 'u',
    createdByName: 'Asha',
    createdAt: now,
    updatedAt: now,
  );
}
