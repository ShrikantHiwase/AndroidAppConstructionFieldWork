import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/device/local_media_cache.dart';
import '../../../core/device/voice_audio_policy.dart';
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
    implements VoiceNotesRepository, SyncableStore, LocalMediaCache {
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
  static const _seededKey = 'voice.seeded_projects.v1';

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
  Future<VoiceNote> addVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    required String audioLocalPath,
    String? fileName,
    int? audioByteSizeBytes,
    String? transcript,
    bool offline = false,
  }) async {
    if (!canAddVoiceNotes(session.activeRole)) {
      throw VoiceNotesException('Client accounts cannot add voice notes');
    }
    if (parentId.trim().isEmpty) {
      throw VoiceNotesException('Parent record is required');
    }
    if (audioLocalPath.trim().isEmpty) {
      throw VoiceNotesException('Audio path is required');
    }
    final now = DateTime.now().toUtc();
    final id = 'voice_${now.microsecondsSinceEpoch}_${++_seq}';
    final pending = offline;
    final path = audioLocalPath.trim();
    final pathLeaf = path.split('/').last;
    final resolvedName = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : (pathLeaf.isEmpty ? 'voice_$id.m4a' : pathLeaf);
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
      audioLocalPath: path,
      audioByteSizeBytes: audioByteSizeBytes ??
          (LocalCacheEstimates.isDemoPath(path)
              ? VoiceAudioPolicy.demoByteSize
              : null),
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
        fileName: resolvedName,
        contentType: 'audio/mp4',
        localPath: path,
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
  Future<VoiceNote> addDemoVoiceNote({
    required AuthSession session,
    required VoiceParentType parentType,
    required String parentId,
    String? transcript,
    bool offline = false,
  }) async {
    final now = DateTime.now().toUtc();
    final stubId = 'voice_${now.microsecondsSinceEpoch}_${_seq + 1}';
    return addVoiceNote(
      session: session,
      parentType: parentType,
      parentId: parentId,
      audioLocalPath: 'local://demo/voice_$stubId.m4a',
      fileName: 'voice_$stubId.m4a',
      audioByteSizeBytes: VoiceAudioPolicy.demoByteSize,
      transcript: transcript,
      offline: offline,
    );
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
          audioByteSizeBytes: r.audioByteSizeBytes,
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

  @override
  LocalCacheSlice estimateLocalCache() {
    var bytes = 0;
    var reclaimable = 0;
    var reclaimableCount = 0;
    var count = 0;
    for (final note in _items.values) {
      final path = note.audioLocalPath;
      if (path == null || path.isEmpty) continue;
      count += 1;
      final size = LocalCacheEstimates.bytesFor(
        localPath: path,
        byteSizeBytes: note.audioByteSizeBytes ?? VoiceAudioPolicy.demoByteSize,
      );
      bytes += size;
      if (LocalCacheEstimates.isReclaimableLocalStub(
        localPath: path,
        remoteUrl: note.remoteAudioUrl,
      )) {
        reclaimable += size;
        reclaimableCount += 1;
      }
    }
    return LocalCacheSlice(
      label: 'voice',
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
    for (final note in _items.values.toList()) {
      if (!LocalCacheEstimates.isReclaimableLocalStub(
        localPath: note.audioLocalPath,
        remoteUrl: note.remoteAudioUrl,
      )) {
        continue;
      }
      freed += LocalCacheEstimates.bytesFor(
        localPath: note.audioLocalPath,
        byteSizeBytes: note.audioByteSizeBytes ?? VoiceAudioPolicy.demoByteSize,
      );
      _items[note.id] = note.copyWith(clearAudioLocalPath: true);
      changed = true;
    }
    if (changed) await _persist();
    return freed;
  }

  @override
  Future<void> ensureSeedVoiceNotes(AuthSession session) async {
    final seeded = _prefs.getStringList(_seededKey) ?? [];
    if (seeded.contains(session.activeProjectId)) return;

    final now = DateTime.now().toUtc();
    final yesterday = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final orgId = session.activeProject.orgId;
    final projectId = session.activeProjectId;
    // Matches LocalDprRepository.ensureSeedDprs parent id.
    final dprId =
        'dpr_seed_${projectId}_${yesterday.toIso8601String().split('T').first}';

    final (noteId, transcript, remoteUrl) = switch (projectId) {
      'proj_mumbai_metro' => (
          'voice_seed_dpr_mumbai',
          'Yard staging ready. Waiting on visitor badges for night shift.',
          'demo://seed/voice-dpr-mumbai.m4a',
        ),
      _ => (
          'voice_seed_dpr',
          'Slab shuttering 80 percent. Need beam depth answer before pour.',
          'demo://seed/voice-dpr-0801.m4a',
        ),
    };

    _items[noteId] = VoiceNote(
      id: noteId,
      orgId: orgId,
      projectId: projectId,
      parentType: VoiceParentType.dpr,
      parentId: dprId,
      transcript: transcript,
      createdBy: 'u_engineer',
      createdByName: 'Asha Patil',
      createdAt: yesterday.add(const Duration(hours: 11, minutes: 40)),
      remoteAudioUrl: remoteUrl,
      transcriptPending: false,
      synced: true,
    );

    seeded.add(projectId);
    await _prefs.setStringList(_seededKey, seeded);
    await _persist();
  }
}
