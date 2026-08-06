import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/admin_invite_models.dart';
import '../domain/admin_invites_repository.dart';

class LocalAdminInvitesRepository implements AdminInvitesRepository {
  LocalAdminInvitesRepository(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'admin.invites';

  final _items = <String, AdminInvite>{};
  final _controller = StreamController<List<AdminInvite>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      final invite = AdminInvite.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _items[invite.id] = invite;
    }
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _controller.add(_sorted());
  }

  List<AdminInvite> _sorted() {
    return _items.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _displayNameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return email;
    return local[0].toUpperCase() + local.substring(1);
  }

  String _userIdForEmail(String email) =>
      'u_inv_${email.replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

  InviteAuthGrant _grantFrom(AdminInvite invite) {
    return InviteAuthGrant(
      email: invite.email,
      role: invite.role,
      projectIds: List.of(invite.projectIds),
      orgId: invite.orgId,
      displayName: _displayNameFromEmail(invite.email),
      userId: invite.acceptedUserId ?? _userIdForEmail(invite.email),
    );
  }

  @override
  Stream<List<AdminInvite>> watchInvites() async* {
    yield _sorted();
    yield* _controller.stream;
  }

  @override
  Future<List<AdminInvite>> listInvites({InviteStatus? status}) async {
    final all = _sorted();
    if (status == null) return all;
    return all.where((i) => i.status == status).toList();
  }

  @override
  Future<AdminInvite> createInvite({
    required AuthSession session,
    required String email,
    required AppRole role,
    required List<String> projectIds,
  }) async {
    if (!RolePermissions.canManageUsers(session.activeRole)) {
      throw AdminInvitesException('Only admins can invite users');
    }
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AdminInvitesException('Valid email required');
    }
    if (projectIds.isEmpty) {
      throw AdminInvitesException('Select at least one project');
    }
    final known = session.projects.map((p) => p.id).toSet();
    for (final id in projectIds) {
      if (!known.contains(id)) {
        throw AdminInvitesException('Unknown project: $id');
      }
    }
    final duplicate = _items.values.any(
      (i) =>
          i.email == normalized &&
          i.orgId == session.activeProject.orgId &&
          i.status == InviteStatus.pending,
    );
    if (duplicate) {
      throw AdminInvitesException('Pending invite already exists for $normalized');
    }

    final now = DateTime.now().toUtc();
    final invite = AdminInvite(
      id: 'inv_${now.microsecondsSinceEpoch}_${++_seq}',
      orgId: session.activeProject.orgId,
      email: normalized,
      role: role,
      projectIds: List.of(projectIds),
      status: InviteStatus.pending,
      invitedByUserId: session.user.id,
      invitedByName: session.user.displayName,
      createdAt: now,
    );
    _items[invite.id] = invite;
    await _persist();
    return invite;
  }

  @override
  Future<InviteAuthGrant?> consumePendingInvite(String email) async {
    final normalized = _normalizeEmail(email);
    AdminInvite? pending;
    for (final invite in _items.values) {
      if (invite.email == normalized && invite.status == InviteStatus.pending) {
        pending = invite;
        break;
      }
    }
    if (pending == null) return null;
    final userId = _userIdForEmail(normalized);
    final accepted = pending.copyWith(
      status: InviteStatus.accepted,
      acceptedAt: DateTime.now().toUtc(),
      acceptedUserId: userId,
    );
    _items[accepted.id] = accepted;
    await _persist();
    return _grantFrom(accepted);
  }

  @override
  Future<InviteAuthGrant?> lookupAcceptedInvite(String email) async {
    final normalized = _normalizeEmail(email);
    AdminInvite? match;
    for (final invite in _items.values) {
      if (invite.email == normalized && invite.status == InviteStatus.accepted) {
        match = invite;
        break;
      }
    }
    if (match == null) return null;
    return _grantFrom(match);
  }
}
