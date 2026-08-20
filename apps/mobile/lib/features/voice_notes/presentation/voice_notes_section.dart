import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import '../../../core/device/voice_audio_policy.dart';
import '../../../core/device/voice_capture.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/voice_note_models.dart';
import 'voice_notes_providers.dart';
import '../../../core/errors/localize_app_error.dart';

/// Lists voice notes for a parent and offers capture (Fake or live mic).
class VoiceNotesSection extends ConsumerWidget {
  const VoiceNotesSection({
    super.key,
    required this.parentType,
    required this.parentId,
    this.canAdd = true,
  });

  final VoiceParentType parentType;
  final String parentId;
  final bool canAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notesAsync = ref.watch(
      voiceNotesForParentProvider((type: parentType, id: parentId)),
    );
    final session = ref.watch(authSessionProvider);
    final offline = ref.watch(isOfflineProvider);
    final native = ref.watch(usingNativeSensorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.voiceNotesTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          native ? l10n.voiceNotesHintNative : l10n.voiceNotesHintDemo,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(localizeAppError(e, l10n)),
          data: (notes) {
            if (notes.isEmpty) {
              return Text(
                l10n.noVoiceNotesYet,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: notes
                  .map(
                    (n) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        n.transcriptPending
                            ? Icons.hourglass_top_outlined
                            : Icons.mic_none_outlined,
                      ),
                      title: Text(n.transcript),
                      subtitle: Text(
                        '${n.createdByName}'
                        '${n.transcriptPending ? l10n.transcriptPendingPart : ''}'
                        '${n.synced ? l10n.syncedPart : l10n.pendingSyncPart}'
                        '${n.remoteAudioUrl == null ? '' : l10n.audioReadyPart}'
                        '${n.audioByteSizeBytes == null ? '' : ' · ${VoiceAudioPolicy.formatBytes(n.audioByteSizeBytes!)}'}',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        if (canAdd)
          _AddVoiceButton(
            session: session,
            offline: offline,
            parentType: parentType,
            parentId: parentId,
            native: native,
          ),
      ],
    );
  }
}

class _AddVoiceButton extends ConsumerWidget {
  const _AddVoiceButton({
    required this.session,
    required this.offline,
    required this.parentType,
    required this.parentId,
    required this.native,
  });

  final AuthSession? session;
  final bool offline;
  final VoiceParentType parentType;
  final String parentId;
  final bool native;

  Future<VoiceClip?> _capture(BuildContext context, WidgetRef ref) async {
    final capture = ref.read(voiceCaptureProvider);
    if (!native) {
      return capture.record();
    }

    final stop = Completer<void>();
    final clipFuture = capture.record(
      stopSignal: stop.future,
      maxDuration: VoiceAudioPolicy.maxDuration,
    );
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final dialogL10n = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(dialogL10n.recordingVoiceNoteTitle),
            content: Text(dialogL10n.recordingVoiceNoteBody),
            actions: [
              TextButton(
                onPressed: () {
                  if (!stop.isCompleted) stop.complete();
                  Navigator.of(ctx).pop();
                },
                child: Text(dialogL10n.stopAction),
              ),
            ],
          );
        },
      );
    }
    if (!stop.isCompleted) stop.complete();
    return clipFuture;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = session;
    if (active == null || !canAddVoiceNotes(active.activeRole)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            final clip = await _capture(context, ref);
            if (clip == null) return;
            final transcript = clip.transcriptHint == null
                ? null
                : '${clip.transcriptHint} (${active.user.displayName})';
            await ref.read(voiceNotesRepositoryProvider).addVoiceNote(
                  session: active,
                  parentType: parentType,
                  parentId: parentId,
                  audioLocalPath: clip.localPath,
                  fileName: clip.fileName,
                  audioByteSizeBytes: clip.byteSizeBytes,
                  transcript: transcript,
                  offline: offline,
                );
            if (!offline) {
              await ref.read(syncEngineProvider).flushNow(
                    isOnline: true,
                    projectId: active.activeProjectId,
                  );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizeAppError(e, l10n))),
              );
            }
          }
        },
        icon: const Icon(Icons.mic_outlined),
        label: Text(
          offline
              ? (native ? l10n.recordVoiceOffline : l10n.addDemoVoiceOffline)
              : (native ? l10n.recordVoiceNote : l10n.addDemoVoiceNote),
        ),
      ),
    );
  }
}
