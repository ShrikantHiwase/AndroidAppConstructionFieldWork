import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../issues/domain/issue_models.dart';
import '../../issues/presentation/field_records_providers.dart';

class RfisListPage extends ConsumerWidget {
  const RfisListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rfisAsync = ref.watch(rfisProvider);
    final session = ref.watch(authSessionProvider);
    final offline = ref.watch(isOfflineProvider);
    final canCreate =
        session != null && canMutateFieldRecords(session.activeRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFIs'),
        actions: [
          IconButton(
            tooltip: offline ? 'Go online & sync' : 'Go offline',
            onPressed: () async {
              final next = !offline;
              ref.read(isOfflineProvider.notifier).state = next;
              if (!next) {
                await ref
                    .read(fieldRecordsRepositoryProvider)
                    .flushOutbox(isOnline: true);
              }
            },
            icon: Icon(offline ? Icons.cloud_off : Icons.cloud_done_outlined),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateRfiPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New RFI'),
            )
          : null,
      body: rfisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rfis) {
          if (rfis.isEmpty) {
            return const Center(child: Text('No RFIs yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rfis.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final rfi = rfis[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                title: Text(rfi.subject),
                subtitle: Text(
                  '${rfi.status.label}'
                  '${rfi.synced ? '' : ' · not synced'}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RfiDetailPage(rfiId: rfi.id),
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

class CreateRfiPage extends ConsumerStatefulWidget {
  const CreateRfiPage({super.key});

  @override
  ConsumerState<CreateRfiPage> createState() => _CreateRfiPageState();
}

class _CreateRfiPageState extends ConsumerState<CreateRfiPage> {
  final _subject = TextEditingController();
  final _question = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(fieldRecordsRepositoryProvider).createRfi(
            session: session,
            input: CreateRfiInput(
              subject: _subject.text,
              question: _question.text,
            ),
          );
      if (!ref.read(isOfflineProvider)) {
        await ref
            .read(fieldRecordsRepositoryProvider)
            .flushOutbox(isOnline: true);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New RFI')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _question,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit RFI'),
          ),
        ],
      ),
    );
  }
}

class RfiDetailPage extends ConsumerStatefulWidget {
  const RfiDetailPage({super.key, required this.rfiId});

  final String rfiId;

  @override
  ConsumerState<RfiDetailPage> createState() => _RfiDetailPageState();
}

class _RfiDetailPageState extends ConsumerState<RfiDetailPage> {
  final _comment = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rfis = ref.watch(rfisProvider).valueOrNull ?? const <Rfi>[];
    Rfi? rfi;
    for (final item in rfis) {
      if (item.id == widget.rfiId) {
        rfi = item;
        break;
      }
    }
    final session = ref.watch(authSessionProvider);
    final commentsAsync =
        ref.watch(commentsProvider((type: 'rfi', id: widget.rfiId)));

    if (rfi == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RFI')),
        body: const Center(child: Text('RFI not found')),
      );
    }

    final current = rfi;
    final activeSession = session;
    final canStatus =
        RolePermissions.canChangeIssueStatus(activeSession.activeRole);
    final canComment = canMutateFieldRecords(activeSession.activeRole);

    return Scaffold(
      appBar: AppBar(title: Text(current.subject)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(current.status.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(current.question),
          const SizedBox(height: 8),
          Text(
            'By ${current.createdByName}${current.synced ? ' · synced' : ' · pending sync'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (canStatus && current.status.nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: current.status.nextStatuses
                  .map(
                    (s) => FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                await ref
                                    .read(fieldRecordsRepositoryProvider)
                                    .updateRfiStatus(
                                      session: activeSession,
                                      rfiId: current.id,
                                      status: s,
                                    );
                                if (!ref.read(isOfflineProvider)) {
                                  await ref
                                      .read(fieldRecordsRepositoryProvider)
                                      .flushOutbox(isOnline: true);
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text('Threaded responses', style: Theme.of(context).textTheme.titleMedium),
          commentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (comments) => Column(
              children: comments
                  .map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.body),
                      subtitle: Text(c.authorName),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (canComment) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              decoration: const InputDecoration(
                labelText: 'Add response',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await ref.read(fieldRecordsRepositoryProvider).addComment(
                              session: activeSession,
                              parentType: 'rfi',
                              parentId: current.id,
                              body: _comment.text,
                            );
                        _comment.clear();
                        if (!ref.read(isOfflineProvider)) {
                          await ref
                              .read(fieldRecordsRepositoryProvider)
                              .flushOutbox(isOnline: true);
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: const Text('Post response'),
            ),
          ],
        ],
      ),
    );
  }
}
