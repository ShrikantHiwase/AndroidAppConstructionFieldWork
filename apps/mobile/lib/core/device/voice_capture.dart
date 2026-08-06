/// Result of a voice capture (Fake stub or on-device file).
class VoiceClip {
  const VoiceClip({
    required this.localPath,
    required this.fileName,
    this.contentType = 'audio/mp4',
    this.byteSizeBytes,
    this.transcriptHint,
    this.duration,
  });

  final String localPath;
  final String fileName;
  final String contentType;
  final int? byteSizeBytes;

  /// Demo/Fake canned transcript; Device leaves null (heuristic on flush).
  final String? transcriptHint;
  final Duration? duration;
}

/// Mic capture for voice notes. Fake is default; Device behind sensors gate.
abstract class VoiceCapture {
  /// Captures one clip.
  ///
  /// Fake returns a `local://` stub immediately (or after a brief wait when
  /// [stopSignal] is provided for UI parity).
  /// Device starts the mic and finishes when [stopSignal] completes or
  /// [maxDuration] elapses; falls back to Fake on permission/plugin errors.
  Future<VoiceClip?> record({
    Future<void>? stopSignal,
    Duration maxDuration = const Duration(seconds: 60),
  });
}
