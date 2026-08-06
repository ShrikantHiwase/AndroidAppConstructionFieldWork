import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/voice_note_models.dart';
import 'voice_notes_providers.dart';

/// Lists voice notes for a parent and offers a demo capture button.
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
    final notesAsync = ref.watch(
      voiceNotesForParentProvider((type: parentType, id: parentId)),
    );
    final session = ref.watch(authSessionProvider);
    final offline = ref.watch(isOfflineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Voice notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Demo capture stores audio path + transcript. Real mic arrives with device plugins.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (notes) {
            if (notes.isEmpty) {
              return Text(
                'No voice notes yet.',
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
                        '${n.transcriptPending ? ' · transcript pending' : ''}'
                        '${n.audioLocalPath == null ? '' : ' · ${n.audioLocalPath}'}',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        if (canAdd) _AddVoiceButton(
          session: session,
          offline: offline,
          parentType: parentType,
          parentId: parentId,
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
  });

  final AuthSession? session;
  final bool offline;
  final VoiceParentType parentType;
  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = session;
    if (active == null || !canAddVoiceNotes(active.activeRole)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            await ref.read(voiceNotesRepositoryProvider).addDemoVoiceNote(
                  session: active,
                  parentType: parentType,
                  parentId: parentId,
                  offline: offline,
                );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')),
              );
            }
          }
        },
        icon: const Icon(Icons.mic_outlined),
        label: Text(
          offline ? 'Add demo voice (offline)' : 'Add demo voice note',
        ),
      ),
    );
  }
}
