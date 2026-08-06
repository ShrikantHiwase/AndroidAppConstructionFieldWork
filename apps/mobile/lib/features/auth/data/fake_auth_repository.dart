import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/secure/secure_store.dart';
import '../../admin/domain/admin_invite_models.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// In-memory demo auth until Firebase Auth + memberships are wired.
///
/// Demo accounts (password for all: `demo1234`):
/// - engineer@demo.rayns / pm@demo.rayns / qa@demo.rayns
/// - client@demo.rayns / admin@demo.rayns
///
/// Invited emails (same password) honor pending [InviteAuthBridge] grants.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(
    this._prefs, {
    InviteAuthBridge? invites,
    SecureStore? secure,
  })  : _invites = invites,
        _secure = secure ?? FakeSecureStore(_prefs);

  final SharedPreferences _prefs;
  final InviteAuthBridge? _invites;
  final SecureStore _secure;

  static const _sessionEmailKey = SecureKeys.sessionEmail;
  static const _projectKey = 'auth.active_project';
  static const _biometricsKey = SecureKeys.biometricsEnabled;
  static const _lockedKey = 'auth.requires_unlock';

  static const demoPassword = 'demo1234';

  AuthSession? _session;
  var _biometricsEnabled = false;
  var _secureReady = false;

  Future<void> _ensureSecure() async {
    if (_secureReady) return;
    await _secure.migrateFromPrefs(_prefs);
    _biometricsEnabled =
        (await _secure.read(_biometricsKey)) == 'true';
    _secureReady = true;
  }

  Future<void> _writeBiometrics(bool enabled) async {
    await _ensureSecure();
    _biometricsEnabled = enabled;
    await _secure.write(_biometricsKey, enabled ? 'true' : 'false');
  }

  static final _org =
      const Organization(id: 'org_demo', name: 'RAYNS Demo Contractors');

  static final _projects = [
    const Project(
      id: 'proj_pune_tower',
      orgId: 'org_demo',
      name: 'Pune Tower A',
      siteName: 'Hinjewadi Phase 1',
    ),
    const Project(
      id: 'proj_mumbai_metro',
      orgId: 'org_demo',
      name: 'Mumbai Metro Yard',
      siteName: 'Bandra Kurla',
    ),
  ];

  /// Demo catalog used by admin invite project pickers in tests.
  static List<Project> get demoProjects => List.unmodifiable(_projects);

  static final _demoUsers = <String, ({AppUser user, AppRole role})>{
    'engineer@demo.rayns': (
      user: const AppUser(
        id: 'u_engineer',
        email: 'engineer@demo.rayns',
        displayName: 'Asha Patil',
      ),
      role: AppRole.siteEngineer,
    ),
    'pm@demo.rayns': (
      user: const AppUser(
        id: 'u_pm',
        email: 'pm@demo.rayns',
        displayName: 'Rohit Sharma',
      ),
      role: AppRole.projectManager,
    ),
    'qa@demo.rayns': (
      user: const AppUser(
        id: 'u_qa',
        email: 'qa@demo.rayns',
        displayName: 'Neha Kulkarni',
      ),
      role: AppRole.qaQc,
    ),
    'client@demo.rayns': (
      user: const AppUser(
        id: 'u_client',
        email: 'client@demo.rayns',
        displayName: 'Client Viewer',
      ),
      role: AppRole.client,
    ),
    'admin@demo.rayns': (
      user: const AppUser(
        id: 'u_admin',
        email: 'admin@demo.rayns',
        displayName: 'Site Admin',
      ),
      role: AppRole.admin,
    ),
  };

  AuthSession _buildDemoSession(AppUser user, AppRole role, {String? projectId}) {
    final memberships = _projects
        .map(
          (p) => Membership(
            id: '${user.id}_${p.id}',
            userId: user.id,
            orgId: _org.id,
            projectId: p.id,
            role: role,
          ),
        )
        .toList();
    final active = projectId ??
        _prefs.getString(_projectKey) ??
        _projects.first.id;
    return AuthSession(
      user: user,
      memberships: memberships,
      organizations: [_org],
      projects: _projects,
      activeProjectId: active,
      biometricsEnabled: _biometricsEnabled,
    );
  }

  AuthSession _buildInviteSession(InviteAuthGrant grant, {String? projectId}) {
    final projects = _projects
        .where((p) => grant.projectIds.contains(p.id))
        .toList();
    if (projects.isEmpty) {
      throw AuthFailure('Invite has no matching projects');
    }
    final user = AppUser(
      id: grant.userId,
      email: grant.email,
      displayName: grant.displayName,
    );
    final memberships = projects
        .map(
          (p) => Membership(
            id: '${user.id}_${p.id}',
            userId: user.id,
            orgId: grant.orgId,
            projectId: p.id,
            role: grant.role,
          ),
        )
        .toList();
    final preferred = projectId ?? _prefs.getString(_projectKey);
    final active = projects.any((p) => p.id == preferred)
        ? preferred!
        : projects.first.id;
    return AuthSession(
      user: user,
      memberships: memberships,
      organizations: [_org],
      projects: projects,
      activeProjectId: active,
      biometricsEnabled: _biometricsEnabled,
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    await _ensureSecure();
    final email = await _secure.read(_sessionEmailKey);
    if (email == null) return null;
    final demo = _demoUsers[email];
    if (demo != null) {
      _session = _buildDemoSession(demo.user, demo.role);
      return _session;
    }
    final grant = await _invites?.lookupAcceptedInvite(email);
    if (grant == null) return null;
    _session = _buildInviteSession(grant);
    return _session;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _ensureSecure();
    final normalized = email.trim().toLowerCase();
    if (password != demoPassword) {
      throw AuthFailure('Invalid email or password. Try a demo account.');
    }

    final demo = _demoUsers[normalized];
    if (demo != null) {
      await _secure.write(_sessionEmailKey, normalized);
      await _prefs.setBool(_lockedKey, false);
      _session = _buildDemoSession(demo.user, demo.role);
      await _prefs.setString(_projectKey, _session!.activeProjectId);
      return _session!;
    }

    final grant = await _invites?.consumePendingInvite(normalized) ??
        await _invites?.lookupAcceptedInvite(normalized);
    if (grant == null) {
      throw AuthFailure(
        'Invalid email or password. Use a demo account or accept an admin invite.',
      );
    }

    await _secure.write(_sessionEmailKey, normalized);
    await _prefs.setBool(_lockedKey, false);
    _session = _buildInviteSession(grant);
    await _prefs.setString(_projectKey, _session!.activeProjectId);
    return _session!;
  }

  @override
  Future<void> signOut() async {
    await _ensureSecure();
    _session = null;
    await _secure.delete(_sessionEmailKey);
    await _prefs.remove(_projectKey);
    await _prefs.setBool(_lockedKey, false);
  }

  @override
  Future<AuthSession> switchProject(String projectId) async {
    final current = _session ?? await restoreSession();
    if (current == null) {
      throw AuthFailure('Not signed in');
    }
    if (!current.projects.any((p) => p.id == projectId)) {
      throw AuthFailure('Project not found for this user');
    }
    await _prefs.setString(_projectKey, projectId);
    _session = current.copyWith(activeProjectId: projectId);
    return _session!;
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _writeBiometrics(enabled);
    if (_session != null) {
      _session = _session!.copyWith(biometricsEnabled: enabled);
    }
  }

  /// Demo unlock: succeeds when biometrics are enabled (no device API yet).
  @override
  Future<bool> unlockWithBiometrics() async {
    await _ensureSecure();
    if (!_biometricsEnabled) return true;
    await _prefs.setBool(_lockedKey, false);
    return true;
  }

  bool get requiresUnlock =>
      _biometricsEnabled && (_prefs.getBool(_lockedKey) ?? false);

  Future<void> markLockedForResume() async {
    await _ensureSecure();
    if (_biometricsEnabled) {
      await _prefs.setBool(_lockedKey, true);
    }
  }
}
