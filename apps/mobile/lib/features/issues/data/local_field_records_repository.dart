import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/device/local_media_cache.dart';
import '../../../sync/outbox/outbox_entry.dart';
import '../../../sync/remote/field_remote_pull.dart';
import '../../../sync/remote/outbox_remote_sink.dart';
import '../../../sync/remote/storage_uploader.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/field_records_repository.dart';
import '../domain/issue_models.dart';

/// Offline-first field records store with sync outbox.
///
/// Creates always succeed locally. [flushOutbox] pushes to [OutboxRemoteSink]
/// (Firestore when Firebase is enabled, no-op in demo) then marks docs synced.
/// Attachment bytes go through [StorageUploader] via [OutboxOperation.upload].
class LocalFieldRecordsRepository
    implements FieldRecordsRepository, LocalMediaCache {
  LocalFieldRecordsRepository(
    this._prefs, {
    OutboxRemoteSink? remoteSink,
    FieldRemotePull? remotePull,
    StorageUploader? storageUploader,
  })  : _remoteSink = remoteSink ?? const NoOpOutboxRemoteSink(),
        _remotePull = remotePull ?? const NoOpFieldRemotePull(),
        _storageUploader = storageUploader ?? const NoOpStorageUploader() {
    _load();
  }

  final SharedPreferences _prefs;
  final OutboxRemoteSink _remoteSink;
  final FieldRemotePull _remotePull;
  final StorageUploader _storageUploader;

  static const _issuesKey = 'field.issues';
  static const _rfisKey = 'field.rfis';
  static const _commentsKey = 'field.comments';
  static const _outboxKey = 'field.outbox';

  final _issues = <String, Issue>{};
  final _rfis = <String, Rfi>{};
  final _comments = <String, FieldComment>{};
  final _outbox = <OutboxEntry>[];

  final _issuesController = StreamController<List<Issue>>.broadcast();
  final _rfisController = StreamController<List<Rfi>>.broadcast();
  final _commentsController = StreamController<List<FieldComment>>.broadcast();
  final _pendingController = StreamController<int>.broadcast();

  int _seq = 0;

  String _newId(String prefix) {
    _seq += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  void _load() {
    for (final raw in _prefs.getStringList(_issuesKey) ?? const []) {
      final issue = Issue.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
      _issues[issue.id] = issue;
    }
    for (final raw in _prefs.getStringList(_rfisKey) ?? const []) {
      final rfi = Rfi.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
      _rfis[rfi.id] = rfi;
    }
    for (final raw in _prefs.getStringList(_commentsKey) ?? const []) {
      final comment =
          FieldComment.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
      _comments[comment.id] = comment;
    }
    for (final raw in _prefs.getStringList(_outboxKey) ?? const []) {
      final map = Map<String, Object?>.from(jsonDecode(raw) as Map);
      _outbox.add(
        OutboxEntry(
          id: map['id'] as String,
          collection: map['collection'] as String,
          documentId: map['documentId'] as String,
          operation: OutboxOperation.values
              .byName(map['operation'] as String? ?? 'create'),
          payload: Map<String, Object?>.from(map['payload'] as Map? ?? {}),
          createdAt: DateTime.parse(map['createdAt'] as String),
          attempts: map['attempts'] as int? ?? 0,
          lastError: map['lastError'] as String?,
        ),
      );
    }
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _issuesKey,
      _issues.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _rfisKey,
      _rfis.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _commentsKey,
      _comments.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _outboxKey,
      _outbox
          .map(
            (e) => jsonEncode({
              'id': e.id,
              'collection': e.collection,
              'documentId': e.documentId,
              'operation': e.operation.name,
              'payload': e.payload,
              'createdAt': e.createdAt.toIso8601String(),
              'attempts': e.attempts,
              'lastError': e.lastError,
            }),
          )
          .toList(),
    );
    _emitAll();
  }

  void _emitAll() {
    _issuesController.add(_issues.values.toList());
    _rfisController.add(_rfis.values.toList());
    _commentsController.add(_comments.values.toList());
    _pendingController.add(_outbox.length);
  }

  void _ensureCanMutate(AuthSession session) {
    if (!canMutateFieldRecords(session.activeRole)) {
      throw FieldRecordsException('Client accounts are read-only');
    }
  }

  void _ensureCanAssign(AuthSession session) {
    if (!RolePermissions.canAssignWork(session.activeRole)) {
      throw FieldRecordsException('Your role cannot assign work');
    }
  }

  void _ensureCanChangeStatus(AuthSession session) {
    if (!RolePermissions.canChangeIssueStatus(session.activeRole)) {
      throw FieldRecordsException('Your role cannot change status');
    }
  }

  List<Issue> _issuesForProject(String projectId) {
    final list = _issues.values.where((i) => i.projectId == projectId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<Rfi> _rfisForProject(String projectId) {
    final list = _rfis.values.where((i) => i.projectId == projectId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Stream<List<Issue>> watchIssues(String projectId) async* {
    yield _issuesForProject(projectId);
    yield* _issuesController.stream.map((_) => _issuesForProject(projectId));
  }

  @override
  Stream<List<Rfi>> watchRfis(String projectId) async* {
    yield _rfisForProject(projectId);
    yield* _rfisController.stream.map((_) => _rfisForProject(projectId));
  }

  @override
  Stream<List<FieldComment>> watchComments({
    required String parentType,
    required String parentId,
  }) async* {
    List<FieldComment> filter() {
      final list = _comments.values
          .where((c) => c.parentType == parentType && c.parentId == parentId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    yield filter();
    yield* _commentsController.stream.map((_) => filter());
  }

  @override
  Stream<int> watchPendingSyncCount() async* {
    yield _outbox.length;
    yield* _pendingController.stream;
  }

  Future<void> _enqueue({
    required String collection,
    required String documentId,
    required OutboxOperation operation,
    required Map<String, Object?> payload,
  }) async {
    _outbox.add(
      OutboxEntry(
        id: _newId('outbox'),
        collection: collection,
        documentId: documentId,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<Issue> createIssue({
    required AuthSession session,
    required CreateIssueInput input,
  }) async {
    _ensureCanMutate(session);
    if (input.title.trim().isEmpty) {
      throw FieldRecordsException('Title is required');
    }
    final now = DateTime.now().toUtc();
    final issue = Issue(
      id: _newId('issue'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      title: input.title.trim(),
      description: input.description.trim(),
      status: IssueStatus.open,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      updatedAt: now,
      assigneeId: input.assigneeId,
      assigneeName: input.assigneeName,
      location: input.location,
      attachments: input.attachments,
      synced: false,
    );
    _issues[issue.id] = issue;
    for (final attachment in issue.attachments) {
      final path = attachment.localPath;
      if (path == null || path.isEmpty || !attachment.pendingUpload) continue;
      await _enqueue(
        collection: FirestoreCollections.issues,
        documentId: issue.id,
        operation: OutboxOperation.upload,
        payload: StorageUploadRequest(
          orgId: issue.orgId,
          projectId: issue.projectId,
          parentType: 'issues',
          parentId: issue.id,
          attachmentId: attachment.id,
          fileName: attachment.fileName,
          contentType: attachment.contentType,
          localPath: path,
        ).toPayload(),
      );
    }
    await _enqueue(
      collection: FirestoreCollections.issues,
      documentId: issue.id,
      operation: OutboxOperation.create,
      payload: issue.toJson(),
    );
    await _persist();
    return issue;
  }

  @override
  Future<Issue> updateIssueStatus({
    required AuthSession session,
    required String issueId,
    required IssueStatus status,
  }) async {
    _ensureCanChangeStatus(session);
    final current = _issues[issueId];
    if (current == null) throw FieldRecordsException('Issue not found');
    if (current.projectId != session.activeProjectId) {
      throw FieldRecordsException('Issue is not in the active project');
    }
    if (!current.status.nextStatuses.contains(status) &&
        current.status != status) {
      throw FieldRecordsException(
        'Cannot move from ${current.status.label} to ${status.label}',
      );
    }
    final now = DateTime.now().toUtc();
    final history = [
      ...current.statusHistory,
      StatusAuditEntry(
        from: current.status,
        to: status,
        changedBy: session.user.id,
        changedAt: now,
      ),
    ];
    final updated = current.copyWith(
      status: status,
      statusHistory: history,
      updatedAt: now,
      synced: false,
    );
    _issues[issueId] = updated;
    await _enqueue(
      collection: FirestoreCollections.issues,
      documentId: issueId,
      operation: OutboxOperation.update,
      payload: {
        'status': status.firestoreValue,
        'updatedAt': now.toIso8601String(),
        'changedBy': session.user.id,
      },
    );
    await _persist();
    return updated;
  }

  @override
  Future<Issue> assignIssue({
    required AuthSession session,
    required String issueId,
    required String assigneeId,
    required String assigneeName,
  }) async {
    _ensureCanAssign(session);
    final current = _issues[issueId];
    if (current == null) throw FieldRecordsException('Issue not found');
    final now = DateTime.now().toUtc();
    final updated = current.copyWith(
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      updatedAt: now,
      synced: false,
    );
    _issues[issueId] = updated;
    await _enqueue(
      collection: FirestoreCollections.issues,
      documentId: issueId,
      operation: OutboxOperation.update,
      payload: {
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'updatedAt': now.toIso8601String(),
      },
    );
    await _persist();
    return updated;
  }

  @override
  Future<Rfi> createRfi({
    required AuthSession session,
    required CreateRfiInput input,
  }) async {
    _ensureCanMutate(session);
    if (input.subject.trim().isEmpty) {
      throw FieldRecordsException('Subject is required');
    }
    final now = DateTime.now().toUtc();
    final rfi = Rfi(
      id: _newId('rfi'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      subject: input.subject.trim(),
      question: input.question.trim(),
      status: IssueStatus.open,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      updatedAt: now,
      assigneeId: input.assigneeId,
      assigneeName: input.assigneeName,
      synced: false,
    );
    _rfis[rfi.id] = rfi;
    await _enqueue(
      collection: FirestoreCollections.rfis,
      documentId: rfi.id,
      operation: OutboxOperation.create,
      payload: rfi.toJson(),
    );
    await _persist();
    return rfi;
  }

  @override
  Future<Rfi> assignRfi({
    required AuthSession session,
    required String rfiId,
    required String assigneeId,
    required String assigneeName,
  }) async {
    _ensureCanAssign(session);
    final current = _rfis[rfiId];
    if (current == null) throw FieldRecordsException('RFI not found');
    final now = DateTime.now().toUtc();
    final updated = current.copyWith(
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      updatedAt: now,
      synced: false,
    );
    _rfis[rfiId] = updated;
    await _enqueue(
      collection: FirestoreCollections.rfis,
      documentId: rfiId,
      operation: OutboxOperation.update,
      payload: {
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'updatedAt': now.toIso8601String(),
      },
    );
    await _persist();
    return updated;
  }

  @override
  Future<Rfi> updateRfiStatus({
    required AuthSession session,
    required String rfiId,
    required IssueStatus status,
  }) async {
    _ensureCanChangeStatus(session);
    final current = _rfis[rfiId];
    if (current == null) throw FieldRecordsException('RFI not found');
    final now = DateTime.now().toUtc();
    final updated = current.copyWith(
      status: status,
      updatedAt: now,
      synced: false,
    );
    _rfis[rfiId] = updated;
    await _enqueue(
      collection: FirestoreCollections.rfis,
      documentId: rfiId,
      operation: OutboxOperation.update,
      payload: {
        'status': status.firestoreValue,
        'updatedAt': now.toIso8601String(),
      },
    );
    await _persist();
    return updated;
  }

  @override
  Future<FieldComment> addComment({
    required AuthSession session,
    required String parentType,
    required String parentId,
    required String body,
  }) async {
    _ensureCanMutate(session);
    if (body.trim().isEmpty) {
      throw FieldRecordsException('Comment cannot be empty');
    }
    final comment = FieldComment(
      id: _newId('comment'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      parentType: parentType,
      parentId: parentId,
      body: body.trim(),
      authorId: session.user.id,
      authorName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
      synced: false,
    );
    _comments[comment.id] = comment;
    await _enqueue(
      collection: FirestoreCollections.comments,
      documentId: comment.id,
      operation: OutboxOperation.create,
      payload: comment.toJson(),
    );
    await _persist();
    return comment;
  }

  @override
  Future<void> flushOutbox({required bool isOnline}) async {
    if (!isOnline || _outbox.isEmpty) {
      _pendingController.add(_outbox.length);
      return;
    }

    final remaining = <OutboxEntry>[];
    final failedUploadDocs = <String>{};
    for (final entry in List<OutboxEntry>.from(_outbox)) {
      try {
        if (entry.operation == OutboxOperation.upload) {
          await _flushUpload(entry);
          continue;
        }

        if (failedUploadDocs.contains(entry.documentId) &&
            (entry.operation == OutboxOperation.create ||
                entry.operation == OutboxOperation.update)) {
          remaining.add(entry);
          continue;
        }

        final toApply = _resolvePayload(entry);
        await _remoteSink.apply(toApply);
        switch (entry.collection) {
          case FirestoreCollections.issues:
            final issue = _issues[entry.documentId];
            if (issue != null) {
              _issues[entry.documentId] = issue.copyWith(synced: true);
            }
          case FirestoreCollections.rfis:
            final rfi = _rfis[entry.documentId];
            if (rfi != null) {
              _rfis[entry.documentId] = rfi.copyWith(synced: true);
            }
          case FirestoreCollections.comments:
            final comment = _comments[entry.documentId];
            if (comment != null) {
              _comments[entry.documentId] = FieldComment(
                id: comment.id,
                orgId: comment.orgId,
                projectId: comment.projectId,
                parentType: comment.parentType,
                parentId: comment.parentId,
                body: comment.body,
                authorId: comment.authorId,
                authorName: comment.authorName,
                createdAt: comment.createdAt,
                synced: true,
              );
            }
        }
      } catch (e) {
        if (entry.operation == OutboxOperation.upload) {
          failedUploadDocs.add(entry.documentId);
        }
        remaining.add(
          OutboxEntry(
            id: entry.id,
            collection: entry.collection,
            documentId: entry.documentId,
            operation: entry.operation,
            payload: entry.payload,
            createdAt: entry.createdAt,
            attempts: entry.attempts + 1,
            lastError: e.toString(),
          ),
        );
      }
    }
    _outbox
      ..clear()
      ..addAll(remaining);
    await _persist();
  }

  /// Prefer live local entity JSON so attachment URLs set by prior upload
  /// entries are included in the Firestore create/update payload.
  OutboxEntry _resolvePayload(OutboxEntry entry) {
    if (entry.collection == FirestoreCollections.issues) {
      final issue = _issues[entry.documentId];
      if (issue != null &&
          (entry.operation == OutboxOperation.create ||
              entry.operation == OutboxOperation.update)) {
        return OutboxEntry(
          id: entry.id,
          collection: entry.collection,
          documentId: entry.documentId,
          operation: entry.operation,
          payload: issue.toJson(),
          createdAt: entry.createdAt,
          attempts: entry.attempts,
          lastError: entry.lastError,
        );
      }
    }
    if (entry.collection == FirestoreCollections.rfis) {
      final rfi = _rfis[entry.documentId];
      if (rfi != null &&
          (entry.operation == OutboxOperation.create ||
              entry.operation == OutboxOperation.update)) {
        return OutboxEntry(
          id: entry.id,
          collection: entry.collection,
          documentId: entry.documentId,
          operation: entry.operation,
          payload: rfi.toJson(),
          createdAt: entry.createdAt,
          attempts: entry.attempts,
          lastError: entry.lastError,
        );
      }
    }
    return entry;
  }

  Future<void> _flushUpload(OutboxEntry entry) async {
    final request = StorageUploadRequest.fromPayload(entry.payload);
    final url = await _storageUploader.upload(request);
    final issue = _issues[entry.documentId];
    if (issue == null) return;
    final updatedAttachments = issue.attachments.map((a) {
      if (a.id != request.attachmentId) return a;
      return a.copyWith(remoteUrl: url, pendingUpload: false);
    }).toList();
    _issues[entry.documentId] = issue.copyWith(
      attachments: updatedAttachments,
      synced: false,
    );
  }

  @override
  Future<({int issues, int rfis})> pullRemote({required String projectId}) async {
    final remoteIssues = await _remotePull.pullIssues(projectId);
    final remoteRfis = await _remotePull.pullRfis(projectId);
    var issueMerges = 0;
    var rfiMerges = 0;

    for (final remote in remoteIssues) {
      final local = _issues[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        _issues[remote.id] = remote.copyWith(synced: true);
        issueMerges += 1;
      }
    }
    for (final remote in remoteRfis) {
      final local = _rfis[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        _rfis[remote.id] = remote.copyWith(synced: true);
        rfiMerges += 1;
      }
    }
    if (issueMerges > 0 || rfiMerges > 0) {
      await _persist();
    }
    return (issues: issueMerges, rfis: rfiMerges);
  }

  @override
  LocalCacheSlice estimateLocalCache() {
    var bytes = 0;
    var reclaimable = 0;
    var reclaimableCount = 0;
    var count = 0;
    for (final issue in _issues.values) {
      for (final a in issue.attachments) {
        final path = a.localPath;
        if (path == null || path.isEmpty) continue;
        count += 1;
        final size = LocalCacheEstimates.bytesFor(
          localPath: path,
          byteSizeBytes: a.byteSizeBytes,
        );
        bytes += size;
        if (LocalCacheEstimates.isReclaimableLocalStub(
          localPath: path,
          remoteUrl: a.remoteUrl,
        )) {
          reclaimable += size;
          reclaimableCount += 1;
        }
      }
    }
    return LocalCacheSlice(
      label: 'issues',
      estimatedBytes: bytes,
      reclaimableBytes: reclaimable,
      reclaimableItemCount: reclaimableCount,
      itemCount: count,
    );
  }

  @override
  Future<int> reclaimUploadedLocalPaths() async {
    var freed = 0;
    var changed = false;
    for (final issue in _issues.values.toList()) {
      var issueChanged = false;
      final next = issue.attachments.map((a) {
        if (!LocalCacheEstimates.isReclaimableLocalStub(
          localPath: a.localPath,
          remoteUrl: a.remoteUrl,
        )) {
          return a;
        }
        freed += LocalCacheEstimates.bytesFor(
          localPath: a.localPath,
          byteSizeBytes: a.byteSizeBytes,
        );
        issueChanged = true;
        return a.copyWith(clearLocalPath: true);
      }).toList();
      if (issueChanged) {
        _issues[issue.id] = issue.copyWith(attachments: next);
        changed = true;
      }
    }
    if (changed) await _persist();
    return freed;
  }
}
