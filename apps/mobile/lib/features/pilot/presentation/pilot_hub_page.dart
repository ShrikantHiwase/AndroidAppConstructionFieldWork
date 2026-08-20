import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/pilot_models.dart';
import 'pilot_providers.dart';
import '../../../core/errors/localize_app_error.dart';

class PilotHubPage extends ConsumerWidget {
  const PilotHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    final checklist = ref.watch(pilotChecklistProvider);
    final snapshotAsync = ref.watch(pilotSnapshotProvider);

    if (session == null || !canAccessPilotHub(session.activeRole)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.pilot)),
        body: Center(
          child: Text(l10n.pilotHubRestricted),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pilotUatTitle),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final dialogL10n = AppLocalizations.of(ctx);
                  return AlertDialog(
                    title: Text(dialogL10n.resetUatChecklistTitle),
                    content: Text(dialogL10n.resetUatChecklistBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(dialogL10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(dialogL10n.resetAction),
                      ),
                    ],
                  );
                },
              );
              if (ok == true) {
                await ref.read(pilotChecklistProvider.notifier).reset();
              }
            },
            child: Text(l10n.resetAction),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.hypercareSnapshot,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.hypercareTargetsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          snapshotAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(localizeAppError(e, l10n)),
            data: (snap) {
              if (snap == null) return Text(l10n.noSnapshot);
              final rate = snap.syncFailureRate;
              final projectName = session.activeProject.name;
              final shareText = snap.toShareText(
                projectName: projectName,
                l10n: l10n,
              );
              final subject = l10n.shareSubjectPilot(projectName);

              Future<void> sharePdf() async {
                final bytes = await FieldPdfExport.pilot(
                  snapshot: snap,
                  projectName: projectName,
                  l10n: l10n,
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
                        shareSnackMessage(
                          outcome,
                          kind: l10n.shareKindPilotPdf,
                          l10n: l10n,
                        ),
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
                        shareSnackMessage(
                          outcome,
                          kind: l10n.shareKindPilotSnapshot,
                          l10n: l10n,
                        ),
                      ),
                    ),
                  );
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MetricTile(
                    label: l10n.metricDprDaysSubmitted,
                    value: '${snap.dprSubmittedDaysThisWeek}',
                    ok: snap.dprTargetMet,
                    hint: l10n.hintTargetGte4,
                  ),
                  _MetricTile(
                    label: l10n.metricDprSubmitMedian,
                    value: snap.dprSubmitMedianLabel,
                    ok: snap.dprSubmitTargetMet != false,
                    hint: snap.dprSubmitSampleCount <
                            PilotMetricsSnapshot.dprSubmitMinSamples
                        ? 'n=${snap.dprSubmitSampleCount} · need '
                            '>=${PilotMetricsSnapshot.dprSubmitMinSamples} '
                            'samples'
                        : 'n=${snap.dprSubmitSampleCount} · target <3m',
                  ),
                  _MetricTile(
                    label: l10n.metricIssueCreateMedian,
                    value: snap.issueCreateMedianLabel,
                    ok: snap.issueCreateTargetMet != false,
                    hint: snap.issueCreateSampleCount <
                            PilotMetricsSnapshot.issueCreateMinSamples
                        ? 'n=${snap.issueCreateSampleCount} · need '
                            '>=${PilotMetricsSnapshot.issueCreateMinSamples} '
                            'samples'
                        : 'n=${snap.issueCreateSampleCount} · target <90s',
                  ),
                  _MetricTile(
                    label: l10n.metricOpenIssues,
                    value: '${snap.openIssueCount}',
                    ok: true,
                    hint: l10n.hintActiveProject,
                  ),
                  _MetricTile(
                    label: l10n.metricPendingSync,
                    value: '${snap.pendingSyncCount}',
                    ok: snap.pendingSyncCount == 0,
                    hint: l10n.hintOutbox,
                  ),
                  _MetricTile(
                    label: l10n.metricSyncFailureRate,
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
                    label: Text(l10n.sharePilotPdf),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: shareAsText,
                    icon: const Icon(Icons.ios_share),
                    label: Text(l10n.shareAsText),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            l10n.uatChecklistProgress(
              checklist.completedCount,
              checklist.totalCount,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: checklist.progress),
          const SizedBox(height: 8),
          Text(
            l10n.uatChecklistHint,
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
