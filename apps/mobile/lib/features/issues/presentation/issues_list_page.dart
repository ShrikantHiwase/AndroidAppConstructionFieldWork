import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/issue_models.dart';
import 'create_issue_page.dart';
import 'field_records_providers.dart';
import 'issue_detail_page.dart';

class IssuesListPage extends ConsumerWidget {
  const IssuesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final issuesAsync = ref.watch(issuesProvider);
    final session = ref.watch(authSessionProvider);
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final offline = ref.watch(isOfflineProvider);
    final canCreate =
        session != null && RolePermissions.canCreateIssues(session.activeRole);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.issues),
        actions: [
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  offline ? l10n.pendingCount(pending) : l10n.syncingEllipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          IconButton(
            tooltip: offline ? l10n.tooltipGoOnlineSync : l10n.goOffline,
            onPressed: () => ref.read(isOfflineProvider.notifier).toggle(),
            icon: Icon(offline ? Icons.cloud_off : Icons.cloud_done_outlined),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateIssuePage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.newIssue),
            )
          : null,
      body: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(issuesProvider),
        ),
        data: (issues) {
          if (issues.isEmpty) {
            return Center(child: Text(l10n.noIssuesYet));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(issuesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final issue = issues[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  title: Text(
                    issue.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${issue.status.localizedLabel(l10n)}'
                    '${issue.assigneeName == null ? '' : ' · ${issue.assigneeName}'}'
                    '${issue.synced ? '' : l10n.notSyncedSuffix}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: issue.location == null
                      ? null
                      : const Icon(Icons.place_outlined),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => IssueDetailPage(issueId: issue.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
