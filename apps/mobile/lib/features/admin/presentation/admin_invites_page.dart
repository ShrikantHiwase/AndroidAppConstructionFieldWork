import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/admin_invite_models.dart';
import 'admin_invites_providers.dart';

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
                  ? 'Invite created for ${invite.email}. Temp password: demo1234'
                  : 'Invite created for ${invite.email}. Password: demo1234',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final invitesAsync = ref.watch(adminInvitesProvider);

    if (session == null || !RolePermissions.canManageUsers(session.activeRole)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invites')),
        body: const Center(child: Text('Admin only')),
      );
    }

    if (!_projectsSeeded) {
      _projectsSeeded = true;
      _selectedProjects.add(session.activeProjectId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Invite users')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Create invite',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            ref.watch(firebaseEnabledProvider)
                ? 'Creates a Firebase Auth user + memberships via the '
                    'inviteMember callable (temporary password demo1234 until '
                    'email delivery is wired).'
                : 'Invitees sign in with the email + password demo1234 (local demo). '
                    'When Firebase is on, the same form calls Cloud Functions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Role', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _inviteableRoles
                .map(
                  (r) => ChoiceChip(
                    label: Text(roleLabel(r)),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('Projects', style: Theme.of(context).textTheme.titleSmall),
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
            child: const Text('Send invite'),
          ),
          const SizedBox(height: 28),
          Text('Invites', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          invitesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (invites) {
              if (invites.isEmpty) {
                return const Text('No invites yet.');
              }
              return Column(
                children: invites
                    .map(
                      (inv) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(inv.email),
                        subtitle: Text(
                          '${roleLabel(inv.role)} · ${inv.status.name} · '
                          '${inv.projectIds.length} project(s)',
                        ),
                        trailing: inv.status == InviteStatus.pending
                            ? IconButton(
                                tooltip: 'Copy sign-in hint',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          'Field Evidence invite\nEmail: ${inv.email}\nPassword: demo1234',
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invite hint copied'),
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
