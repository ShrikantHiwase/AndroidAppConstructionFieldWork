import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/evidence_capture.dart';
import '../../../core/device/evidence_image_policy.dart';
import '../../../core/device/device_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../issues/domain/issue_models.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../domain/dpr_models.dart';
import 'dpr_providers.dart';

class DrawingsListPage extends ConsumerWidget {
  const DrawingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawings = ref.watch(drawingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Drawings')),
      body: drawings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No drawings seeded yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sheet = list[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                leading: const Icon(Icons.map_outlined),
                title: Text(sheet.title),
                subtitle: Text('${sheet.version} · ${sheet.pageCount} pages'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DrawingPinPage(drawingId: sheet.id),
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

class DrawingPinPage extends ConsumerStatefulWidget {
  const DrawingPinPage({super.key, required this.drawingId});

  final String drawingId;

  @override
  ConsumerState<DrawingPinPage> createState() => _DrawingPinPageState();
}

class _DrawingPinPageState extends ConsumerState<DrawingPinPage> {
  var _page = 1;
  Issue? _selectedIssue;
  var _busy = false;
  String? _photoLocalPath;
  int? _photoByteSizeBytes;
  String? _photoLabel;

  Future<void> _attachPhoto(EvidencePhotoSource source) async {
    final shot =
        await ref.read(evidenceCaptureProvider).capturePhoto(source: source);
    if (shot == null || !mounted) return;
    setState(() {
      _photoLocalPath = shot.localPath;
      _photoByteSizeBytes = shot.byteSizeBytes;
      _photoLabel = shot.fileName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final drawings =
        ref.watch(drawingsProvider).valueOrNull ?? const <DrawingSheet>[];
    DrawingSheet? sheet;
    for (final d in drawings) {
      if (d.id == widget.drawingId) {
        sheet = d;
        break;
      }
    }
    final pins = ref.watch(pinsProvider(widget.drawingId)).valueOrNull ??
        const <DrawingPin>[];
    final issues = ref.watch(issuesProvider).valueOrNull ?? const <Issue>[];
    final session = ref.watch(authSessionProvider);
    final canPin = session != null && canPinDrawings(session.activeRole);

    if (sheet == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Drawing')),
        body: const Center(child: Text('Drawing not found')),
      );
    }
    final current = sheet;
    final pagePins = pins.where((p) => p.page == _page).toList();
    final photoReady =
        _photoLocalPath != null && _photoLocalPath!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.title),
        actions: [
          IconButton(
            onPressed: _page <= 1 ? null : () => setState(() => _page -= 1),
            icon: const Icon(Icons.chevron_left),
          ),
          Center(child: Text('$_page / ${current.pageCount}')),
          IconButton(
            onPressed: _page >= current.pageCount
                ? null
                : () => setState(() => _page += 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: [
          if (canPin) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: DropdownMenu<Issue>(
                expandedInsets: EdgeInsets.zero,
                label: const Text('Link issue'),
                hintText: issues.isEmpty
                    ? 'Create an issue first'
                    : 'Select issue to pin',
                dropdownMenuEntries: issues
                    .map(
                      (i) => DropdownMenuEntry(value: i, label: i.title),
                    )
                    .toList(),
                onSelected: (v) => setState(() => _selectedIssue = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _attachPhoto(EvidencePhotoSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Add photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _attachPhoto(EvidencePhotoSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  if (photoReady)
                    Text(
                      '${_photoLabel ?? 'photo'} · '
                      '${EvidenceImagePolicy.formatBytes(_photoByteSizeBytes ?? 0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'Photo optional',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: !canPin || _selectedIssue == null || _busy
                      ? null
                      : (details) async {
                          final box = context.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local = details.localPosition;
                          final x = (local.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                          final y = (local.dy / constraints.maxHeight)
                              .clamp(0.0, 1.0);
                          setState(() => _busy = true);
                          try {
                            await ref
                                .read(drawingPinsRepositoryProvider)
                                .addPin(
                                  session: session,
                                  input: CreatePinInput(
                                    drawingId: current.id,
                                    page: _page,
                                    x: x,
                                    y: y,
                                    issueId: _selectedIssue!.id,
                                    issueTitle: _selectedIssue!.title,
                                    note: 'Punch on ${current.version}',
                                    photoLocalPath: _photoLocalPath,
                                    photoByteSizeBytes: _photoByteSizeBytes,
                                  ),
                                );
                            if (context.mounted) {
                              final photoNote = photoReady
                                  ? ' + evidence photo'
                                  : '';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pinned "${_selectedIssue!.title}"$photoNote',
                                  ),
                                ),
                              );
                            }
                            if (mounted) {
                              setState(() {
                                _photoLocalPath = null;
                                _photoByteSizeBytes = null;
                                _photoLabel = null;
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '${current.title}\n${current.version}\nPage $_page\n\n'
                              'Tap to drop a punch pin'
                              '${_selectedIssue == null ? ' (select an issue first)' : ''}'
                              '${photoReady ? ' with evidence photo' : ''}.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        for (final pin in pagePins)
                          Positioned(
                            left: pin.x * constraints.maxWidth - 14,
                            top: pin.y * constraints.maxHeight - 14,
                            child: Tooltip(
                              message: pin.hasPhoto
                                  ? '${pin.issueTitle} · photo'
                                  : pin.issueTitle,
                              child: Icon(
                                pin.hasPhoto
                                    ? Icons.add_a_photo
                                    : Icons.location_on,
                                color: const Color(0xFFB3261E),
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${pagePins.length} pin(s) on this page · optional evidence photo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
