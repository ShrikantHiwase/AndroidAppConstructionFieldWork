import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/dpr_nudge_scheduler.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dpr/presentation/dpr_pages.dart';
import '../../dpr/presentation/dpr_providers.dart';
import '../domain/digest_models.dart';
import 'digests_providers.dart';

class DigestsPage extends ConsumerWidget {
  const DigestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final prefs = ref.watch(digestPrefsProvider);
    final digestAsync = ref.watch(pmDigestProvider);
    final nudgeAsync = ref.watch(dprNudgeProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digests')),
        body: const Center(child: Text('Sign in required')),
      );
    }

    final canPrefs = canManageDigestPrefs(session.activeRole);
    final canPm = canViewPmDigest(session.activeRole);

    return Scaffold(
      appBar: AppBar(title: const Text('Digests & reminders')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Reminders', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('5 PM DPR nudge'),
            subtitle: Text(
              'Local tray reminder around ${prefs.nudgeHourLocal}:00 if '
              'today\'s DPR is not submitted. Cloud FCM cron still deferred.',
            ),
            value: prefs.dprNudgeEnabled,
            onChanged: canPrefs
                ? (v) => ref
                    .read(digestPrefsProvider.notifier)
                    .update(prefs.copyWith(dprNudgeEnabled: v))
                : null,
          ),
          nudgeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('$e'),
            data: (nudge) {
              if (nudge == null) {
                return Text(
                  'No DPR nudge right now.',
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
                  child: const Text("Open DPR"),
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
                            title: 'DPR reminder',
                            body: simulated.message,
                          );
                      await ref.read(notificationInboxProvider).add(
                            title: 'DPR reminder',
                            body: simulated.message,
                            data: const {'type': 'dpr_nudge'},
                            source: 'local_nudge',
                          );
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          simulated?.message ??
                              'No nudge (DPR already submitted or prefs off).',
                        ),
                      ),
                    );
                  },
            child: const Text('Simulate 5 PM check'),
          ),
          const SizedBox(height: 24),
          if (canPm) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('PM digests'),
              subtitle: const Text(
                'Aggregate open issues, RFIs, and DPR blockers for the active project.',
              ),
              value: prefs.pmDigestEnabled,
              onChanged: canPrefs
                  ? (v) => ref
                      .read(digestPrefsProvider.notifier)
                      .update(prefs.copyWith(pmDigestEnabled: v))
                  : null,
            ),
            const SizedBox(height: 8),
            Text('PM digest', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            digestAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (digest) {
                if (digest == null) {
                  return const Text('Digest unavailable for this role.');
                }
                if (!prefs.pmDigestEnabled) {
                  return const Text('PM digests are turned off.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Open issues: ${digest.openIssueCount} · '
                      'Open RFIs: ${digest.openRfiCount} · '
                      'Today DPR: ${digest.missingTodayDpr ? 'incomplete' : 'ok'}',
                    ),
                    const SizedBox(height: 8),
                    if (digest.items.isEmpty)
                      const Text('Queue is clear.')
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
                        );
                        final subject = 'PM digest — $projectName';
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
                                shareSnackMessage(outcome, kind: 'Digest PDF'),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Share digest PDF'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final text = digest.toShareText(
                          projectName: session.activeProject.name,
                        );
                        final outcome =
                            await ref.read(sharePortProvider).shareText(
                                  text: text,
                                  subject:
                                      'PM digest — ${session.activeProject.name}',
                                );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                shareSnackMessage(outcome, kind: 'Digest'),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share as text'),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Text(
              'PM digests are available to project managers and admins.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
