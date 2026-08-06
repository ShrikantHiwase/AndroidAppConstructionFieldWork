import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import '../../../core/device/evidence_capture.dart';
import '../../../core/device/evidence_image_policy.dart';
import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../voice_notes/domain/voice_note_models.dart';
import '../../voice_notes/presentation/voice_notes_section.dart';
import '../domain/dpr_models.dart';
import 'dpr_providers.dart';

class DprHomePage extends ConsumerWidget {
  const DprHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dprs = ref.watch(dprsProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canEditDpr(session.activeRole);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Progress')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TodaysDprPage(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text("Today's DPR"),
            )
          : null,
      body: dprs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No DPRs yet. Capture today\'s progress in ~3 minutes.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final dpr = list[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                title: Text(
                  dpr.reportDate.toIso8601String().split('T').first,
                ),
                subtitle: Text(
                  '${dpr.submitted ? 'Submitted' : 'Draft'} · '
                  '${dpr.activities.length} activities'
                  '${dpr.synced ? '' : ' · pending sync'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DprDetailPage(dprId: dpr.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TodaysDprPage extends ConsumerStatefulWidget {
  const TodaysDprPage({super.key});

  @override
  ConsumerState<TodaysDprPage> createState() => _TodaysDprPageState();
}

class _TodaysDprPageState extends ConsumerState<TodaysDprPage> {
  final _weather = TextEditingController(text: 'Clear, 32°C');
  final _manpower = TextEditingController(text: '42 total · 18 civil · 12 MEP');
  final _blockers = TextEditingController();
  final _activity = TextEditingController();
  final _activities = <DprActivity>[];
  var _saving = false;
  String? _error;
  DailyProgressReport? _existing;
  String? _pendingPhotoPath;
  int? _pendingPhotoBytes;
  String? _pendingPhotoLabel;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadExisting);
  }

  Future<void> _loadExisting() async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    final existing = await ref
        .read(dprRepositoryProvider)
        .todayDpr(session.activeProjectId, DateTime.now());
    if (!mounted || existing == null) return;
    setState(() {
      _existing = existing;
      _weather.text = existing.weather;
      _manpower.text = existing.manpowerSummary;
      _blockers.text = existing.blockers;
      _activities
        ..clear()
        ..addAll(existing.activities);
    });
  }

  @override
  void dispose() {
    _weather.dispose();
    _manpower.dispose();
    _blockers.dispose();
    _activity.dispose();
    super.dispose();
  }

  Future<void> _save({required bool submit}) async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var dpr = await ref.read(dprRepositoryProvider).createOrUpdateToday(
            session: session,
            input: CreateDprInput(
              weather: _weather.text,
              manpowerSummary: _manpower.text,
              activities: List.of(_activities),
              blockers: _blockers.text,
            ),
          );
      if (submit) {
        dpr = await ref
            .read(dprRepositoryProvider)
            .submit(session: session, dprId: dpr.id);
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DprDetailPage(dprId: dpr.id),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _existing?.submitted ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text("Today's DPR")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (submitted)
            Text(
              'Already submitted — view only.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          TextField(
            controller: _weather,
            enabled: !submitted,
            decoration: const InputDecoration(
              labelText: 'Weather',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manpower,
            enabled: !submitted,
            decoration: const InputDecoration(
              labelText: 'Manpower summary',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Activities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!submitted) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activity,
                    decoration: const InputDecoration(
                      labelText: 'Activity + optional location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final text = _activity.text.trim();
                    if (text.isEmpty) return;
                    final path = _pendingPhotoPath;
                    final hasPhoto = path != null && path.isNotEmpty;
                    setState(() {
                      _activities.add(
                        DprActivity(
                          id: 'act_${DateTime.now().microsecondsSinceEpoch}',
                          description: text,
                          hasPhoto: hasPhoto,
                          photoLocalPath: hasPhoto ? path : null,
                          photoByteSizeBytes:
                              hasPhoto ? _pendingPhotoBytes : null,
                        ),
                      );
                      _activity.clear();
                      _pendingPhotoPath = null;
                      _pendingPhotoBytes = null;
                      _pendingPhotoLabel = null;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final shot = await ref
                        .read(evidenceCaptureProvider)
                        .capturePhoto(source: EvidencePhotoSource.camera);
                    if (shot == null || !mounted) return;
                    setState(() {
                      _pendingPhotoPath = shot.localPath;
                      _pendingPhotoBytes = shot.byteSizeBytes;
                      _pendingPhotoLabel = shot.fileName;
                    });
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Activity photo'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final shot = await ref
                        .read(evidenceCaptureProvider)
                        .capturePhoto(source: EvidencePhotoSource.gallery);
                    if (shot == null || !mounted) return;
                    setState(() {
                      _pendingPhotoPath = shot.localPath;
                      _pendingPhotoBytes = shot.byteSizeBytes;
                      _pendingPhotoLabel = shot.fileName;
                    });
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
                if (_pendingPhotoPath != null)
                  Text(
                    '${_pendingPhotoLabel ?? 'photo'} · '
                    '${EvidenceImagePolicy.formatBytes(_pendingPhotoBytes ?? 0)}'
                    ' (attaches to next activity)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
          ..._activities.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                a.hasPhoto
                    ? Icons.photo_outlined
                    : Icons.check_circle_outline,
              ),
              title: Text(a.description),
              subtitle: Text(
                a.hasPhoto
                    ? (a.pendingPhotoUpload
                        ? 'Evidence photo · queued upload'
                        : a.photoRemoteUrl != null
                            ? 'Evidence photo · synced'
                            : 'Evidence photo attached'
                                '${a.photoByteSizeBytes == null ? '' : ' · ${EvidenceImagePolicy.formatBytes(a.photoByteSizeBytes!)}'}')
                    : 'No evidence photo',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _blockers,
            enabled: !submitted,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Blockers',
              border: OutlineInputBorder(),
            ),
          ),
          if (_existing != null) ...[
            const SizedBox(height: 20),
            VoiceNotesSection(
              parentType: VoiceParentType.dpr,
              parentId: _existing!.id,
              canAdd: !submitted,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Save a draft once to attach voice notes to today\'s DPR.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (!submitted) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(submit: false),
              child: const Text('Save draft'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _saving ? null : () => _save(submit: true),
              child: const Text('Submit DPR'),
            ),
          ],
        ],
      ),
    );
  }
}

class DprDetailPage extends ConsumerWidget {
  const DprDetailPage({super.key, required this.dprId});

  final String dprId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final list = ref.watch(dprsProvider).valueOrNull ?? const <DailyProgressReport>[];
    DailyProgressReport? dpr;
    for (final item in list) {
      if (item.id == dprId) {
        dpr = item;
        break;
      }
    }
    if (dpr == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('DPR')),
        body: const Center(child: Text('DPR not found')),
      );
    }
    final current = dpr;
    final projectName = session.activeProject.name;
    final dateLabel = current.reportDate.toIso8601String().split('T').first;
    final shareText = current.toShareText(projectName: projectName);
    final subject = 'DPR $dateLabel — $projectName';

    Future<void> sharePdf() async {
      final bytes = await FieldPdfExport.dpr(
        report: current,
        projectName: projectName,
      );
      final outcome = await ref.read(sharePortProvider).shareFile(
            bytes: bytes,
            filename: 'dpr_$dateLabel.pdf',
            subject: subject,
            text: subject,
            fallbackText: shareText,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shareSnackMessage(outcome, kind: 'DPR PDF')),
          ),
        );
      }
    }

    Future<void> shareAsText() async {
      final outcome = await ref.read(sharePortProvider).shareText(
            text: shareText,
            subject: subject,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shareSnackMessage(outcome, kind: 'DPR summary'),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dateLabel),
        actions: [
          IconButton(
            tooltip: 'Share PDF',
            onPressed: sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Share text summary',
            onPressed: shareAsText,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            current.submitted ? 'Submitted' : 'Draft',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Weather: ${current.weather}'),
          Text('Manpower: ${current.manpowerSummary}'),
          const SizedBox(height: 16),
          Text('Activities', style: Theme.of(context).textTheme.titleMedium),
          ...current.activities.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a.description),
              subtitle: Text(
                a.hasPhoto
                    ? (a.pendingPhotoUpload
                        ? 'Evidence photo · queued upload'
                        : '${a.photoCount} photo evidence')
                    : 'No photo evidence',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Blockers: ${current.blockers.isEmpty ? 'None' : current.blockers}',
          ),
          const SizedBox(height: 20),
          VoiceNotesSection(
            parentType: VoiceParentType.dpr,
            parentId: current.id,
            canAdd: !current.submitted && canEditDpr(session.activeRole),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Share PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: shareAsText,
            icon: const Icon(Icons.ios_share),
            label: const Text('Share as text'),
          ),
          const SizedBox(height: 16),
          Text('Text preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(shareText),
          const SizedBox(height: 8),
          Text(
            'PDF and text open the system share sheet (WhatsApp, email, etc.).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
