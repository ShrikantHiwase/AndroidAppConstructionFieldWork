import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import '../../../core/constants/app_constants.dart';

/// In-memory demo auth until Firebase Auth + memberships are wired.
///
/// Demo accounts (password for all: `demo1234`):
/// - engineer@demo.rayns / pm@demo.rayns / qa@demo.rayns
/// - client@demo.rayns / admin@demo.rayns
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionEmailKey = 'auth.session_email';
  static const _projectKey = 'auth.active_project';
  static const _biometricsKey = 'auth.biometrics_enabled';
  static const _lockedKey = 'auth.requires_unlock';

  static const demoPassword = 'demo1234';

  AuthSession? _session;

  static final _org = const Organization(id: 'org_demo', name: 'RAYNS Demo Contractors');

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

  AuthSession _buildSession(AppUser user, AppRole role, {String? projectId}) {
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
      biometricsEnabled: _prefs.getBool(_biometricsKey) ?? false,
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final email = _prefs.getString(_sessionEmailKey);
    if (email == null) return null;
    final demo = _demoUsers[email];
    if (demo == null) return null;
    _session = _buildSession(demo.user, demo.role);
    return _session;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final demo = _demoUsers[normalized];
    if (demo == null || password != demoPassword) {
      throw AuthFailure('Invalid email or password. Try a demo account.');
    }
    await _prefs.setString(_sessionEmailKey, normalized);
    await _prefs.setBool(_lockedKey, false);
    _session = _buildSession(demo.user, demo.role);
    await _prefs.setString(_projectKey, _session!.activeProjectId);
    return _session!;
  }

  @override
  Future<void> signOut() async {
    _session = null;
    await _prefs.remove(_sessionEmailKey);
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
    await _prefs.setBool(_biometricsKey, enabled);
    if (_session != null) {
      _session = _session!.copyWith(biometricsEnabled: enabled);
    }
  }

  /// Demo unlock: succeeds when biometrics are enabled (no device API yet).
  /// Replace with `local_auth` after Firebase wiring.
  @override
  Future<bool> unlockWithBiometrics() async {
    final enabled = _prefs.getBool(_biometricsKey) ?? false;
    if (!enabled) return true;
    await _prefs.setBool(_lockedKey, false);
    return true;
  }

  bool get requiresUnlock =>
      (_prefs.getBool(_biometricsKey) ?? false) &&
      (_prefs.getBool(_lockedKey) ?? false);

  Future<void> markLockedForResume() async {
    if (_prefs.getBool(_biometricsKey) ?? false) {
      await _prefs.setBool(_lockedKey, true);
    }
  }
}
