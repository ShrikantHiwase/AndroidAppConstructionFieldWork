import '../../../core/constants/app_constants.dart';

enum InviteStatus { pending, accepted }

extension InviteStatusX on InviteStatus {
  String get firestoreValue => name;

  static InviteStatus fromFirestore(String value) => switch (value) {
        'accepted' => InviteStatus.accepted,
        _ => InviteStatus.pending,
      };
}

class AdminInvite {
  const AdminInvite({
    required this.id,
    required this.orgId,
    required this.email,
    required this.role,
    required this.projectIds,
    required this.status,
    required this.invitedByUserId,
    required this.invitedByName,
    required this.createdAt,
    this.acceptedAt,
    this.acceptedUserId,
  });

  final String id;
  final String orgId;
  final String email;
  final AppRole role;
  final List<String> projectIds;
  final InviteStatus status;
  final String invitedByUserId;
  final String invitedByName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? acceptedUserId;

  AdminInvite copyWith({
    InviteStatus? status,
    DateTime? acceptedAt,
    String? acceptedUserId,
  }) {
    return AdminInvite(
      id: id,
      orgId: orgId,
      email: email,
      role: role,
      projectIds: projectIds,
      status: status ?? this.status,
      invitedByUserId: invitedByUserId,
      invitedByName: invitedByName,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedUserId: acceptedUserId ?? this.acceptedUserId,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orgId': orgId,
        'email': email,
        'role': role.firestoreValue,
        'projectIds': projectIds,
        'status': status.firestoreValue,
        'invitedByUserId': invitedByUserId,
        'invitedByName': invitedByName,
        'createdAt': createdAt.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'acceptedUserId': acceptedUserId,
      };

  factory AdminInvite.fromJson(Map<String, Object?> json) {
    AppRole role = AppRole.siteEngineer;
    final rawRole = json['role'] as String? ?? 'site_engineer';
    for (final r in AppRole.values) {
      if (r.firestoreValue == rawRole) {
        role = r;
        break;
      }
    }
    return AdminInvite(
      id: json['id'] as String,
      orgId: json['orgId'] as String,
      email: json['email'] as String,
      role: role,
      projectIds: (json['projectIds'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: InviteStatusX.fromFirestore(json['status'] as String? ?? 'pending'),
      invitedByUserId: json['invitedByUserId'] as String,
      invitedByName: json['invitedByName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] == null
          ? null
          : DateTime.parse(json['acceptedAt'] as String),
      acceptedUserId: json['acceptedUserId'] as String?,
    );
  }
}

class AdminInvitesException implements Exception {
  AdminInvitesException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Grant FakeAuth can turn into a session (invite-scoped memberships).
class InviteAuthGrant {
  const InviteAuthGrant({
    required this.email,
    required this.role,
    required this.projectIds,
    required this.orgId,
    required this.displayName,
    required this.userId,
  });

  final String email;
  final AppRole role;
  final List<String> projectIds;
  final String orgId;
  final String displayName;
  final String userId;
}

abstract class InviteAuthBridge {
  Future<InviteAuthGrant?> consumePendingInvite(String email);
  Future<InviteAuthGrant?> lookupAcceptedInvite(String email);
}

String roleLabel(AppRole role) => switch (role) {
      AppRole.siteEngineer => 'Site Engineer',
      AppRole.projectManager => 'Project Manager',
      AppRole.qaQc => 'QA/QC',
      AppRole.client => 'Client',
      AppRole.admin => 'Admin',
    };
