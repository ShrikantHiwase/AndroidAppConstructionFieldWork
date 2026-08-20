import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import '../../../core/device/evidence_capture.dart';
import '../../../core/device/evidence_image_policy.dart';
import '../../../core/share/field_pdf_export.dart';
import '../../../core/share/share_port.dart';
import '../../../core/telemetry/telemetry_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../pilot/presentation/pilot_providers.dart';
import '../../voice_notes/domain/voice_note_models.dart';
import '../../voice_notes/presentation/voice_notes_section.dart';
import '../domain/dpr_models.dart';
import 'dpr_providers.dart';
import '../../../core/errors/localize_app_error.dart';

class DprHomePage extends ConsumerWidget {
  const DprHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dprs = ref.watch(dprsProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canEditDpr(session.activeRole);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dailyProgress)),
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
              label: Text(l10n.todaysDpr),
            )
          : null,
      body: dprs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(localizeAppError(e, l10n))),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.noDprsYet));
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
                  '${dpr.submitted ? l10n.submittedLabel : l10n.draftLabel} · '
                  '${l10n.activitiesCount(dpr.activities.length)}'
                  '${dpr.synced ? '' : l10n.pendingSyncPart}',
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
  final _openedAt = Stopwatch()..start();
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
        final elapsedMs = _openedAt.elapsedMilliseconds;
        await ref.read(dprSubmitTimingProvider.notifier).record(
              durationMs: elapsedMs,
              projectId: session.activeProjectId,
            );
        await logTelemetryEvent(
          ref,
          name: 'dpr_submit',
          params: {
            'duration_ms': elapsedMs,
            'project_id': session.activeProjectId,
          },
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DprDetailPage(dprId: dpr.id),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = localizeAppError(e, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submitted = _existing?.submitted ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.todaysDpr)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (submitted)
            Text(
              l10n.alreadySubmittedViewOnly,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          TextField(
            controller: _weather,
            enabled: !submitted,
            decoration: InputDecoration(
              labelText: l10n.weatherLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manpower,
            enabled: !submitted,
            decoration: InputDecoration(
              labelText: l10n.manpowerSummaryLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.activities, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!submitted) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activity,
                    decoration: InputDecoration(
                      labelText: l10n.activityLocationLabel,
                      border: const OutlineInputBorder(),
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
                  label: Text(l10n.activityPhoto),
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
                  label: Text(l10n.gallery),
                ),
                if (_pendingPhotoPath != null)
                  Text(
                    l10n.photoAttachesNext(
                      _pendingPhotoLabel ?? 'photo',
                      EvidenceImagePolicy.formatBytes(_pendingPhotoBytes ?? 0),
                    ),
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
                        ? l10n.evidencePhotoQueued
                        : a.photoRemoteUrl != null
                            ? l10n.evidencePhotoSynced
                            : '${l10n.evidencePhotoAttached}'
                                '${a.photoByteSizeBytes == null ? '' : ' · ${EvidenceImagePolicy.formatBytes(a.photoByteSizeBytes!)}'}')
                    : l10n.noEvidencePhoto,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _blockers,
            enabled: !submitted,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.blockersLabel,
              border: const OutlineInputBorder(),
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
              l10n.saveDraftForVoice,
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
              child: Text(l10n.saveDraft),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _saving ? null : () => _save(submit: true),
              child: Text(l10n.submitDpr),
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
    final l10n = AppLocalizations.of(context);
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
        appBar: AppBar(title: Text(l10n.dprNoun)),
        body: Center(child: Text(l10n.dprNotFound)),
      );
    }
    final current = dpr;
    final projectName = session.activeProject.name;
    final dateLabel = current.reportDate.toIso8601String().split('T').first;
    final shareText = current.toShareText(
      projectName: projectName,
      l10n: l10n,
    );
    final subject = l10n.shareSubjectDpr(dateLabel, projectName);

    Future<void> sharePdf() async {
      final bytes = await FieldPdfExport.dpr(
        report: current,
        projectName: projectName,
        l10n: l10n,
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
            content: Text(
              shareSnackMessage(
                outcome,
                kind: l10n.shareKindDprPdf,
                l10n: l10n,
              ),
            ),
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
              shareSnackMessage(
                outcome,
                kind: l10n.shareKindDprSummary,
                l10n: l10n,
              ),
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
            tooltip: l10n.sharePdfTooltip,
            onPressed: sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: l10n.shareTextTooltip,
            onPressed: shareAsText,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            current.submitted ? l10n.submittedLabel : l10n.draftLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(l10n.weatherValue(current.weather)),
          Text(l10n.manpowerValue(current.manpowerSummary)),
          const SizedBox(height: 16),
          Text(l10n.activities, style: Theme.of(context).textTheme.titleMedium),
          ...current.activities.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a.description),
              subtitle: Text(
                a.hasPhoto
                    ? (a.pendingPhotoUpload
                        ? l10n.evidencePhotoQueued
                        : l10n.photoEvidenceCount(a.photoCount))
                    : l10n.noEvidencePhoto,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.blockersLine(
              current.blockers.isEmpty ? l10n.noneLabel : current.blockers,
            ),
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
            label: Text(l10n.sharePdf),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: shareAsText,
            icon: const Icon(Icons.ios_share),
            label: Text(l10n.shareAsText),
          ),
          const SizedBox(height: 16),
          Text(l10n.textPreview, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(shareText),
          const SizedBox(height: 8),
          Text(
            l10n.shareSheetHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
