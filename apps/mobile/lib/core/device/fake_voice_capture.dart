import 'voice_audio_policy.dart';
import 'voice_capture.dart';

class FakeVoiceCapture implements VoiceCapture {
  FakeVoiceCapture({int startIndex = 0}) : _index = startIndex;

  int _index;

  @override
  Future<VoiceClip?> record({
    Future<void>? stopSignal,
    Duration maxDuration = VoiceAudioPolicy.maxDuration,
  }) async {
    if (stopSignal != null) {
      await Future.any([
        stopSignal,
        Future<void>.delayed(const Duration(milliseconds: 350)),
      ]);
    }
    _index += 1;
    return VoiceClip(
      localPath: 'local://demo/voice_$_index.m4a',
      fileName: 'voice_demo_$_index.m4a',
      contentType: 'audio/mp4',
      byteSizeBytes: VoiceAudioPolicy.demoByteSize,
      transcriptHint: 'Voice stub: progress update from site',
      duration: const Duration(seconds: 4),
    );
  }
}
