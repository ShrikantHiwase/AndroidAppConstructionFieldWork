import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/dpr_nudge_scheduler.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dpr/presentation/dpr_pages.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../domain/digest_models.dart';
import 'digests_providers.dart';

class DigestsPage extends ConsumerWidget {
  const DigestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    final prefs = ref.watch(digestPrefsProvider);
    final digestAsync = ref.watch(pmDigestProvider);
    final nudgeAsync = ref.watch(dprNudgeProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.digestsTitle)),
        body: Center(child: Text(l10n.signInRequired)),
      );
    }

    final canPrefs = canManageDigestPrefs(session.activeRole);
    final canPm = canViewPmDigest(session.activeRole);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.digestsAndReminders)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.reminders, style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dailyDprNudge),
            subtitle: Text(l10n.dailyDprNudgeSubtitle(prefs.nudgeHourLocal)),
            value: prefs.dprNudgeEnabled,
            onChanged: canPrefs
                ? (v) => ref
                    .read(digestPrefsProvider.notifier)
                    .update(prefs.copyWith(dprNudgeEnabled: v))
                : null,
          ),
          if (canPrefs && prefs.dprNudgeEnabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reminderHour),
              trailing: DropdownButton<int>(
                value: prefs.nudgeHourLocal.clamp(12, 21),
                items: [
                  for (var h = 12; h <= 21; h++)
                    DropdownMenuItem(
                      value: h,
                      child: Text('$h:00'),
                    ),
                ],
                onChanged: (h) {
                  if (h == null) return;
                  ref
                      .read(digestPrefsProvider.notifier)
                      .update(prefs.copyWith(nudgeHourLocal: h));
                },
              ),
            ),
          ],
          nudgeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('$e'),
            data: (nudge) {
              if (nudge == null) {
                return Text(
                  l10n.noDprNudgeNow,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notification_important_outlined),
                title: Text(nudge.message),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TodaysDprPage(),
                      ),
                    );
                  },
                  child: Text(l10n.openDpr),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: !canPrefs
                ? null
                : () async {
                    final today = await ref
                        .read(dprRepositoryProvider)
                        .todayDpr(session.activeProjectId, DateTime.now());
                    final simulated = evaluateDprNudge(
                      prefs: prefs,
                      todaySubmitted: today?.submitted ?? false,
                      l10n: l10n,
                      now: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        prefs.nudgeHourLocal,
                        5,
                      ),
                    );
                    if (simulated != null) {
                      await ref.read(dprNudgeSchedulerProvider).showNow(
                            title: l10n.dprReminderTitle,
                            body: simulated.message,
                          );
                      await ref.read(notificationInboxProvider).add(
                            title: l10n.dprReminderTitle,
                            body: simulated.message,
                            data: const {'type': 'dpr_nudge'},
                            source: 'local_nudge',
                          );
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          simulated?.message ?? l10n.noNudgeAlreadySubmitted,
                        ),
                      ),
                    );
                  },
            child: Text(l10n.simulate5PmCheck),
          ),
          const SizedBox(height: 24),
          if (canPm) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pmDigests),
              subtitle: Text(l10n.pmDigestsSubtitle),
              value: prefs.pmDigestEnabled,
              onChanged: canPrefs
                  ? (v) => ref
                      .read(digestPrefsProvider.notifier)
                      .update(prefs.copyWith(pmDigestEnabled: v))
                  : null,
            ),
            const SizedBox(height: 8),
            Text(l10n.pmDigest, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            digestAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (digest) {
                if (digest == null) {
                  return Text(l10n.digestUnavailableRole);
                }
                if (!prefs.pmDigestEnabled) {
                  return Text(l10n.pmDigestsOff);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.digestSummaryLine(
                        digest.openIssueCount,
                        digest.openRfiCount,
                        digest.missingTodayDpr
                            ? l10n.todayDprIncomplete
                            : l10n.todayDprOk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (digest.items.isEmpty)
                      Text(l10n.queueIsClear)
                    else
                      ...digest.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(switch (item.kind) {
                            DigestItemKind.missingDpr =>
                              Icons.assignment_late_outlined,
                            DigestItemKind.openIssue =>
                              Icons.report_problem_outlined,
                            DigestItemKind.openRfi => Icons.help_outline,
                            DigestItemKind.dprBlocker => Icons.block_outlined,
                            DigestItemKind.nudge => Icons.alarm_outlined,
                          }),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final projectName = session.activeProject.name;
                        final text = digest.toShareText(
                          projectName: projectName,
                          l10n: l10n,
                        );
                        final subject = l10n.shareSubjectPmDigest(projectName);
                        final bytes = await FieldPdfExport.digest(
                          digest: digest,
                          projectName: projectName,
                        );
                        final day = digest.generatedAt
                            .toIso8601String()
                            .split('T')
                            .first;
                        final outcome =
                            await ref.read(sharePortProvider).shareFile(
                                  bytes: bytes,
                                  filename: 'pm_digest_$day.pdf',
                                  subject: subject,
                                  text: subject,
                                  fallbackText: text,
                                );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                shareSnackMessage(
                                  outcome,
                                  kind: l10n.shareKindDigestPdf,
                                  l10n: l10n,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(l10n.shareDigestPdf),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final text = digest.toShareText(
                          projectName: session.activeProject.name,
                          l10n: l10n,
                        );
                        final outcome =
                            await ref.read(sharePortProvider).shareText(
                                  text: text,
                                  subject: l10n.shareSubjectPmDigest(
                                    session.activeProject.name,
                                  ),
                                );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                shareSnackMessage(
                                  outcome,
                                  kind: l10n.shareKindDigest,
                                  l10n: l10n,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.shareAsText),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Text(
              l10n.pmDigestsStaffOnly,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
