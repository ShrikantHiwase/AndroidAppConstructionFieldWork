import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/admin_invite_models.dart';
import 'admin_invites_providers.dart';
import '../../../core/errors/localize_app_error.dart';

class AdminInvitesPage extends ConsumerStatefulWidget {
  const AdminInvitesPage({super.key});

  @override
  ConsumerState<AdminInvitesPage> createState() => _AdminInvitesPageState();
}

class _AdminInvitesPageState extends ConsumerState<AdminInvitesPage> {
  final _email = TextEditingController();
  AppRole _role = AppRole.siteEngineer;
  final _selectedProjects = <String>{};
  var _projectsSeeded = false;
  var _saving = false;
  String? _error;

  static const _inviteableRoles = [
    AppRole.siteEngineer,
    AppRole.projectManager,
    AppRole.qaQc,
    AppRole.client,
  ];

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final invite = await ref.read(adminInvitesRepositoryProvider).createInvite(
            session: session,
            email: _email.text,
            role: _role,
            projectIds: _selectedProjects.toList(),
          );
      if (mounted) {
        _email.clear();
        final firebase = ref.read(firebaseEnabledProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firebase
                  ? l10n.inviteCreatedFirebase(invite.email)
                  : l10n.inviteCreatedDemo(invite.email),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = localizeAppError(e, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    final invitesAsync = ref.watch(adminInvitesProvider);

    if (session == null || !RolePermissions.canManageUsers(session.activeRole)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.invitesTitle)),
        body: Center(child: Text(l10n.adminOnly)),
      );
    }

    if (!_projectsSeeded) {
      _projectsSeeded = true;
      _selectedProjects.add(session.activeProjectId);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteUsersTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.createInvite,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            ref.watch(firebaseEnabledProvider)
                ? l10n.firebaseInviteHint
                : l10n.demoInviteHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.roleSectionLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _inviteableRoles
                .map(
                  (r) => ChoiceChip(
                    label: Text(roleLabel(r, l10n)),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.projectsSectionLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ...session.projects.map(
            (p) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _selectedProjects.contains(p.id),
              title: Text(
                p.siteName == null ? p.name : '${p.name} · ${p.siteName}',
              ),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedProjects.add(p.id);
                  } else {
                    _selectedProjects.remove(p.id);
                  }
                });
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _create,
            child: Text(l10n.sendInvite),
          ),
          const SizedBox(height: 28),
          Text(l10n.invitesSection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          invitesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(localizeAppError(e, l10n)),
            data: (invites) {
              if (invites.isEmpty) {
                return Text(l10n.noInvitesYet);
              }
              return Column(
                children: invites
                    .map(
                      (inv) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(inv.email),
                        subtitle: Text(
                          l10n.inviteListSubtitle(
                            roleLabel(inv.role, l10n),
                            inv.status.name,
                            inv.projectIds.length,
                          ),
                        ),
                        trailing: inv.status == InviteStatus.pending
                            ? IconButton(
                                tooltip: l10n.copySignInHintTooltip,
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: l10n.clipboardInviteHint(inv.email),
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.inviteHintCopied),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy),
                              )
                            : const Icon(Icons.check_circle_outline),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
