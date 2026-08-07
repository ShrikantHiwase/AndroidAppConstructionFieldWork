import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../voice_notes/domain/voice_note_models.dart';
import '../../voice_notes/presentation/voice_notes_section.dart';
import '../domain/issue_models.dart';
import 'field_records_providers.dart';

class IssueDetailPage extends ConsumerStatefulWidget {
  const IssueDetailPage({super.key, required this.issueId});

  final String issueId;

  @override
  ConsumerState<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends ConsumerState<IssueDetailPage> {
  final _comment = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Issue? _find(List<Issue> issues) {
    for (final issue in issues) {
      if (issue.id == widget.issueId) return issue;
    }
    return null;
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
    final issues = ref.watch(issuesProvider).valueOrNull ?? const <Issue>[];
    final issue = _find(issues);
    final session = ref.watch(authSessionProvider);
    final commentsAsync = ref.watch(
      commentsProvider((type: 'issue', id: widget.issueId)),
    );

    if (issue == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.issueNoun)),
        body: Center(child: Text(l10n.issueNotFound)),
      );
    }

    final canStatus = RolePermissions.canChangeIssueStatus(session.activeRole);
    final canAssign = RolePermissions.canAssignWork(session.activeRole);
    final canComment = canMutateFieldRecords(session.activeRole);

    return Scaffold(
      appBar: AppBar(title: Text(issue.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(issue.status.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            issue.description.isEmpty ? l10n.noDescription : issue.description,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.byAuthorLine(
              issue.createdByName,
              issue.assigneeName == null
                  ? ''
                  : l10n.assignedToPart(issue.assigneeName!),
              issue.synced ? l10n.syncedPart : l10n.pendingSyncPart,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (issue.location != null) ...[
            const SizedBox(height: 8),
            Text(
              'GPS: ${issue.location!.latitude.toStringAsFixed(5)}, '
              '${issue.location!.longitude.toStringAsFixed(5)}'
              '${issue.location!.label == null ? '' : ' (${issue.location!.label})'}',
            ),
          ],
          if (issue.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...issue.attachments.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(a.fileName),
                subtitle: Text(
                  a.pendingUpload
                      ? l10n.queuedForUpload
                      : (a.remoteUrl == null
                          ? l10n.onDeviceStatus
                          : (a.remoteUrl!.startsWith('demo://')
                              ? l10n.syncedDemoStatus
                              : l10n.uploadedStatus)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          VoiceNotesSection(
            parentType: VoiceParentType.issue,
            parentId: issue.id,
            canAdd: canComment,
          ),
          if (canStatus && issue.status.nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.statusSection, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: issue.status.nextStatuses
                  .map(
                    (s) => FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                await ref
                                    .read(fieldRecordsRepositoryProvider)
                                    .updateIssueStatus(
                                      session: session,
                                      issueId: issue.id,
                                      status: s,
                                    );
                                await _notify(
                                  title: 'Issue status updated',
                                  body:
                                      '${issue.title} → ${s.label}',
                                  data: {
                                    'type': 'issue_status',
                                    'issueId': issue.id,
                                    'status': s.firestoreValue,
                                  },
                                );
                                await _afterMutate();
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
                      child: Text(s.label),
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
                        await ref.read(fieldRecordsRepositoryProvider).assignIssue(
                              session: session,
                              issueId: issue.id,
                              assigneeId: 'u_engineer',
                              assigneeName: 'Asha Patil',
                            );
                        await _notify(
                          title: 'Issue assigned',
                          body: '${issue.title} → Asha Patil',
                          data: {
                            'type': 'issue_assigned',
                            'issueId': issue.id,
                            'assigneeId': 'u_engineer',
                          },
                        );
                        await _afterMutate();
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
              child: Text(l10n.assignToAsha),
            ),
          ],
          if (issue.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.statusHistory, style: Theme.of(context).textTheme.titleMedium),
            ...issue.statusHistory.map(
              (h) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${h.from.label} → ${h.to.label}'),
                subtitle: Text(h.changedAt.toLocal().toString()),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.comments, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          commentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (comments) {
              if (comments.isEmpty) {
                return Text(l10n.noCommentsYet);
              }
              return Column(
                children: comments
                    .map(
                      (c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.body),
                        subtitle: Text(
                          '${c.authorName} · ${c.synced ? l10n.syncedLabel : l10n.pendingLabel}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (canComment) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              decoration: InputDecoration(
                labelText: l10n.addComment,
                border: const OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await ref.read(fieldRecordsRepositoryProvider).addComment(
                              session: session,
                              parentType: 'issue',
                              parentId: issue.id,
                              body: _comment.text,
                            );
                        _comment.clear();
                        await _afterMutate();
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
              child: Text(l10n.postComment),
            ),
          ],
        ],
      ),
    );
  }
}
