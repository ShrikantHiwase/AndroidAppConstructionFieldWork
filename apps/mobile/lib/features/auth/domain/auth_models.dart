import '../../../core/constants/app_constants.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;
}

class Organization {
  const Organization({required this.id, required this.name});

  final String id;
  final String name;
}

class Project {
  const Project({
    required this.id,
    required this.orgId,
    required this.name,
    this.siteName,
  });

  final String id;
  final String orgId;
  final String name;
  final String? siteName;
}

class Membership {
  const Membership({
    required this.id,
    required this.userId,
    required this.orgId,
    required this.projectId,
    required this.role,
    this.active = true,
  });

  final String id;
  final String userId;
  final String orgId;
  final String projectId;
  final AppRole role;
  final bool active;
}

/// Signed-in session with org/project memberships for RBAC.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.memberships,
    required this.organizations,
    required this.projects,
    required this.activeProjectId,
    this.biometricsEnabled = false,
  });

  final AppUser user;
  final List<Membership> memberships;
  final List<Organization> organizations;
  final List<Project> projects;
  final String activeProjectId;
  final bool biometricsEnabled;

  Project get activeProject =>
      projects.firstWhere((p) => p.id == activeProjectId);

  Membership get activeMembership => memberships.firstWhere(
        (m) => m.projectId == activeProjectId && m.active,
      );

  AppRole get activeRole => activeMembership.role;

  AuthSession copyWith({
    String? activeProjectId,
    bool? biometricsEnabled,
  }) {
    return AuthSession(
      user: user,
      memberships: memberships,
      organizations: organizations,
      projects: projects,
      activeProjectId: activeProjectId ?? this.activeProjectId,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    );
  }
}

/// CRUD permission matrix keyed by role (RAYNS brief).
abstract final class RolePermissions {
  static bool canCreateIssues(AppRole role) => switch (role) {
        AppRole.siteEngineer ||
        AppRole.projectManager ||
        AppRole.qaQc ||
        AppRole.admin =>
          true,
        AppRole.client => false,
      };

  static bool canAssignWork(AppRole role) => switch (role) {
        AppRole.projectManager || AppRole.admin => true,
        _ => false,
      };

  static bool canChangeIssueStatus(AppRole role) => switch (role) {
        AppRole.siteEngineer ||
        AppRole.projectManager ||
        AppRole.qaQc ||
        AppRole.admin =>
          true,
        AppRole.client => false,
      };

  static bool canManageUsers(AppRole role) => role == AppRole.admin;

  static bool canApprove(AppRole role) => switch (role) {
        AppRole.projectManager || AppRole.admin => true,
        _ => false,
      };

  static bool isReadOnly(AppRole role) => role == AppRole.client;
}
