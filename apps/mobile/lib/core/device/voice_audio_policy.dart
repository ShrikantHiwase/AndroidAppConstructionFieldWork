/// Soft targets for voice-note audio stubs (demo has no real file I/O).
abstract final class VoiceAudioPolicy {
  /// Estimated size for Fake `local://demo/voice_*.m4a` stubs.
  static const int demoByteSize = 80 * 1024;

  /// Cap for a single live capture session.
  static const Duration maxDuration = Duration(seconds: 60);

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}
