import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/site_ops_models.dart';
import 'site_ops_providers.dart';

class SiteOpsHubPage extends ConsumerWidget {
  const SiteOpsHubPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Site ops'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Safety'),
              Tab(text: 'QA/QC'),
              Tab(text: 'Labour'),
              Tab(text: 'Materials'),
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
    final list = ref.watch(safetyProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateSafety(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Log safety'),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No safety records yet.'));
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
                  '${r.hasPhoto ? ' · photo' : ''}',
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
    var hasPhoto = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Safety record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu<SafetyKind>(
                      initialSelection: kind,
                      label: const Text('Kind'),
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
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Attach demo photo'),
                      value: hasPhoto,
                      onChanged: (v) =>
                          setLocal(() => hasPhoto = v ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
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
            hasPhoto: hasPhoto,
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
    final list = ref.watch(inspectionsProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _createInspection(context, ref),
              icon: const Icon(Icons.checklist_outlined),
              label: const Text('WIR checklist'),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No inspections yet.'));
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
                  '${r.items.length} checks · '
                  '${r.hasFailures ? 'HAS FAILS' : 'PASS'}',
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
      await ref.read(siteOpsRepositoryProvider).addInspection(
            session: session,
            title: 'WIR — Slab Bay 3',
            items: const [
              InspectionItem(
                id: 'i1',
                label: 'Formwork alignment',
                result: InspectionResult.pass,
              ),
              InspectionItem(
                id: 'i2',
                label: 'Rebar cover',
                result: InspectionResult.fail,
                hasPhoto: true,
              ),
              InspectionItem(
                id: 'i3',
                label: 'Embeds / openings',
                result: InspectionResult.pass,
              ),
            ],
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection saved (demo WIR)')),
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
    final list = ref.watch(musterProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _addMuster(context, ref),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Muster'),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Text('No labour muster yet (supervisor-led).'),
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
                title: Text('${r.trade} · ${r.headcount}'),
                subtitle: Text(
                  '${r.subcontractor} · geofence '
                  '${r.geofenceOk ? 'OK' : 'MISS'}',
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
    try {
      await ref.read(siteOpsRepositoryProvider).addMuster(
            session: session,
            trade: 'Civil',
            subcontractor: 'Shree Contractors',
            headcount: 18,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Muster logged (demo geofence OK)')),
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
    final list = ref.watch(materialsProvider);
    final session = ref.watch(authSessionProvider);
    final canEdit = session != null && canMutateSiteOps(session.activeRole);

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _addMaterial(context, ref),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('GRN / use'),
            )
          : null,
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No material logs yet.'));
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
                  '${r.activityRef == null ? '' : ' · ${r.activityRef}'}',
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
    try {
      await ref.read(siteOpsRepositoryProvider).addMaterial(
            session: session,
            kind: MaterialLogKind.inward,
            material: 'OPC Cement',
            quantity: 200,
            unit: 'bags',
            activityRef: 'Slab Bay 3',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material inward logged')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

RoundedRectangleBorder _tileShape(BuildContext context) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  );
}
