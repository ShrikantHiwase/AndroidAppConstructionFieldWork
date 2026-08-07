import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/weekly_progress_models.dart';
import 'weekly_progress_providers.dart';

class WeeklyProgressPage extends ConsumerWidget {
  const WeeklyProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    final packAsync = ref.watch(weeklyProgressProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weeklyProgress)),
        body: Center(child: Text(l10n.signInRequired)),
      );
    }

    if (!canViewWeeklyProgress(session.activeRole)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weeklyProgress)),
        body: Center(
          child: Text(l10n.weeklyProgressRoleGate),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklyProgress)),
      body: packAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (pack) {
          if (pack == null) {
            return Center(child: Text(l10n.progressPackUnavailable));
          }
          final projectName = session.activeProject.name;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                projectName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.isoWeekLabel(pack.weekRangeLabel),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.submittedDprDaysLine(
                  pack.submittedDprDays,
                  pack.openIssueCount,
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              if (pack.isEmptyWeek)
                Text(
                  l10n.emptyWeekShareHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...pack.days.map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.dateLabel,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          l10n.weatherManpowerLine(
                            day.weather,
                            day.manpowerSummary,
                          ),
                        ),
                        for (final a in day.activitySummaries)
                          Text('• $a'),
                        if (day.blockers != null)
                          Text(
                            l10n.blockersLine(day.blockers!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (pack.openIssueTitles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.openIssuesSection,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                ...pack.openIssueTitles.map((t) => Text('• $t')),
              ],
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final text = pack.toShareText(projectName: projectName);
                  final subject = 'Weekly progress — $projectName';
                  final bytes = await FieldPdfExport.weekly(
                    pack: pack,
                    projectName: projectName,
                  );
                  final weekKey =
                      pack.weekStart.toIso8601String().split('T').first;
                  final outcome = await ref.read(sharePortProvider).shareFile(
                        bytes: bytes,
                        filename: 'weekly_progress_$weekKey.pdf',
                        subject: subject,
                        text: subject,
                        fallbackText: text,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          shareSnackMessage(outcome, kind: 'Weekly PDF'),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l10n.shareWeeklyPdf),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final text = pack.toShareText(projectName: projectName);
                  final outcome = await ref.read(sharePortProvider).shareText(
                        text: text,
                        subject: 'Weekly progress — $projectName',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          shareSnackMessage(outcome, kind: 'Weekly progress'),
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
    );
  }
}
