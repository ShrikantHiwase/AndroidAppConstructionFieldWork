/// Field evidence photo limits for low-end Android + Storage cost control.
abstract final class EvidenceImagePolicy {
  /// Longest edge after resize (matches image_picker maxWidth).
  static const int maxWidthPx = 1600;

  /// Initial JPEG quality (0–100).
  static const int jpegQuality = 70;

  /// Soft target size; compressor may lower quality until under this.
  static const int targetMaxBytes = 400 * 1024;

  /// Floor quality while trying to meet [targetMaxBytes].
  static const int minJpegQuality = 40;

  /// Synthetic size for Fake / demo `local://` paths (~150 KB).
  static const int demoByteSize = 150 * 1024;

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}
