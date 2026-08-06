import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/pilot_models.dart';
import 'pilot_providers.dart';

class PilotHubPage extends ConsumerWidget {
  const PilotHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final checklist = ref.watch(pilotChecklistProvider);
    final snapshotAsync = ref.watch(pilotSnapshotProvider);

    if (session == null || !canAccessPilotHub(session.activeRole)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pilot')),
        body: const Center(
          child: Text('Pilot hub is for PM and Admin.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilot / UAT'),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset UAT checklist?'),
                  content: const Text('Clears all local ticks on this device.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(pilotChecklistProvider.notifier).reset();
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Hypercare snapshot',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Targets: DPR ≥4 days this week · sync errors <2%. '
            'Full guide: docs/Hypercare_Metrics.md',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          snapshotAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (snap) {
              if (snap == null) return const Text('No snapshot');
              final rate = snap.syncFailureRate;
              final projectName = session.activeProject.name;
              final shareText = snap.toShareText(projectName: projectName);
              final subject = 'Pilot snapshot — $projectName';

              Future<void> sharePdf() async {
                final bytes = await FieldPdfExport.pilot(
                  snapshot: snap,
                  projectName: projectName,
                );
                final day =
                    snap.generatedAt.toIso8601String().split('T').first;
                final outcome = await ref.read(sharePortProvider).shareFile(
                      bytes: bytes,
                      filename: 'pilot_snapshot_$day.pdf',
                      subject: subject,
                      text: subject,
                      fallbackText: shareText,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        shareSnackMessage(outcome, kind: 'Pilot PDF'),
                      ),
                    ),
                  );
                }
              }

              Future<void> shareAsText() async {
                final outcome = await ref.read(sharePortProvider).shareText(
                      text: shareText,
                      subject: subject,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        shareSnackMessage(outcome, kind: 'Pilot snapshot'),
                      ),
                    ),
                  );
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MetricTile(
                    label: 'DPR days submitted (ISO week)',
                    value: '${snap.dprSubmittedDaysThisWeek}',
                    ok: snap.dprTargetMet,
                    hint: 'target ≥4',
                  ),
                  _MetricTile(
                    label: 'Open issues',
                    value: '${snap.openIssueCount}',
                    ok: true,
                    hint: 'active project',
                  ),
                  _MetricTile(
                    label: 'Pending sync',
                    value: '${snap.pendingSyncCount}',
                    ok: snap.pendingSyncCount == 0,
                    hint: 'outbox',
                  ),
                  _MetricTile(
                    label: 'Sync failure rate',
                    value: rate == null
                        ? 'n/a'
                        : '${(rate * 100).toStringAsFixed(1)}%',
                    ok: snap.syncTargetMet,
                    hint:
                        '${snap.syncErrorCount}/${snap.syncLogCount} · target <2%',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: sharePdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Share pilot PDF'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: shareAsText,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share as text'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'UAT checklist (${checklist.completedCount}/${checklist.totalCount})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: checklist.progress),
          const SizedBox(height: 8),
          Text(
            'Mirrors docs/UAT_Checklist.md — tick as you verify on device.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...UatItemIds.all.map(
            (id) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: checklist.isChecked(id),
              onChanged: (_) =>
                  ref.read(pilotChecklistProvider.notifier).toggle(id),
              title: Text(UatItemIds.label(id)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.ok,
    required this.hint,
  });

  final String label;
  final String value;
  final bool ok;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
        color: color,
      ),
      title: Text(label),
      subtitle: Text(hint),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    );
  }
}
