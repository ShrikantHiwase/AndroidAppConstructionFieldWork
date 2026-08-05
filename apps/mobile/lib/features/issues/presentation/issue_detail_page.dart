import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
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
      await ref.read(fieldRecordsRepositoryProvider).flushOutbox(isOnline: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issues = ref.watch(issuesProvider).valueOrNull ?? const <Issue>[];
    final issue = _find(issues);
    final session = ref.watch(authSessionProvider);
    final commentsAsync = ref.watch(
      commentsProvider((type: 'issue', id: widget.issueId)),
    );

    if (issue == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Issue')),
        body: const Center(child: Text('Issue not found')),
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
          Text(issue.description.isEmpty ? 'No description' : issue.description),
          const SizedBox(height: 8),
          Text(
            'By ${issue.createdByName}'
            '${issue.assigneeName == null ? '' : ' · Assigned to ${issue.assigneeName}'}'
            '${issue.synced ? ' · synced' : ' · pending sync'}',
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
              ),
            ),
          ],
          if (canStatus && issue.status.nextStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
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
              child: const Text('Assign to Asha Patil'),
            ),
          ],
          if (issue.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Status history', style: Theme.of(context).textTheme.titleMedium),
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
          Text('Comments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          commentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (comments) {
              if (comments.isEmpty) {
                return const Text('No comments yet.');
              }
              return Column(
                children: comments
                    .map(
                      (c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.body),
                        subtitle: Text(
                          '${c.authorName} · ${c.synced ? 'synced' : 'pending'}',
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
              decoration: const InputDecoration(
                labelText: 'Add comment',
                border: OutlineInputBorder(),
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
              child: const Text('Post comment'),
            ),
          ],
        ],
      ),
    );
  }
}
