/// App-wide constants for the Construction Field App.
library;

/// Collection names mirrored in Firestore (Phase 1+).
abstract final class FirestoreCollections {
  static const organizations = 'organizations';
  static const projects = 'projects';
  static const memberships = 'memberships';
  static const issues = 'issues';
  static const rfis = 'rfis';
  static const comments = 'comments';
  static const folders = 'folders';
  static const documents = 'documents';
  static const drawingPins = 'drawing_pins';
  static const dprs = 'dprs';
  static const safetyRecords = 'safety_records';
  static const inspections = 'inspections';
  static const attendanceLogs = 'attendance_logs';
  static const materialLogs = 'material_logs';
  static const syncEvents = 'sync_events';
}

/// RBAC roles from the RAYNS brief.
enum AppRole {
  siteEngineer,
  projectManager,
  qaQc,
  client,
  admin,
}

extension AppRoleX on AppRole {
  String get firestoreValue => switch (this) {
        AppRole.siteEngineer => 'site_engineer',
        AppRole.projectManager => 'project_manager',
        AppRole.qaQc => 'qa_qc',
        AppRole.client => 'client',
        AppRole.admin => 'admin',
      };
}
