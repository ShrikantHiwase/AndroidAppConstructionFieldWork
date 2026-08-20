import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../issues/domain/issue_models.dart';
import '../../issues/presentation/field_records_providers.dart';
import '../../../core/errors/localize_app_error.dart';

class RfisListPage extends ConsumerWidget {
  const RfisListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rfisAsync = ref.watch(rfisProvider);
    final session = ref.watch(authSessionProvider);
    final offline = ref.watch(isOfflineProvider);
    final canCreate =
        session != null && canMutateFieldRecords(session.activeRole);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rfisTitle),
        actions: [
          IconButton(
            tooltip: offline ? l10n.tooltipGoOnlineSync : l10n.goOffline,
            onPressed: () => ref.read(isOfflineProvider.notifier).toggle(),
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
              label: Text(l10n.newRfi),
            )
          : null,
      body: rfisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(localizeAppError(e, l10n))),
        data: (rfis) {
          if (rfis.isEmpty) {
            return Center(child: Text(l10n.noRfisYet));
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
                  '${rfi.status.localizedLabel(l10n)}'
                  '${rfi.assigneeName == null ? '' : ' · ${rfi.assigneeName}'}'
                  '${rfi.synced ? '' : l10n.notSyncedSuffix}',
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
        await ref.read(syncEngineProvider).flushNow(isOnline: true);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = localizeAppError(e, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newRfi)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _subject,
                  decoration: InputDecoration(
                    labelText: l10n.subjectLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _question,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: l10n.questionLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
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
                : Text(l10n.submitRfi),
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

  Future<void> _afterMutate() async {
    if (!ref.read(isOfflineProvider)) {
      await ref.read(syncEngineProvider).flushNow(isOnline: true);
    }
  }

  Future<void> _notify({
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await ref.read(pushNotificationServiceProvider).notifyLocal(
          title: title,
          body: body,
          data: data,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        appBar: AppBar(title: Text(l10n.rfiNoun)),
        body: Center(child: Text(l10n.rfiNotFound)),
      );
    }

    final current = rfi;
    final activeSession = session;
    final canStatus =
        RolePermissions.canChangeIssueStatus(activeSession.activeRole);
    final canAssign = RolePermissions.canAssignWork(activeSession.activeRole);
    final canComment = canMutateFieldRecords(activeSession.activeRole);

    return Scaffold(
      appBar: AppBar(title: Text(current.subject)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(current.status.localizedLabel(l10n), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(current.question),
          const SizedBox(height: 8),
          Text(
            l10n.byAuthorLine(
              current.createdByName,
              current.assigneeName == null
                  ? ''
                  : l10n.assignedToPart(current.assigneeName!),
              current.synced ? l10n.syncedPart : l10n.pendingSyncPart,
            ),
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
                                await _notify(
                                  title: l10n.notifyRfiStatusUpdated,
                                  body: '${current.subject} → ${s.localizedLabel(l10n)}',
                                  data: {
                                    'type': 'rfi_status',
                                    'rfiId': current.id,
                                    'status': s.firestoreValue,
                                  },
                                );
                                await _afterMutate();
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      child: Text(s.localizedLabel(l10n)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (canAssign) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await ref.read(fieldRecordsRepositoryProvider).assignRfi(
                              session: activeSession,
                              rfiId: current.id,
                              assigneeId: 'u_engineer',
                              assigneeName: 'Asha Patil',
                            );
                        await _notify(
                          title: l10n.notifyRfiAssigned,
                          body: '${current.subject} → Asha Patil',
                          data: {
                            'type': 'rfi_assigned',
                            'rfiId': current.id,
                            'assigneeId': 'u_engineer',
                          },
                        );
                        await _afterMutate();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(localizeAppError(e, l10n))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(l10n.assignToAsha),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.threadedResponses, style: Theme.of(context).textTheme.titleMedium),
          commentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(localizeAppError(e, l10n)),
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
              decoration: InputDecoration(
                labelText: l10n.addResponse,
                border: const OutlineInputBorder(),
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
                        await _afterMutate();
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(l10n.postResponse),
            ),
          ],
        ],
      ),
    );
  }
}
