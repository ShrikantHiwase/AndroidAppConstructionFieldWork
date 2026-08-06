import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../sync/outbox/outbox_entry.dart';
import '../../../sync/remote/module_remote_pull.dart';
import '../../../sync/remote/outbox_remote_sink.dart';
import '../../../sync/remote/prefs_outbox_queue.dart';
import '../../../sync/remote/storage_uploader.dart';
import '../../../sync/remote/syncable_store.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/voice_note_models.dart';
import '../domain/voice_notes_repository.dart';

class LocalVoiceNotesRepository
    implements VoiceNotesRepository, SyncableStore {
  LocalVoiceNotesRepository(
    this._prefs, {
    OutboxRemoteSink? remoteSink,
    ModuleRemotePull? remotePull,
    StorageUploader? storageUploader,
  })  : _remoteSink = remoteSink ?? const NoOpOutboxRemoteSink(),
        _remotePull = remotePull ?? const NoOpModuleRemotePull(),
        _storageUploader = storageUploader ?? const NoOpStorageUploader(),
        _outbox = PrefsOutboxQueue(_prefs, _outboxKey) {
    _load();
  }

  final SharedPreferences _prefs;
  final OutboxRemoteSink _remoteSink;
  final ModuleRemotePull _remotePull;
  final StorageUploader _storageUploader;
  final PrefsOutboxQueue _outbox;

  static const _key = 'voice.notes';
  static const _outboxKey = 'voice.outbox';

  final _items = <String, VoiceNote>{};
  final _controller = StreamController<List<VoiceNote>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      final note = VoiceNote.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _items[note.id] = note;
    }
    _outbox.load();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _outbox.persist();
    _controller.add(_items.values.toList());
  }

  Future<void> _persistEntitiesOnly() async {
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _controller.add(_items.values.toList());
  }

  List<VoiceNote> _filter({
    required VoiceParentType parentType,
    required String parentId,
  }) {
    return _items.values
        .where((n) => n.parentType == parentType && n.parentId == parentId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Stream<List<VoiceNote>> watchForParent({
    required VoiceParentType parentType,
    required String parentId,
  }) async* {
    yield _filter(parentType: parentType, parentId: parentId);
    yield* _controller.stream
        .map((_) => _filter(parentType: parentType, parentId: parentId));
  }

  @override
  Future<List<VoiceNote>> listForParent({
    required VoiceParentType parentType,
    required String parentId,
  }) async {
    return _filter(parentType: parentType, parentId: parentId);
  }

  @override
  Future<VoiceNote> addDemoVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    String? transcript,
    bool offline = false,
  }) async {
    if (!canAddVoiceNotes(session.activeRole)) {
      throw VoiceNotesException('Client accounts cannot add voice notes');
    }
    if (parentId.trim().isEmpty) {
      throw VoiceNotesException('Parent record is required');
    }
    final now = DateTime.now().toUtc();
    final id = 'voice_${now.microsecondsSinceEpoch}_${++_seq}';
    final pending = offline;
    final audioPath = 'local://demo/voice_$id.m4a';
    final note = VoiceNote(
      id: id,
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      parentType: parentType,
      parentId: parentId,
      transcript: pending
          ? (transcript?.trim().isNotEmpty == true
              ? transcript!.trim()
              : 'Audio stored offline — transcript when online')
          : (transcript?.trim().isNotEmpty == true
              ? transcript!.trim()
              : 'Voice stub: progress update from site (${session.user.displayName})'),
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      audioLocalPath: audioPath,
      transcriptPending: pending,
      synced: false,
    );
    _items[note.id] = note;
    _outbox.enqueue(
      collection: FirestoreCollections.voiceNotes,
      documentId: note.id,
      operation: OutboxOperation.upload,
      payload: StorageUploadRequest(
        orgId: note.orgId,
        projectId: note.projectId,
        parentType: 'voice',
        parentId: note.id,
        attachmentId: note.id,
        fileName: 'voice_$id.m4a',
        contentType: 'audio/mp4',
        localPath: audioPath,
      ).toPayload(),
    );
    _outbox.enqueue(
      collection: FirestoreCollections.voiceNotes,
      documentId: note.id,
      operation: OutboxOperation.create,
      payload: note.toRemoteJson(),
    );
    await _persist();
    return note;
  }

  @override
  Stream<int> watchPendingSyncCount() => _outbox.watchPending();

  @override
  Future<void> flushOutbox({required bool isOnline}) async {
    if (!isOnline || _outbox.entries.isEmpty) {
      _outbox.pendingController.add(_outbox.entries.length);
      return;
    }

    final remaining = <OutboxEntry>[];
    final failedUploadDocs = <String>{};
    for (final entry in List<OutboxEntry>.from(_outbox.entries)) {
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

        // Resolve offline transcript pending before push.
        final current = _items[entry.documentId];
        if (current != null && current.transcriptPending) {
          _items[entry.documentId] = current.copyWith(
            transcript:
                'Voice stub: progress update from site (${current.createdByName})',
            transcriptPending: false,
          );
        }

        final toApply = _resolvePayload(entry);
        await _remoteSink.apply(toApply);
        final note = _items[entry.documentId];
        if (note != null) {
          _items[entry.documentId] = note.copyWith(synced: true);
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
    _outbox.entries
      ..clear()
      ..addAll(remaining);
    await _outbox.persist();
    await _persistEntitiesOnly();
  }

  OutboxEntry _resolvePayload(OutboxEntry entry) {
    final note = _items[entry.documentId];
    if (note != null &&
        (entry.operation == OutboxOperation.create ||
            entry.operation == OutboxOperation.update)) {
      return OutboxEntry(
        id: entry.id,
        collection: entry.collection,
        documentId: entry.documentId,
        operation: entry.operation,
        payload: note.toRemoteJson(),
        createdAt: entry.createdAt,
        attempts: entry.attempts,
        lastError: entry.lastError,
      );
    }
    return entry;
  }

  Future<void> _flushUpload(OutboxEntry entry) async {
    final request = StorageUploadRequest.fromPayload(entry.payload);
    final url = await _storageUploader.upload(request);
    final note = _items[entry.documentId];
    if (note == null) return;
    _items[entry.documentId] = note.copyWith(
      remoteAudioUrl: url,
      synced: false,
    );
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    final remote = await _remotePull.pullVoiceNotes(projectId);
    var changed = 0;
    for (final r in remote) {
      if (!_items.containsKey(r.id)) {
        _items[r.id] = VoiceNote(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          parentType: r.parentType,
          parentId: r.parentId,
          transcript: r.transcript,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          audioLocalPath: r.audioLocalPath,
          remoteAudioUrl: r.remoteAudioUrl,
          transcriptPending: false,
          synced: true,
        );
        changed += 1;
      }
    }
    if (changed > 0) await _persistEntitiesOnly();
    return changed;
  }
}
