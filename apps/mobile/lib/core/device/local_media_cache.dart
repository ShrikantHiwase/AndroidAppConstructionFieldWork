import '../device/evidence_image_policy.dart';

/// One bucket of estimated on-device media retained for the soft cache cap.
class LocalCacheSlice {
  const LocalCacheSlice({
    required this.label,
    required this.estimatedBytes,
    this.reclaimableBytes = 0,
    this.reclaimableItemCount = 0,
    this.itemCount = 0,
  });

  final String label;
  final int estimatedBytes;

  /// Bytes that Cleanup can drop by clearing uploaded `local://` stubs.
  final int reclaimableBytes;

  /// Count of uploaded stubs Cleanup can clear.
  final int reclaimableItemCount;
  final int itemCount;
}

class LocalCacheSnapshot {
  const LocalCacheSnapshot({
    required this.slices,
    required this.capBytes,
  });

  final List<LocalCacheSlice> slices;
  final int capBytes;

  int get estimatedBytes =>
      slices.fold<int>(0, (sum, s) => sum + s.estimatedBytes);

  int get reclaimableBytes =>
      slices.fold<int>(0, (sum, s) => sum + s.reclaimableBytes);

  double get usageRatio =>
      capBytes <= 0 ? 0 : (estimatedBytes / capBytes).clamp(0.0, 2.0);

  String get breakdownLabel => slices
      .where((s) => s.estimatedBytes > 0)
      .map(
        (s) =>
            '${s.label} ${EvidenceImagePolicy.formatBytes(s.estimatedBytes)}',
      )
      .join(' · ');
}

/// Feature stores that contribute soft local media estimates / reclaim.
abstract class LocalMediaCache {
  LocalCacheSlice estimateLocalCache();

  /// Clears `local://` paths that already have a remote/demo URL.
  /// Returns estimated bytes no longer counted toward the soft cap.
  Future<int> reclaimUploadedLocalPaths();
}

/// Shared helpers for soft estimates (demo `local://` stubs have no file I/O).
abstract final class LocalCacheEstimates {
  static bool isDemoPath(String? path) =>
      path != null &&
      (path.startsWith('local://') || path.startsWith('demo://'));

  static bool isReclaimableLocalStub({
    required String? localPath,
    required String? remoteUrl,
  }) {
    if (remoteUrl == null || remoteUrl.isEmpty) return false;
    return localPath != null && localPath.startsWith('local://');
  }

  static int bytesFor({
    required String? localPath,
    int? byteSizeBytes,
  }) {
    if (localPath == null || localPath.isEmpty) return 0;
    if (byteSizeBytes != null && byteSizeBytes > 0) return byteSizeBytes;
    if (isDemoPath(localPath)) return EvidenceImagePolicy.demoByteSize;
    return 0;
  }
}
