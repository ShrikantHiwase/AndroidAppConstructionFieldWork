import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_locale_provider.dart';
import '../../../core/notifications/dpr_nudge_scheduler.dart';
import '../../../l10n/app_localizations.dart';
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
  return DigestPrefsController(
    ref.watch(digestsRepositoryProvider),
    scheduler: ref.watch(dprNudgeSchedulerProvider),
  );
});

class DigestPrefsController extends StateNotifier<DigestPrefs> {
  DigestPrefsController(this._repo, {required DprNudgeScheduler scheduler})
      : _scheduler = scheduler,
        super(_repo.getPrefs());

  final DigestsRepository _repo;
  final DprNudgeScheduler _scheduler;

  Future<void> update(DigestPrefs prefs) async {
    await _repo.setPrefs(prefs);
    state = prefs;
    await syncDprNudgeSchedule(
      scheduler: _scheduler,
      enabled: prefs.dprNudgeEnabled,
      hourLocal: prefs.nudgeHourLocal,
    );
  }
}

/// Locale used when building digest copy outside a BuildContext.
AppLocalizations digestsCopy(Ref ref) {
  final override = ref.watch(appLocaleProvider);
  return lookupAppLocalizations(override ?? const Locale('en'));
}

PmDigestSnapshot buildPmDigest({
  required AuthSession session,
  required List<Issue> issues,
  required List<Rfi> rfis,
  required List<DailyProgressReport> dprs,
  required AppLocalizations l10n,
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
        title: l10n.todaysDprIncomplete,
        subtitle: today == null ? l10n.noDraftYet : l10n.draftNotSubmitted,
        relatedId: today?.id,
      ),
    ...openIssues.map(
      (i) => DigestItem(
        kind: DigestItemKind.openIssue,
        title: i.title,
        subtitle: l10n.issueStatusSubtitle(i.status.localizedLabel(l10n)),
        relatedId: i.id,
      ),
    ),
    ...openRfis.map(
      (r) => DigestItem(
        kind: DigestItemKind.openRfi,
        title: r.subject,
        subtitle: l10n.rfiStatusSubtitle(r.status.localizedLabel(l10n)),
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
            title: l10n.blockerTitle(
              d.reportDate.toIso8601String().split('T').first,
            ),
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
  required AppLocalizations l10n,
  DateTime? now,
}) {
  if (!prefs.dprNudgeEnabled) return null;
  final clock = now ?? DateTime.now();
  if (clock.hour < prefs.nudgeHourLocal) return null;
  if (todaySubmitted) return null;
  return DprNudge(
    message: l10n.dprNudgeReminder(prefs.nudgeHourLocal),
    dueHourLocal: prefs.nudgeHourLocal,
  );
}

final pmDigestProvider = FutureProvider<PmDigestSnapshot?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null || !canViewPmDigest(session.activeRole)) return null;
  final prefs = ref.watch(digestPrefsProvider);
  final l10n = digestsCopy(ref);
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
    l10n: l10n,
  );
});

final dprNudgeProvider = FutureProvider<DprNudge?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return null;
  final prefs = ref.watch(digestPrefsProvider);
  final l10n = digestsCopy(ref);
  final today = await ref.watch(dprRepositoryProvider).todayDpr(
        session.activeProjectId,
        DateTime.now(),
      );
  return evaluateDprNudge(
    prefs: prefs,
    todaySubmitted: today?.submitted ?? false,
    l10n: l10n,
  );
});
