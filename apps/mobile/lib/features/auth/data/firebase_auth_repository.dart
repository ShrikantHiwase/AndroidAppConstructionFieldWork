import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// Firebase Auth + memberships-backed session loader.
///
/// Expects Firestore docs:
/// - memberships/{uid}_{projectId} with orgId, projectId, userId, role, active
/// - projects/{projectId} with orgId, name, optional siteName
/// - organizations/{orgId} with name
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required SharedPreferences prefs,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _prefs = prefs,
        _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final SharedPreferences _prefs;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _projectKey = 'auth.active_project';
  static const _biometricsKey = 'auth.biometrics_enabled';
  static const _lockedKey = 'auth.requires_unlock';

  AuthSession? _session;

  AppRole _roleFrom(String raw) {
    for (final role in AppRole.values) {
      if (role.firestoreValue == raw) return role;
    }
    return AppRole.siteEngineer;
  }

  Future<AuthSession> _sessionFor(User user) async {
    final membershipSnap = await _db
        .collection(FirestoreCollections.memberships)
        .where('userId', isEqualTo: user.uid)
        .where('active', isEqualTo: true)
        .get();

    if (membershipSnap.docs.isEmpty) {
      throw AuthFailure('No project memberships for this account.');
    }

    final memberships = <Membership>[];
    final projectIds = <String>{};
    final orgIds = <String>{};

    for (final doc in membershipSnap.docs) {
      final data = doc.data();
      final projectId = data['projectId'] as String;
      final orgId = data['orgId'] as String;
      projectIds.add(projectId);
      orgIds.add(orgId);
      memberships.add(
        Membership(
          id: doc.id,
          userId: user.uid,
          orgId: orgId,
          projectId: projectId,
          role: _roleFrom(data['role'] as String? ?? 'site_engineer'),
          active: data['active'] as bool? ?? true,
        ),
      );
    }

    final projects = <Project>[];
    for (final id in projectIds) {
      final snap = await _db.collection(FirestoreCollections.projects).doc(id).get();
      final data = snap.data();
      if (data == null) continue;
      projects.add(
        Project(
          id: id,
          orgId: data['orgId'] as String,
          name: data['name'] as String? ?? id,
          siteName: data['siteName'] as String?,
        ),
      );
    }

    final organizations = <Organization>[];
    for (final id in orgIds) {
      final snap =
          await _db.collection(FirestoreCollections.organizations).doc(id).get();
      final data = snap.data();
      organizations.add(
        Organization(
          id: id,
          name: data?['name'] as String? ?? id,
        ),
      );
    }

    if (projects.isEmpty) {
      throw AuthFailure('Memberships found but no projects could be loaded.');
    }

    final preferred = _prefs.getString(_projectKey);
    final activeProjectId = projects.any((p) => p.id == preferred)
        ? preferred!
        : projects.first.id;

    return AuthSession(
      user: AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email ?? 'User'),
      ),
      memberships: memberships,
      organizations: organizations,
      projects: projects,
      activeProjectId: activeProjectId,
      biometricsEnabled: _prefs.getBool(_biometricsKey) ?? false,
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    _session = await _sessionFor(user);
    return _session;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw AuthFailure('Sign-in failed');
      await _prefs.setBool(_lockedKey, false);
      _session = await _sessionFor(user);
      await _prefs.setString(_projectKey, _session!.activeProjectId);
      return _session!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? e.code);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _session = null;
    await _prefs.remove(_projectKey);
    await _prefs.setBool(_lockedKey, false);
  }

  @override
  Future<AuthSession> switchProject(String projectId) async {
    final current = _session ?? await restoreSession();
    if (current == null) throw AuthFailure('Not signed in');
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

  @override
  Future<bool> unlockWithBiometrics() async {
    final enabled = _prefs.getBool(_biometricsKey) ?? false;
    if (!enabled) return true;
    await _prefs.setBool(_lockedKey, false);
    return true;
  }
}
