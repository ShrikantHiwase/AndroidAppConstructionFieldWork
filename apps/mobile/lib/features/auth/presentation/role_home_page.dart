import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_locale_provider.dart';
import '../../../core/notifications/notification_deep_link.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/telemetry/telemetry_providers.dart';
import '../../../core/widgets/offline_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/admin_invites_page.dart';
import '../../client_progress/presentation/weekly_progress_page.dart';
import '../../digests/presentation/digests_page.dart';
import '../../documents/presentation/documents_browser_page.dart';
import '../../dpr/presentation/dpr_pages.dart';
import '../../dpr/presentation/drawing_pin_pages.dart';
import '../../issues/presentation/create_issue_page.dart';
import '../../issues/presentation/issues_list_page.dart';
import '../../pilot/presentation/pilot_hub_page.dart';
import '../../site_ops/presentation/site_ops_hub_page.dart';
import '../../sync/presentation/sync_status_page.dart';
import '../domain/auth_models.dart';
import 'auth_controller.dart';

class RoleHomePage extends ConsumerStatefulWidget {
  const RoleHomePage({super.key});

  @override
  ConsumerState<RoleHomePage> createState() => _RoleHomePageState();
}

class _RoleHomePageState extends ConsumerState<RoleHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      consumePendingNotificationDeepLink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    // Keep FCM / demo push token registration warm while home is open.
    ref.watch(pushRegistrationProvider);
    // Align telemetry user id with the signed-in session.
    ref.watch(telemetryBootstrapProvider);
    if (session == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(body: Center(child: Text(l10n.noSession)));
    }

    final l10n = AppLocalizations.of(context);

    return switch (session.activeRole) {
      AppRole.siteEngineer => _RoleScaffold(
          session: session,
          title: l10n.roleEngineerTitle,
          subtitle: l10n.roleEngineerSubtitle,
          actions: [
            _PrimaryAction(
              Icons.report_problem_outlined,
              l10n.newIssue,
              onPressed: () => _open(context, const CreateIssuePage()),
            ),
            _PrimaryAction(
              Icons.assignment_outlined,
              l10n.todaysDpr,
              onPressed: () => _open(context, const TodaysDprPage()),
            ),
            _PrimaryAction(
              Icons.push_pin_outlined,
              l10n.pinOnDrawing,
              onPressed: () => _open(context, const DrawingsListPage()),
            ),
            _PrimaryAction(
              Icons.health_and_safety_outlined,
              l10n.siteOps,
              onPressed: () => _open(context, const SiteOpsHubPage()),
            ),
            _PrimaryAction(
              Icons.notifications_active_outlined,
              l10n.reminders,
              onPressed: () => _open(context, const DigestsPage()),
            ),
          ],
        ),
      AppRole.projectManager => _RoleScaffold(
          session: session,
          title: l10n.rolePmTitle,
          subtitle: l10n.rolePmSubtitle,
          actions: [
            _PrimaryAction(
              Icons.inbox_outlined,
              l10n.openQueue,
              onPressed: () => _open(context, const IssuesListPage()),
            ),
            _PrimaryAction(
              Icons.assignment_outlined,
              l10n.dprs,
              onPressed: () => _open(context, const DprHomePage()),
            ),
            _PrimaryAction(
              Icons.notifications_active_outlined,
              l10n.digests,
              onPressed: () => _open(context, const DigestsPage()),
            ),
            _PrimaryAction(
              Icons.calendar_view_week_outlined,
              l10n.weeklyPack,
              onPressed: () => _open(context, const WeeklyProgressPage()),
            ),
            _PrimaryAction(
              Icons.health_and_safety_outlined,
              l10n.siteOps,
              onPressed: () => _open(context, const SiteOpsHubPage()),
            ),
            _PrimaryAction(
              Icons.flag_outlined,
              l10n.pilot,
              onPressed: () => _open(context, const PilotHubPage()),
            ),
          ],
        ),
      AppRole.qaQc => _RoleScaffold(
          session: session,
          title: l10n.roleQaTitle,
          subtitle: l10n.roleQaSubtitle,
          actions: [
            _PrimaryAction(
              Icons.checklist_outlined,
              l10n.inspections,
              onPressed: () =>
                  _open(context, const SiteOpsHubPage(initialTab: 1)),
            ),
            _PrimaryAction(
              Icons.report_problem_outlined,
              l10n.qualityIssues,
              onPressed: () => _open(context, const IssuesListPage()),
            ),
            _PrimaryAction(
              Icons.health_and_safety_outlined,
              l10n.siteOps,
              onPressed: () => _open(context, const SiteOpsHubPage()),
            ),
          ],
        ),
      AppRole.client => _RoleScaffold(
          session: session,
          title: l10n.roleClientTitle,
          subtitle: l10n.roleClientSubtitle,
          actions: [
            _PrimaryAction(
              Icons.calendar_view_week_outlined,
              l10n.weeklyProgress,
              onPressed: () => _open(context, const WeeklyProgressPage()),
            ),
            _PrimaryAction(
              Icons.list_alt_outlined,
              l10n.issues,
              onPressed: () => _open(context, const IssuesListPage()),
            ),
            _PrimaryAction(
              Icons.folder_open_outlined,
              l10n.documents,
              onPressed: () => _open(context, const DocumentsBrowserPage()),
            ),
          ],
          readOnly: true,
        ),
      AppRole.admin => _RoleScaffold(
          session: session,
          title: l10n.roleAdminTitle,
          subtitle: l10n.roleAdminSubtitle,
          actions: [
            _PrimaryAction(
              Icons.folder_open_outlined,
              l10n.documents,
              onPressed: () => _open(context, const DocumentsBrowserPage()),
            ),
            _PrimaryAction(
              Icons.list_alt_outlined,
              l10n.issues,
              onPressed: () => _open(context, const IssuesListPage()),
            ),
            _PrimaryAction(
              Icons.calendar_view_week_outlined,
              l10n.weeklyPack,
              onPressed: () => _open(context, const WeeklyProgressPage()),
            ),
            _PrimaryAction(
              Icons.person_add_outlined,
              l10n.inviteUser,
              onPressed: () => _open(context, const AdminInvitesPage()),
            ),
            _PrimaryAction(
              Icons.notifications_active_outlined,
              l10n.digests,
              onPressed: () => _open(context, const DigestsPage()),
            ),
            _PrimaryAction(
              Icons.flag_outlined,
              l10n.pilot,
              onPressed: () => _open(context, const PilotHubPage()),
            ),
          ],
        ),
    };
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _PrimaryAction {
  const _PrimaryAction(this.icon, this.label, {required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _RoleScaffold extends ConsumerWidget {
  const _RoleScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.readOnly = false,
  });

  final AuthSession session;
  final String title;
  final String subtitle;
  final List<_PrimaryAction> actions;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final offline = ref.watch(isOfflineProvider);
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final role = session.activeRole;
    final perms = <String>[
      if (RolePermissions.canCreateIssues(role)) l10n.permCreateIssues,
      if (RolePermissions.canAssignWork(role)) l10n.permAssignWork,
      if (RolePermissions.canChangeIssueStatus(role)) l10n.permChangeStatus,
      if (RolePermissions.canApprove(role)) l10n.permApprove,
      if (RolePermissions.canManageUsers(role)) l10n.permManageUsers,
      if (RolePermissions.isReadOnly(role)) l10n.permReadOnly,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  l10n.syncPendingCount(pending),
                  style: textTheme.labelLarge,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: OfflineBadge(isOffline: offline)),
          ),
          IconButton(
            tooltip: l10n.languagePickerLabel,
            onPressed: () =>
                ref.read(appLocaleProvider.notifier).cycle(),
            icon: const Icon(Icons.translate_outlined),
          ),
          IconButton(
            tooltip: offline
                ? l10n.tooltipGoOnlineSync
                : l10n.tooltipSimulateOffline,
            onPressed: () => ref.read(isOfflineProvider.notifier).toggle(),
            icon: Icon(offline ? Icons.cloud_off : Icons.cloud_outlined),
          ),
          IconButton(
            tooltip: l10n.tooltipSyncStatus,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SyncStatusPage(),
                ),
              );
            },
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: l10n.signOut,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _ProjectSwitcher(),
          const SizedBox(height: 16),
          Text(session.user.displayName, style: textTheme.titleLarge),
          Text(
            '${session.user.email} · ${role.firestoreValue}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: textTheme.bodyLarge),
          if (readOnly) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clientReadOnlyNote,
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          Text(l10n.permissions, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: perms
                .map(
                  (p) => Chip(
                    label: Text(p),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(l10n.primaryActions, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (a) => FilledButton.tonalIcon(
                    onPressed: a.onPressed,
                    icon: Icon(a.icon),
                    label: Text(a.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.biometricUnlock),
            subtitle: Text(l10n.biometricUnlockSubtitle),
            value: session.biometricsEnabled,
            onChanged: (v) => ref
                .read(authControllerProvider.notifier)
                .setBiometricsEnabled(v),
          ),
          if (session.biometricsEnabled)
            OutlinedButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).lockForResume(),
              child: Text(l10n.simulateAppResumeLock),
            ),
        ],
      ),
    );
  }
}

class _ProjectSwitcher extends ConsumerWidget {
  const _ProjectSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.activeProject,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: session.activeProjectId,
          items: session.projects
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    p.siteName == null ? p.name : '${p.name} · ${p.siteName}',
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) {
              ref.read(authControllerProvider.notifier).switchProject(id);
            }
          },
        ),
      ),
    );
  }
}
