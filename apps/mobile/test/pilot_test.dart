import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/constants/app_constants.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/features/pilot/data/local_pilot_repository.dart';
import 'package:construction_field_app/features/pilot/domain/pilot_models.dart';
import 'package:construction_field_app/features/pilot/presentation/pilot_providers.dart';
import 'package:construction_field_app/sync/sync_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('checklist toggles and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalPilotRepository(prefs);
    expect(repo.getChecklist().completedCount, 0);

    final next = repo.getChecklist().toggle('dpr_submit');
    await repo.saveChecklist(next);
    expect(repo.getChecklist().isChecked('dpr_submit'), isTrue);
    expect(repo.getChecklist().completedCount, 1);
  });

  test('DPR days this week counts unique submitted days', () {
    const project = 'proj_pune_tower';
    final now = DateTime(2026, 8, 6); // Thursday
    final weekMon = DateTime(2026, 8, 3);
    final dprs = [
      DailyProgressReport(
        id: '1',
        orgId: 'o',
        projectId: project,
        reportDate: weekMon,
        weather: '',
        manpowerSummary: '',
        activities: const [],
        blockers: '',
        createdBy: 'u',
        createdByName: 'A',
        createdAt: weekMon,
        updatedAt: weekMon,
        submitted: true,
      ),
      DailyProgressReport(
        id: '2',
        orgId: 'o',
        projectId: project,
        reportDate: weekMon.add(const Duration(days: 1)),
        weather: '',
        manpowerSummary: '',
        activities: const [],
        blockers: '',
        createdBy: 'u',
        createdByName: 'A',
        createdAt: weekMon,
        updatedAt: weekMon,
        submitted: true,
      ),
      DailyProgressReport(
        id: '3',
        orgId: 'o',
        projectId: project,
        reportDate: weekMon.add(const Duration(days: 2)),
        weather: '',
        manpowerSummary: '',
        activities: const [],
        blockers: '',
        createdBy: 'u',
        createdByName: 'A',
        createdAt: weekMon,
        updatedAt: weekMon,
        submitted: false,
      ),
      DailyProgressReport(
        id: '4',
        orgId: 'o',
        projectId: 'other',
        reportDate: weekMon,
        weather: '',
        manpowerSummary: '',
        activities: const [],
        blockers: '',
        createdBy: 'u',
        createdByName: 'A',
        createdAt: weekMon,
        updatedAt: weekMon,
        submitted: true,
      ),
    ];
    expect(
      countSubmittedDprDaysThisWeek(dprs, projectId: project, now: now),
      2,
    );
  });

  test('pilot snapshot sync rate and share text', () {
    final snap = buildPilotSnapshot(
      projectId: 'proj_pune_tower',
      dprs: const [],
      issues: [
        Issue(
          id: 'i1',
          orgId: 'o',
          projectId: 'proj_pune_tower',
          title: 'Gap',
          description: '',
          status: IssueStatus.open,
          createdBy: 'u',
          createdByName: 'A',
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
      pendingSyncCount: 1,
      syncLogs: [
        SyncLogEntry(
          id: 'l1',
          at: DateTime.utc(2026, 8, 1),
          message: 'ok',
          level: SyncLogLevel.info,
        ),
        SyncLogEntry(
          id: 'l2',
          at: DateTime.utc(2026, 8, 1),
          message: 'fail',
          level: SyncLogLevel.error,
        ),
      ],
      checklist: const PilotChecklistState(checkedIds: {'dpr_submit'}),
      issueCreateTimings: [
        PilotDurationSample(
          durationMs: 45000,
          projectId: 'proj_pune_tower',
          recordedAt: DateTime.utc(2026, 8, 5),
        ),
        PilotDurationSample(
          durationMs: 60000,
          projectId: 'proj_pune_tower',
          recordedAt: DateTime.utc(2026, 8, 5),
        ),
        PilotDurationSample(
          durationMs: 50000,
          projectId: 'proj_pune_tower',
          recordedAt: DateTime.utc(2026, 8, 6),
        ),
      ],
      dprSubmitTimings: [
        PilotDurationSample(
          durationMs: 90000,
          projectId: 'proj_pune_tower',
          recordedAt: DateTime.utc(2026, 8, 5),
        ),
        PilotDurationSample(
          durationMs: 120000,
          projectId: 'proj_pune_tower',
          recordedAt: DateTime.utc(2026, 8, 5),
        ),
        PilotDurationSample(
          durationMs: 100000,
          projectId: 'proj_pune_tower',
          recordedAt: DateTime.utc(2026, 8, 6),
        ),
      ],
      now: DateTime(2026, 8, 6),
    );

    expect(snap.openIssueCount, 1);
    expect(snap.syncFailureRate, closeTo(0.5, 0.001));
    expect(snap.syncTargetMet, isFalse);
    expect(snap.dprTargetMet, isFalse);
    expect(snap.issueCreateSampleCount, 3);
    expect(snap.issueCreateMedianMs, 50000);
    expect(snap.issueCreateTargetMet, isTrue);
    expect(snap.dprSubmitSampleCount, 3);
    expect(snap.dprSubmitMedianMs, 100000);
    expect(snap.dprSubmitTargetMet, isTrue);
    expect(canAccessPilotHub(AppRole.admin), isTrue);
    expect(canAccessPilotHub(AppRole.siteEngineer), isFalse);
    final text = snap.toShareText(projectName: 'Pune Tower A');
    expect(text, contains('PILOT SNAPSHOT'));
    expect(text, contains('Issue create median'));
    expect(text, contains('DPR submit median'));
    expect(text, contains('50s'));
    expect(text, contains('1.7m'));
  });

  test('medianDurationMs handles even and odd lists', () {
    expect(medianDurationMs(const []), isNull);
    expect(medianDurationMs(const [10]), 10);
    expect(medianDurationMs(const [10, 30, 20]), 20);
    expect(medianDurationMs(const [10, 40]), 25);
  });

  test('issue create timings persist and drive project median', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalPilotRepository(prefs);
    await repo.recordIssueCreateTiming(
      PilotDurationSample(
        durationMs: 120000,
        projectId: 'p1',
        recordedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    await repo.recordIssueCreateTiming(
      PilotDurationSample(
        durationMs: 80000,
        projectId: 'p1',
        recordedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    await repo.recordIssueCreateTiming(
      PilotDurationSample(
        durationMs: 90000,
        projectId: 'other',
        recordedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    final samples = repo.getIssueCreateTimings();
    expect(samples, hasLength(3));
    expect(
      issueCreateMedianMsForProject(samples, projectId: 'p1'),
      100000,
    );
    expect(
      issueCreateSampleCountForProject(samples, projectId: 'p1'),
      2,
    );
    final snap = buildPilotSnapshot(
      projectId: 'p1',
      dprs: const [],
      issues: const [],
      pendingSyncCount: 0,
      syncLogs: const [],
      checklist: const PilotChecklistState(),
      issueCreateTimings: samples,
    );
    expect(snap.issueCreateTargetMet, isNull); // need 3 samples
  });

  test('dpr submit timings persist and drive project median', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalPilotRepository(prefs);
    await repo.recordDprSubmitTiming(
      PilotDurationSample(
        durationMs: 240000,
        projectId: 'p1',
        recordedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    await repo.recordDprSubmitTiming(
      PilotDurationSample(
        durationMs: 150000,
        projectId: 'p1',
        recordedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    await repo.recordDprSubmitTiming(
      PilotDurationSample(
        durationMs: 160000,
        projectId: 'p1',
        recordedAt: DateTime.utc(2026, 8, 6),
      ),
    );
    final samples = repo.getDprSubmitTimings();
    expect(dprSubmitMedianMsForProject(samples, projectId: 'p1'), 160000);
    final snap = buildPilotSnapshot(
      projectId: 'p1',
      dprs: const [],
      issues: const [],
      pendingSyncCount: 0,
      syncLogs: const [],
      checklist: const PilotChecklistState(),
      dprSubmitTimings: samples,
    );
    expect(snap.dprSubmitTargetMet, isTrue); // 160s < 180s
    expect(snap.dprSubmitMedianLabel, '2.7m');
  });
}
