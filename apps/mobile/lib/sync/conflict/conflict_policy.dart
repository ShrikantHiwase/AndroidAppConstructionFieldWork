/// Default conflict policy for offline-first field records.
enum ConflictStrategy {
  /// Scalar fields (title, assignee, status payload scalars).
  lastWriteWins,

  /// Comments and photo attachments never overwrite — only append.
  appendOnly,

  /// Status transitions recorded in audit history; reject illegal edges.
  auditedStatus,
}

abstract final class ConflictPolicy {
  static ConflictStrategy forCollection(String collection) {
    switch (collection) {
      case 'comments':
        return ConflictStrategy.appendOnly;
      case 'issues':
      case 'rfis':
        return ConflictStrategy.auditedStatus;
      case 'dprs':
      case 'safety_records':
      case 'inspections':
      case 'attendance_logs':
      case 'material_logs':
      case 'folders':
      case 'documents':
      case 'drawing_pins':
        return ConflictStrategy.lastWriteWins;
      default:
        return ConflictStrategy.lastWriteWins;
    }
  }

  static ConflictStrategy forField(String collection, String field) {
    if (field == 'status' || field == 'statusHistory') {
      return ConflictStrategy.auditedStatus;
    }
    if (collection == 'comments' ||
        field == 'attachments' ||
        field == 'photos') {
      return ConflictStrategy.appendOnly;
    }
    return ConflictStrategy.lastWriteWins;
  }

  static String describe(ConflictStrategy strategy) => switch (strategy) {
        ConflictStrategy.lastWriteWins =>
          'Last write wins on scalar fields',
        ConflictStrategy.appendOnly =>
          'Append-only for comments and photos',
        ConflictStrategy.auditedStatus =>
          'Status changes are audited; illegal transitions rejected',
      };
}
