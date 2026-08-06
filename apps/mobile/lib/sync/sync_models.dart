enum SyncLogLevel { info, warn, error }

class SyncLogEntry {
  const SyncLogEntry({
    required this.id,
    required this.at,
    required this.message,
    required this.level,
    this.pendingAfter,
    this.flushedCount,
  });

  final String id;
  final DateTime at;
  final String message;
  final SyncLogLevel level;
  final int? pendingAfter;
  final int? flushedCount;

  Map<String, Object?> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'message': message,
        'level': level.name,
        'pendingAfter': pendingAfter,
        'flushedCount': flushedCount,
      };

  factory SyncLogEntry.fromJson(Map<String, Object?> json) => SyncLogEntry(
        id: json['id'] as String,
        at: DateTime.parse(json['at'] as String),
        message: json['message'] as String,
        level: SyncLogLevel.values.byName(json['level'] as String? ?? 'info'),
        pendingAfter: json['pendingAfter'] as int?,
        flushedCount: json['flushedCount'] as int?,
      );
}

class SyncCleanupResult {
  const SyncCleanupResult({
    required this.removedLogEntries,
    required this.bytesFreedEstimate,
  });

  final int removedLogEntries;
  final int bytesFreedEstimate;
}

/// Tunables for low-end device hardening.
abstract final class SyncCleanupPolicy {
  /// Keep at most this many sync log rows.
  static const maxLogEntries = 100;

  /// Drop log rows older than this.
  static const logRetention = Duration(days: 14);

  /// Soft cap for estimated local JSON payload retention messaging.
  static const softLocalBytesCap = 8 * 1024 * 1024;
}
