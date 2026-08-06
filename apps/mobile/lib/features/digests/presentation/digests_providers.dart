import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dpr/domain/dpr_models.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../../issues/domain/issue_models.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../data/local_digests_repository.dart';
import '../domain/digest_models.dart';
import '../domain/digests_repository.dart';

final digestsRepositoryProvider = Provider<DigestsRepository>((ref) {
  return LocalDigestsRepository(ref.watch(sharedPreferencesProvider));
});

final digestPrefsProvider =
    StateNotifierProvider<DigestPrefsController, DigestPrefs>((ref) {
  return DigestPrefsController(ref.watch(digestsRepositoryProvider));
});

class DigestPrefsController extends StateNotifier<DigestPrefs> {
  DigestPrefsController(this._repo) : super(_repo.getPrefs());

  final DigestsRepository _repo;

  Future<void> update(DigestPrefs prefs) async {
    await _repo.setPrefs(prefs);
    state = prefs;
  }
}

PmDigestSnapshot buildPmDigest({
  required AuthSession session,
  required List<Issue> issues,
  required List<Rfi> rfis,
  required List<DailyProgressReport> dprs,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final todayKey = DateTime(clock.year, clock.month, clock.day);
  final openIssues = issues
      .where(
        (i) =>
            i.projectId == session.activeProjectId &&
            (i.status == IssueStatus.open ||
                i.status == IssueStatus.inProgress),
      )
      .toList();
  final openRfis = rfis
      .where(
        (r) =>
            r.projectId == session.activeProjectId &&
            (r.status == IssueStatus.open ||
                r.status == IssueStatus.inProgress),
      )
      .toList();

  DailyProgressReport? today;
  for (final d in dprs) {
    if (d.projectId != session.activeProjectId) continue;
    final day =
        DateTime(d.reportDate.year, d.reportDate.month, d.reportDate.day);
    if (day == todayKey) {
      today = d;
      break;
    }
  }
  final missingTodayDpr = today == null || !today.submitted;

  final items = <DigestItem>[
    if (missingTodayDpr)
      DigestItem(
        kind: DigestItemKind.missingDpr,
        title: "Today's DPR incomplete",
        subtitle: today == null ? 'No draft yet' : 'Draft not submitted',
        relatedId: today?.id,
      ),
    ...openIssues.map(
      (i) => DigestItem(
        kind: DigestItemKind.openIssue,
        title: i.title,
        subtitle: 'Issue · ${i.status.label}',
        relatedId: i.id,
      ),
    ),
    ...openRfis.map(
      (r) => DigestItem(
        kind: DigestItemKind.openRfi,
        title: r.subject,
        subtitle: 'RFI · ${r.status.label}',
        relatedId: r.id,
      ),
    ),
    ...dprs
        .where(
          (d) =>
              d.projectId == session.activeProjectId &&
              d.blockers.trim().isNotEmpty,
        )
        .take(5)
        .map(
          (d) => DigestItem(
            kind: DigestItemKind.dprBlocker,
            title:
                'Blocker · ${d.reportDate.toIso8601String().split('T').first}',
            subtitle: d.blockers,
            relatedId: d.id,
          ),
        ),
  ];

  return PmDigestSnapshot(
    generatedAt: clock.toUtc(),
    items: items,
    openIssueCount: openIssues.length,
    openRfiCount: openRfis.length,
    missingTodayDpr: missingTodayDpr,
  );
}

DprNudge? evaluateDprNudge({
  required DigestPrefs prefs,
  required bool todaySubmitted,
  DateTime? now,
}) {
  if (!prefs.dprNudgeEnabled) return null;
  final clock = now ?? DateTime.now();
  if (clock.hour < prefs.nudgeHourLocal) return null;
  if (todaySubmitted) return null;
  return DprNudge(
    message:
        "Reminder: submit today's DPR (nudge after ${prefs.nudgeHourLocal}:00).",
    dueHourLocal: prefs.nudgeHourLocal,
  );
}

final pmDigestProvider = FutureProvider<PmDigestSnapshot?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null || !canViewPmDigest(session.activeRole)) return null;
  final prefs = ref.watch(digestPrefsProvider);
  if (!prefs.pmDigestEnabled) {
    return PmDigestSnapshot(
      generatedAt: DateTime.now().toUtc(),
      items: const [],
      openIssueCount: 0,
      openRfiCount: 0,
      missingTodayDpr: false,
    );
  }

  final issues = await ref.watch(issuesProvider.future);
  final rfis = await ref.watch(rfisProvider.future);
  final dprs = await ref.watch(dprsProvider.future);

  return buildPmDigest(
    session: session,
    issues: issues,
    rfis: rfis,
    dprs: dprs,
  );
});

final dprNudgeProvider = FutureProvider<DprNudge?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return null;
  final prefs = ref.watch(digestPrefsProvider);
  final today = await ref.watch(dprRepositoryProvider).todayDpr(
        session.activeProjectId,
        DateTime.now(),
      );
  return evaluateDprNudge(
    prefs: prefs,
    todaySubmitted: today?.submitted ?? false,
  );
});
