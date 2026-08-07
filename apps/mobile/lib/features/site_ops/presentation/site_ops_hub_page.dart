import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import '../../../core/device/evidence_capture.dart';
import '../../../core/device/evidence_image_policy.dart';
import '../../../core/device/fake_location_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/site_ops_models.dart';
import 'site_ops_providers.dart';

class SiteOpsHubPage extends ConsumerWidget {
  const SiteOpsHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.siteOps),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.tabSafety),
              Tab(text: l10n.tabQaQc),
              Tab(text: l10n.tabLabour),
              Tab(text: l10n.tabMaterials),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SafetyTab(),
            _QaTab(),
            _LabourTab(),
            _MaterialsTab(),
          ],
        ),
      ),
    );
  }
}

class _SafetyTab extends ConsumerWidget {
  const _SafetyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(safetyProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateSafety(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.logSafety),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(child: Text(l10n.noSafetyRecordsYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                shape: _tileShape(context),
                title: Text(r.title),
                subtitle: Text(
                  '${r.kind.name} · ${r.createdByName}'
                  '${r.hasPhoto ? ' · photo' : ''}'
                  '${r.photoByteSizeBytes == null ? '' : ' · ~${EvidenceImagePolicy.formatBytes(r.photoByteSizeBytes!)}'}'
                  '${r.pendingPhotoUpload ? ' · queued upload' : ''}'
                  '${r.photoRemoteUrl == null ? '' : ' · uploaded'}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreateSafety(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final notes = TextEditingController();
    var kind = SafetyKind.toolboxTalk;
    String? photoLocalPath;
    int? photoByteSizeBytes;
    String? photoLabel;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final l10n = AppLocalizations.of(context);
            final needsPhoto = kind != SafetyKind.toolboxTalk;
            return AlertDialog(
              title: Text(l10n.safetyRecord),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu<SafetyKind>(
                      initialSelection: kind,
                      label: Text(l10n.kindLabel),
                      expandedInsets: EdgeInsets.zero,
                      dropdownMenuEntries: SafetyKind.values
                          .map(
                            (k) => DropdownMenuEntry(
                              value: k,
                              label: k.name,
                            ),
                          )
                          .toList(),
                      onSelected: (v) {
                        if (v != null) setLocal(() => kind = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: InputDecoration(
                        labelText: l10n.titleLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.notesLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      needsPhoto
                          ? l10n.photoRequiredObservation
                          : l10n.photoOptionalToolbox,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final shot = await ref
                                .read(evidenceCaptureProvider)
                                .capturePhoto(
                                  source: EvidencePhotoSource.camera,
                                );
                            if (shot == null) return;
                            setLocal(() {
                              photoLocalPath = shot.localPath;
                              photoByteSizeBytes = shot.byteSizeBytes;
                              photoLabel = shot.fileName;
                            });
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l10n.addPhoto),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final shot = await ref
                                .read(evidenceCaptureProvider)
                                .capturePhoto(
                                  source: EvidencePhotoSource.gallery,
                                );
                            if (shot == null) return;
                            setLocal(() {
                              photoLocalPath = shot.localPath;
                              photoByteSizeBytes = shot.byteSizeBytes;
                              photoLabel = shot.fileName;
                            });
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l10n.gallery),
                        ),
                      ],
                    ),
                    if (photoLabel != null) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.image_outlined),
                        title: Text(photoLabel!),
                        subtitle: Text(
                          photoByteSizeBytes == null
                              ? l10n.queuedLabel
                              : l10n.queuedWithSize(
                                  EvidenceImagePolicy.formatBytes(
                                    photoByteSizeBytes!,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    try {
      await ref.read(siteOpsRepositoryProvider).addSafety(
            session: session,
            kind: kind,
            title: title.text,
            notes: notes.text,
            hasPhoto: photoLocalPath != null,
            photoLocalPath: photoLocalPath,
            photoByteSizeBytes: photoByteSizeBytes,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _QaTab extends ConsumerWidget {
  const _QaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(inspectionsProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _createInspection(context, ref),
              icon: const Icon(Icons.checklist_outlined),
              label: Text(l10n.wirChecklist),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(child: Text(l10n.noInspectionsYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                shape: _tileShape(context),
                title: Text(r.title),
                subtitle: Text(
                  '${l10n.inspectionChecksCount(
                    r.items.length,
                    r.hasFailures ? l10n.hasFailsLabel : l10n.passLabel,
                  )}'
                  '${r.items.any((i) => i.pendingPhotoUpload) ? l10n.photoQueuedPart : ''}'
                  '${r.items.any((i) => i.photoRemoteUrl != null) ? l10n.photoUploadedPart : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createInspection(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    try {
      // Demo WIR includes one fail — capture compressed evidence for photoOnFail.
      final shot = await ref.read(evidenceCaptureProvider).capturePhoto();
      if (shot == null) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.photoRequiredForFail),
            ),
          );
        }
        return;
      }
      await ref.read(siteOpsRepositoryProvider).addInspection(
            session: session,
            title: 'WIR — Slab Bay 3',
            items: [
              const InspectionItem(
                id: 'i1',
                label: 'Formwork alignment',
                result: InspectionResult.pass,
              ),
              InspectionItem(
                id: 'i2',
                label: 'Rebar cover',
                result: InspectionResult.fail,
                hasPhoto: true,
                photoLocalPath: shot.localPath,
                photoByteSizeBytes: shot.byteSizeBytes,
              ),
              const InspectionItem(
                id: 'i3',
                label: 'Embeds / openings',
                result: InspectionResult.pass,
              ),
            ],
          );
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final size = shot.byteSizeBytes == null
            ? ''
            : ' · ~${EvidenceImagePolicy.formatBytes(shot.byteSizeBytes!)}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inspectionSavedWithFailPhoto(size)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _LabourTab extends ConsumerWidget {
  const _LabourTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(musterProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _addMuster(context, ref),
              icon: const Icon(Icons.groups_outlined),
              label: Text(l10n.muster),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(l10n.noLabourMusterYet),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                shape: _tileShape(context),
                leading: Icon(
                  r.hasPhoto
                      ? Icons.add_a_photo_outlined
                      : Icons.groups_outlined,
                ),
                title: Text('${r.trade} · ${r.headcount}'),
                subtitle: Text(
                  '${l10n.geofenceStatusLine(
                    r.subcontractor,
                    r.geofenceOk ? l10n.geofenceOk : l10n.geofenceMiss,
                  )}'
                  '${r.hasPhoto ? l10n.photoAttachedPart : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addMuster(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;

    String? photoLocalPath;
    int? photoByteSizeBytes;
    String? photoLabel;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n.labourMuster),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.musterDialogHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final shot = await ref
                                .read(evidenceCaptureProvider)
                                .capturePhoto(
                                  source: EvidencePhotoSource.camera,
                                );
                            if (shot == null) return;
                            setLocal(() {
                              photoLocalPath = shot.localPath;
                              photoByteSizeBytes = shot.byteSizeBytes;
                              photoLabel = shot.fileName;
                            });
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l10n.addPhoto),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final shot = await ref
                                .read(evidenceCaptureProvider)
                                .capturePhoto(
                                  source: EvidencePhotoSource.gallery,
                                );
                            if (shot == null) return;
                            setLocal(() {
                              photoLocalPath = shot.localPath;
                              photoByteSizeBytes = shot.byteSizeBytes;
                              photoLabel = shot.fileName;
                            });
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l10n.gallery),
                        ),
                        if (photoLocalPath != null)
                          Text(
                            '${photoLabel ?? 'photo'} · '
                            '${EvidenceImagePolicy.formatBytes(photoByteSizeBytes ?? 0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.logMuster),
                ),
              ],
            );
          },
        );
      },
    );
    if (proceed != true || !context.mounted) return;

    try {
      final geofenceOk = await ref.read(locationServiceProvider).isWithinGeofence(
            site: FakeLocationService.demoSite,
            radiusMeters: 250,
          );
      await ref.read(siteOpsRepositoryProvider).addMuster(
            session: session,
            trade: 'Civil',
            subcontractor: 'Shree Contractors',
            headcount: 18,
            geofenceOk: geofenceOk,
            photoLocalPath: photoLocalPath,
            photoByteSizeBytes: photoByteSizeBytes,
          );
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final photoNote =
            photoLocalPath != null ? l10n.plusEvidencePhoto : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              geofenceOk
                  ? l10n.musterLoggedOk(photoNote)
                  : l10n.musterLoggedMiss(photoNote),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _MaterialsTab extends ConsumerWidget {
  const _MaterialsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(materialsProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _addMaterial(context, ref),
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(l10n.grnUse),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(child: Text(l10n.noMaterialLogsYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                shape: _tileShape(context),
                title: Text('${r.material} · ${r.quantity} ${r.unit}'),
                subtitle: Text(
                  '${r.kind.name}'
                  '${r.activityRef == null ? '' : ' · ${r.activityRef}'}'
                  '${r.hasPhoto ? (r.pendingPhotoUpload ? l10n.photoQueuedPart : l10n.photoAttachedPart) : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addMaterial(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;

    var kind = MaterialLogKind.inward;
    final materialCtrl = TextEditingController(text: 'OPC Cement');
    final qtyCtrl = TextEditingController(text: '200');
    final unitCtrl = TextEditingController(text: 'bags');
    final activityCtrl = TextEditingController(text: 'Slab Bay 3');
    String? photoLocalPath;
    int? photoByteSizeBytes;
    String? photoLabel;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n.materialLog),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.materialDialogHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<MaterialLogKind>(
                      segments: [
                        ButtonSegment(
                          value: MaterialLogKind.inward,
                          label: Text(l10n.inward),
                        ),
                        ButtonSegment(
                          value: MaterialLogKind.consumption,
                          label: Text(l10n.useLabel),
                        ),
                      ],
                      selected: {kind},
                      onSelectionChanged: (s) => setLocal(() => kind = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: materialCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.materialLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.qtyLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.unitLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: activityCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.activityRefOptional,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final shot = await ref
                                .read(evidenceCaptureProvider)
                                .capturePhoto(
                                  source: EvidencePhotoSource.camera,
                                );
                            if (shot == null) return;
                            setLocal(() {
                              photoLocalPath = shot.localPath;
                              photoByteSizeBytes = shot.byteSizeBytes;
                              photoLabel = shot.fileName;
                            });
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l10n.addPhoto),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final shot = await ref
                                .read(evidenceCaptureProvider)
                                .capturePhoto(
                                  source: EvidencePhotoSource.gallery,
                                );
                            if (shot == null) return;
                            setLocal(() {
                              photoLocalPath = shot.localPath;
                              photoByteSizeBytes = shot.byteSizeBytes;
                              photoLabel = shot.fileName;
                            });
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l10n.gallery),
                        ),
                        if (photoLocalPath != null)
                          Text(
                            '${photoLabel ?? 'photo'} · '
                            '${EvidenceImagePolicy.formatBytes(photoByteSizeBytes ?? 0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (proceed != true) {
      materialCtrl.dispose();
      qtyCtrl.dispose();
      unitCtrl.dispose();
      activityCtrl.dispose();
      return;
    }

    try {
      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
      await ref.read(siteOpsRepositoryProvider).addMaterial(
            session: session,
            kind: kind,
            material: materialCtrl.text,
            quantity: qty,
            unit: unitCtrl.text,
            activityRef: activityCtrl.text.trim().isEmpty
                ? null
                : activityCtrl.text.trim(),
            photoLocalPath: photoLocalPath,
            photoByteSizeBytes: photoByteSizeBytes,
          );
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final photoNote =
            photoLocalPath != null ? l10n.plusEvidencePhoto : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kind == MaterialLogKind.inward
                  ? l10n.materialInwardLogged(photoNote)
                  : l10n.materialConsumptionLogged(photoNote),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      materialCtrl.dispose();
      qtyCtrl.dispose();
      unitCtrl.dispose();
      activityCtrl.dispose();
    }
  }
}

RoundedRectangleBorder _tileShape(BuildContext context) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  );
}
