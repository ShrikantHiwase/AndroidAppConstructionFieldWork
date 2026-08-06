import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'fake_voice_capture.dart';
import 'voice_audio_policy.dart';
import 'voice_capture.dart';

/// On-device mic via `record`; falls back to [FakeVoiceCapture] on errors.
class DeviceVoiceCapture implements VoiceCapture {
  DeviceVoiceCapture({VoiceCapture? fallback})
      : _fallback = fallback ?? FakeVoiceCapture();

  final VoiceCapture _fallback;

  @override
  Future<VoiceClip?> record({
    Future<void>? stopSignal,
    Duration maxDuration = VoiceAudioPolicy.maxDuration,
  }) async {
    final recorder = AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        return _fallback.record(stopSignal: stopSignal, maxDuration: maxDuration);
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      await Future.any([
        if (stopSignal != null) stopSignal,
        Future<void>.delayed(maxDuration),
      ]);

      final outPath = await recorder.stop();
      await recorder.dispose();
      if (outPath == null || outPath.isEmpty) return null;

      final file = File(outPath);
      final size = await file.exists() ? await file.length() : null;
      final name = outPath.split('/').last;
      return VoiceClip(
        localPath: outPath,
        fileName: name.isEmpty ? 'voice.m4a' : name,
        contentType: 'audio/mp4',
        byteSizeBytes: size,
      );
    } catch (_) {
      try {
        await recorder.dispose();
      } catch (_) {}
      return _fallback.record(stopSignal: stopSignal, maxDuration: maxDuration);
    }
  }
}
