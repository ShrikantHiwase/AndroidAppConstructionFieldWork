import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/admin_invite_models.dart';
import '../domain/admin_invites_repository.dart';
import '../../../core/errors/app_error_codes.dart';

/// Injectable callable for tests (avoids live Cloud Functions).
typedef InviteMemberCaller = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> data,
);

/// Calls Cloud Function `inviteMember` and lists `invites` from Firestore.
///
/// Demo mode continues to use [LocalAdminInvitesRepository]; this path is only
/// selected when `firebaseEnabledProvider` is true.
class FirebaseAdminInvitesRepository implements AdminInvitesRepository {
  FirebaseAdminInvitesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    InviteMemberCaller? inviteMember,
  })  : _firestoreOverride = firestore,
        _authOverride = auth,
        _functionsOverride = functions,
        _inviteMemberOverride = inviteMember;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
  final FirebaseFunctions? _functionsOverride;
  final InviteMemberCaller? _inviteMemberOverride;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  Future<Map<String, dynamic>> _callInviteMember(
    Map<String, dynamic> data,
  ) async {
    if (_inviteMemberOverride != null) {
      return _inviteMemberOverride(data);
    }
    final functions = _functionsOverride ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable('inviteMember').call(data);
    final raw = result.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  AdminInvite _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, Object?>.from(doc.data() ?? {});
    data['id'] = data['id'] ?? doc.id;
    data['invitedByName'] = data['invitedByName'] ?? '';
    data['createdAt'] =
        data['createdAt'] ?? DateTime.now().toUtc().toIso8601String();
    return AdminInvite.fromJson(data);
  }

  @override
  Stream<List<AdminInvite>> watchInvites() {
    // Unit tests inject only the callable — no Firebase Auth/Firestore.
    if (_firestoreOverride == null && _inviteMemberOverride != null) {
      return Stream.value(const []);
    }
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }
    return _db
        .collection(FirestoreCollections.invites)
        .where('invitedByUserId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<AdminInvite>> listInvites({InviteStatus? status}) async {
    if (_firestoreOverride == null && _inviteMemberOverride != null) {
      return const [];
    }
    final user = _auth.currentUser;
    if (user == null) return const [];
    final snap = await _db
        .collection(FirestoreCollections.invites)
        .where('invitedByUserId', isEqualTo: user.uid)
        .get();
    var list = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (status != null) {
      list = list.where((i) => i.status == status).toList();
    }
    return list;
  }

  @override
  Future<AdminInvite> createInvite({
    required AuthSession session,
    required String email,
    required AppRole role,
    required List<String> projectIds,
  }) async {
    if (!RolePermissions.canManageUsers(session.activeRole)) {
      throw AdminInvitesException(AppErrorCodes.onlyAdminsInvite);
    }
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AdminInvitesException(AppErrorCodes.emailRequired);
    }
    if (projectIds.isEmpty) {
      throw AdminInvitesException(AppErrorCodes.selectProject);
    }
    final known = session.projects.map((p) => p.id).toSet();
    for (final id in projectIds) {
      if (!known.contains(id)) {
        throw AdminInvitesException(AppErrorCodes.unknownProject, arg1: id);
      }
    }

    try {
      final data = await _callInviteMember({
        'email': normalized,
        'displayName': normalized.split('@').first,
        'role': role.firestoreValue,
        'orgId': session.activeProject.orgId,
        'projectIds': projectIds,
        'temporaryPassword': 'demo1234',
        'invitedByName': session.user.displayName,
      });

      final inviteId = data['inviteId']?.toString();
      if (inviteId == null || inviteId.isEmpty) {
        throw AdminInvitesException(AppErrorCodes.inviteMissingId);
      }

      if (_firestoreOverride != null || _inviteMemberOverride == null) {
        try {
          final doc = await _db
              .collection(FirestoreCollections.invites)
              .doc(inviteId)
              .get();
          if (doc.exists) {
            return _fromDoc(doc);
          }
        } catch (_) {
          // Emulators / race: synthesize from callable response.
        }
      }

      final now = DateTime.now().toUtc();
      return AdminInvite(
        id: inviteId,
        orgId: session.activeProject.orgId,
        email: data['email']?.toString() ?? normalized,
        role: role,
        projectIds: List.of(projectIds),
        status: InviteStatus.accepted,
        invitedByUserId: session.user.id,
        invitedByName: session.user.displayName,
        createdAt: now,
        acceptedAt: now,
        acceptedUserId: data['uid']?.toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AdminInvitesException(
        AppErrorCodes.remoteFailure,
        arg1: e.message ?? e.code,
      );
    } on AdminInvitesException {
      rethrow;
    } catch (e) {
      throw AdminInvitesException(
        AppErrorCodes.remoteFailure,
        arg1: e.toString(),
      );
    }
  }

  /// Firebase Auth users are created by the callable; FakeAuth bridge unused.
  @override
  Future<InviteAuthGrant?> consumePendingInvite(String email) async => null;

  @override
  Future<InviteAuthGrant?> lookupAcceptedInvite(String email) async => null;
}
