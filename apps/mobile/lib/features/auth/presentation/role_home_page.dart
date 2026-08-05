import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/offline_badge.dart';
import '../domain/auth_models.dart';
import 'auth_controller.dart';

class RoleHomePage extends ConsumerWidget {
  const RoleHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: Text('No session')));
    }

    return switch (session.activeRole) {
      AppRole.siteEngineer => _RoleScaffold(
          session: session,
          title: 'Site capture',
          subtitle: 'Log issues with photos and location. Keep DPR ready.',
          actions: const [
            _PrimaryAction(Icons.report_problem_outlined, 'New Issue'),
            _PrimaryAction(Icons.assignment_outlined, "Today's DPR"),
            _PrimaryAction(Icons.push_pin_outlined, 'Pin on Drawing'),
          ],
        ),
      AppRole.projectManager => _RoleScaffold(
          session: session,
          title: 'PM queue',
          subtitle: 'Review open issues/RFIs, assign work, approve status.',
          actions: const [
            _PrimaryAction(Icons.inbox_outlined, 'Open queue'),
            _PrimaryAction(Icons.assignment_turned_in_outlined, 'Approvals'),
            _PrimaryAction(Icons.picture_as_pdf_outlined, 'Weekly PDF'),
          ],
        ),
      AppRole.qaQc => _RoleScaffold(
          session: session,
          title: 'QA / QC',
          subtitle: 'Inspections and quality issues with photo evidence.',
          actions: const [
            _PrimaryAction(Icons.checklist_outlined, 'Inspections'),
            _PrimaryAction(Icons.report_problem_outlined, 'Quality issues'),
            _PrimaryAction(Icons.comment_outlined, 'Comments'),
          ],
        ),
      AppRole.client => _RoleScaffold(
          session: session,
          title: 'Client view',
          subtitle: 'Read-only progress and project documents.',
          actions: const [
            _PrimaryAction(Icons.timeline_outlined, 'Progress'),
            _PrimaryAction(Icons.folder_open_outlined, 'Documents'),
          ],
          readOnly: true,
        ),
      AppRole.admin => _RoleScaffold(
          session: session,
          title: 'Admin',
          subtitle: 'Invite users, assign roles and projects, org settings.',
          actions: const [
            _PrimaryAction(Icons.person_add_outlined, 'Invite user'),
            _PrimaryAction(Icons.manage_accounts_outlined, 'Roles'),
            _PrimaryAction(Icons.settings_outlined, 'Org settings'),
          ],
        ),
    };
  }
}

class _PrimaryAction {
  const _PrimaryAction(this.icon, this.label);
  final IconData icon;
  final String label;
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
    final offline = ref.watch(isOfflineProvider);
    final role = session.activeRole;
    final perms = <String>[
      if (RolePermissions.canCreateIssues(role)) 'Create issues',
      if (RolePermissions.canAssignWork(role)) 'Assign work',
      if (RolePermissions.canChangeIssueStatus(role)) 'Change status',
      if (RolePermissions.canApprove(role)) 'Approve',
      if (RolePermissions.canManageUsers(role)) 'Manage users',
      if (RolePermissions.isReadOnly(role)) 'Read-only',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: OfflineBadge(isOffline: offline)),
          ),
          IconButton(
            tooltip: 'Sign out',
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
              'Client accounts cannot create or edit field records.',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          Text('Permissions', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: perms
                .map((p) => Chip(label: Text(p), visualDensity: VisualDensity.compact))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('Primary actions', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (a) => FilledButton.tonalIcon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${a.label} — lands in next MVP modules',
                          ),
                        ),
                      );
                    },
                    icon: Icon(a.icon),
                    label: Text(a.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Biometric unlock'),
            subtitle: const Text(
              'Require unlock after app resume (demo stub until local_auth)',
            ),
            value: session.biometricsEnabled,
            onChanged: (v) => ref
                .read(authControllerProvider.notifier)
                .setBiometricsEnabled(v),
          ),
          if (session.biometricsEnabled)
            OutlinedButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).lockForResume(),
              child: const Text('Simulate app resume lock'),
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

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Active project',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
