/// Soft targets for document upload stubs (demo has no real file I/O).
abstract final class DocumentFilePolicy {
  static const int demoTxtBytes = 512;
  static const int demoCsvBytes = 320;
  static const int demoPdfBytes = 12 * 1024;

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}
