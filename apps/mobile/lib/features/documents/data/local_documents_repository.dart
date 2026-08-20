import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/device/local_media_cache.dart';
import '../../../sync/outbox/outbox_entry.dart';
import '../../../sync/remote/module_remote_pull.dart';
import '../../../sync/remote/outbox_remote_sink.dart';
import '../../../sync/remote/prefs_outbox_queue.dart';
import '../../../sync/remote/storage_uploader.dart';
import '../../../sync/remote/syncable_store.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/document_models.dart';
import '../domain/documents_repository.dart';
import '../domain/pdf_open_source.dart';

class LocalDocumentsRepository
    implements DocumentsRepository, SyncableStore, LocalMediaCache {
  LocalDocumentsRepository(
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

  static const _foldersKey = 'docs.folders';
  static const _documentsKey = 'docs.documents';
  static const _seededKey = 'docs.seeded_projects.v3';
  static const _outboxKey = 'docs.outbox';

  final _folders = <String, DocFolder>{};
  final _documents = <String, ProjectDocument>{};
  final _foldersController = StreamController<List<DocFolder>>.broadcast();
  final _documentsController =
      StreamController<List<ProjectDocument>>.broadcast();

  int _seq = 0;

  String _id(String prefix) {
    _seq += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  void _load() {
    for (final raw in _prefs.getStringList(_foldersKey) ?? const []) {
      final folder =
          DocFolder.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
      _folders[folder.id] = folder;
    }
    for (final raw in _prefs.getStringList(_documentsKey) ?? const []) {
      final doc = ProjectDocument.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _documents[doc.id] = doc;
    }
    _outbox.load();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _foldersKey,
      _folders.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _documentsKey,
      _documents.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _outbox.persist();
    _foldersController.add(_folders.values.toList());
    _documentsController.add(_documents.values.toList());
  }

  Future<void> _persistEntitiesOnly() async {
    await _prefs.setStringList(
      _foldersKey,
      _folders.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _documentsKey,
      _documents.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _foldersController.add(_folders.values.toList());
    _documentsController.add(_documents.values.toList());
  }

  /// Metadata payload for Firestore (skips large inline demo bodies).
  Map<String, Object?> _docMeta(ProjectDocument doc) {
    final json = doc.toJson();
    json.remove('textContent');
    json.remove('pdfPages');
    json.remove('localFilePath');
    return json;
  }

  List<DocFolder> _foldersFor(String projectId) =>
      _folders.values.where((f) => f.projectId == projectId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<ProjectDocument> _docsFor(String projectId, String? folderId) {
    final list = _documents.values.where((d) {
      if (d.projectId != projectId) return false;
      if (folderId == null) return true;
      return d.folderId == folderId;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Stream<List<DocFolder>> watchFolders(String projectId) async* {
    yield _foldersFor(projectId);
    yield* _foldersController.stream.map((_) => _foldersFor(projectId));
  }

  @override
  Stream<List<ProjectDocument>> watchDocuments({
    required String projectId,
    String? folderId,
  }) async* {
    yield _docsFor(projectId, folderId);
    yield* _documentsController.stream
        .map((_) => _docsFor(projectId, folderId));
  }

  @override
  Future<ProjectDocument?> getDocument(String documentId) async =>
      _documents[documentId];

  @override
  Future<void> ensureSeedData(AuthSession session) async {
    final seeded = _prefs.getStringList(_seededKey) ?? [];
    if (seeded.contains(session.activeProjectId)) return;

    final orgId = session.activeProject.orgId;
    final projectId = session.activeProjectId;
    final useStableIds = projectId == 'proj_pune_tower';
    final now = useStableIds
        ? DateTime.utc(2026, 7, 20, 8)
        : DateTime.now().toUtc();

    // Drop any prior demo tree for this project (v2 used random ids).
    _folders.removeWhere((_, f) => f.projectId == projectId);
    _documents.removeWhere((_, d) => d.projectId == projectId);

    DocFolder addFolder({
      required String id,
      required String name,
      required FolderKind kind,
      String? parentId,
    }) {
      final folder = DocFolder(
        id: id,
        orgId: orgId,
        projectId: projectId,
        name: name,
        kind: kind,
        parentId: parentId,
        synced: true,
      );
      _folders[folder.id] = folder;
      return folder;
    }

    final structural = addFolder(
      id: useStableIds ? 'folder_seed_structural' : _id('folder'),
      name: 'Structural',
      kind: FolderKind.discipline,
    );
    final mep = addFolder(
      id: useStableIds ? 'folder_seed_mep' : _id('folder'),
      name: 'MEP',
      kind: FolderKind.discipline,
    );
    final drawings = addFolder(
      id: useStableIds ? 'folder_seed_drawings' : _id('folder'),
      name: 'Drawings',
      kind: FolderKind.documentType,
      parentId: structural.id,
    );
    final specs = addFolder(
      id: useStableIds ? 'folder_seed_specs' : _id('folder'),
      name: 'Specifications',
      kind: FolderKind.documentType,
      parentId: structural.id,
    );
    final schedules = addFolder(
      id: useStableIds ? 'folder_seed_schedules' : _id('folder'),
      name: 'Schedules',
      kind: FolderKind.documentType,
      parentId: mep.id,
    );

    void addDoc({
      required String id,
      required DocFolder folder,
      required String name,
      required String contentType,
      required DocContentType kind,
      String? textContent,
      List<String> pdfPages = const [],
      String? localFilePath,
      String? remoteUrl,
      bool downloaded = false,
      int? sizeBytes,
      DateTime? createdAt,
    }) {
      final at = createdAt ?? now;
      final doc = ProjectDocument(
        id: id,
        orgId: orgId,
        projectId: projectId,
        folderId: folder.id,
        name: name,
        contentType: contentType,
        kind: kind,
        createdBy: useStableIds ? 'u_admin' : 'seed',
        createdByName: useStableIds ? 'Site Admin' : 'System',
        createdAt: at,
        updatedAt: at,
        sizeBytes: sizeBytes ??
            (textContent?.length ?? pdfPages.join().length),
        downloaded: downloaded,
        synced: true,
        textContent: textContent,
        pdfPages: pdfPages,
        localFilePath: localFilePath,
        remoteUrl: remoteUrl,
      );
      _documents[doc.id] = doc;
    }

    addDoc(
      id: useStableIds ? 'doc_seed_ga_plan' : _id('doc'),
      folder: drawings,
      name: 'GA Plan Level 02.pdf',
      contentType: 'application/pdf',
      kind: DocContentType.pdf,
      localFilePath: DemoDocumentAssets.gaPlanAssetUri,
      remoteUrl: useStableIds ? 'demo://seed/ga-plan-level-02.pdf' : null,
      downloaded: true,
      sizeBytes: 5150,
      pdfPages: const [
        'GA PLAN — LEVEL 02 (seed metadata; open asset in demo or Storage URL when uploaded)',
        'SECTION A-A — Beam B2: 300x600',
        'REVISION LOG — Rev A IFC / Rev B beam depth',
      ],
    );
    addDoc(
      id: useStableIds ? 'doc_seed_mix_notes' : _id('doc'),
      folder: specs,
      name: 'Concrete mix notes.txt',
      contentType: 'text/plain',
      kind: DocContentType.txt,
      textContent:
          'CONCRETE MIX NOTES\n\nM30 for columns.\nM25 for slabs.\nCure 7 days minimum.\nPhoto evidence required on pour day.',
      remoteUrl: useStableIds ? 'demo://seed/concrete-mix-notes.txt' : null,
      downloaded: true,
      createdAt: useStableIds ? DateTime.utc(2026, 7, 20, 8, 5) : null,
    );
    addDoc(
      id: useStableIds ? 'doc_seed_cable_csv' : _id('doc'),
      folder: schedules,
      name: 'Cable tray schedule.csv',
      contentType: 'text/csv',
      kind: DocContentType.csv,
      textContent:
          'tag,level,size_mm,length_m\nCT-01,L2,300,42\nCT-02,L2,450,18\nCT-03,L3,300,25\n',
      remoteUrl: useStableIds ? 'demo://seed/cable-tray-schedule.csv' : null,
      createdAt: useStableIds ? DateTime.utc(2026, 7, 20, 8, 10) : null,
    );

    seeded.add(projectId);
    await _prefs.setStringList(_seededKey, seeded);
    await _persist();
  }

  @override
  Future<ProjectDocument> uploadDocument({
    required AuthSession session,
    required UploadDocumentInput input,
  }) async {
    if (!canUploadDocuments(session.activeRole)) {
      throw DocumentsException('Your role cannot upload documents');
    }
    final folder = _folders[input.folderId];
    if (folder == null || folder.projectId != session.activeProjectId) {
      throw DocumentsException('Folder not found in active project');
    }
    if (input.name.trim().isEmpty) {
      throw DocumentsException('File name is required');
    }
    final now = DateTime.now().toUtc();
    final kind = DocContentTypeX.fromMimeOrName(input.contentType, input.name);
    final localPath = (input.localFilePath == null || input.localFilePath!.isEmpty)
        ? 'local://demo/documents/${input.name.trim()}'
        : input.localFilePath!;
    final inferredSize = input.sizeBytes ??
        (input.textContent?.length ?? input.pdfPages.join().length);
    final doc = ProjectDocument(
      id: _id('doc'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      folderId: input.folderId,
      name: input.name.trim(),
      contentType: input.contentType,
      kind: kind,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      updatedAt: now,
      sizeBytes: inferredSize,
      downloaded: true,
      synced: false,
      textContent: input.textContent,
      pdfPages: input.pdfPages,
      localFilePath: localPath,
      pendingUpload: true,
    );
    _documents[doc.id] = doc;
    _outbox.enqueue(
      collection: FirestoreCollections.documents,
      documentId: doc.id,
      operation: OutboxOperation.upload,
      payload: StorageUploadRequest(
        orgId: doc.orgId,
        projectId: doc.projectId,
        parentType: 'documents',
        parentId: doc.id,
        attachmentId: doc.id,
        fileName: doc.name,
        contentType: doc.contentType,
        localPath: localPath,
      ).toPayload(),
    );
    _outbox.enqueue(
      collection: FirestoreCollections.documents,
      documentId: doc.id,
      operation: OutboxOperation.create,
      payload: _docMeta(doc),
    );
    await _persist();
    return doc;
  }

  @override
  Future<ProjectDocument> markDownloaded(String documentId) async {
    final current = _documents[documentId];
    if (current == null) throw DocumentsException('Document not found');
    final updated = current.copyWith(
      downloaded: true,
      updatedAt: DateTime.now().toUtc(),
    );
    _documents[documentId] = updated;
    await _persist();
    return updated;
  }

  @override
  Future<DocFolder> createFolder({
    required AuthSession session,
    required String name,
    required FolderKind kind,
    String? parentId,
  }) async {
    if (!canManageFolders(session.activeRole)) {
      throw DocumentsException('Your role cannot manage folders');
    }
    if (parentId != null) {
      final parent = _folders[parentId];
      if (parent == null || parent.projectId != session.activeProjectId) {
        throw DocumentsException('Parent folder not found');
      }
    }
    final folder = DocFolder(
      id: _id('folder'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      name: name.trim(),
      kind: kind,
      parentId: parentId,
    );
    _folders[folder.id] = folder;
    _outbox.enqueue(
      collection: FirestoreCollections.folders,
      documentId: folder.id,
      operation: OutboxOperation.create,
      payload: folder.toJson(),
    );
    await _persist();
    return folder;
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

        final toApply = _resolvePayload(entry);
        await _remoteSink.apply(toApply);
        if (entry.collection == FirestoreCollections.folders) {
          final cur = _folders[entry.documentId];
          if (cur != null) {
            _folders[entry.documentId] = cur.copyWith(synced: true);
          }
        } else if (entry.collection == FirestoreCollections.documents) {
          final cur = _documents[entry.documentId];
          if (cur != null) {
            _documents[entry.documentId] = cur.copyWith(synced: true);
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
    _outbox.entries
      ..clear()
      ..addAll(remaining);
    await _outbox.persist();
    await _persistEntitiesOnly();
  }

  OutboxEntry _resolvePayload(OutboxEntry entry) {
    if (entry.collection == FirestoreCollections.documents) {
      final doc = _documents[entry.documentId];
      if (doc != null &&
          (entry.operation == OutboxOperation.create ||
              entry.operation == OutboxOperation.update)) {
        return OutboxEntry(
          id: entry.id,
          collection: entry.collection,
          documentId: entry.documentId,
          operation: entry.operation,
          payload: _docMeta(doc),
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
    final doc = _documents[entry.documentId];
    if (doc == null) return;
    _documents[entry.documentId] = doc.copyWith(
      remoteUrl: url,
      pendingUpload: false,
      synced: false,
    );
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    var changed = 0;
    for (final r in await _remotePull.pullFolders(projectId)) {
      if (!_folders.containsKey(r.id)) {
        _folders[r.id] = DocFolder(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          name: r.name,
          kind: r.kind,
          parentId: r.parentId,
          synced: true,
        );
        changed += 1;
      }
    }
    for (final r in await _remotePull.pullDocuments(projectId)) {
      final local = _documents[r.id];
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        _documents[r.id] = ProjectDocument(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          folderId: r.folderId,
          name: r.name,
          contentType: r.contentType,
          kind: r.kind,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          sizeBytes: r.sizeBytes,
          downloaded: local?.downloaded ?? r.downloaded,
          synced: true,
          textContent: local?.textContent ?? r.textContent,
          pdfPages: local?.pdfPages.isNotEmpty == true
              ? local!.pdfPages
              : r.pdfPages,
          localFilePath: local?.localFilePath ?? r.localFilePath,
          remoteUrl: r.remoteUrl ?? local?.remoteUrl,
          pendingUpload: false,
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
    for (final doc in _documents.values) {
      final path = doc.localFilePath;
      if (path == null || path.isEmpty) continue;
      count += 1;
      final size = LocalCacheEstimates.bytesFor(
        localPath: path,
        byteSizeBytes: doc.sizeBytes > 0 ? doc.sizeBytes : null,
      );
      bytes += size;
      if (LocalCacheEstimates.isReclaimableLocalStub(
        localPath: path,
        remoteUrl: doc.remoteUrl,
      )) {
        reclaimable += size;
        reclaimableCount += 1;
      }
    }
    return LocalCacheSlice(
      label: 'docs',
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
    for (final doc in _documents.values.toList()) {
      if (!LocalCacheEstimates.isReclaimableLocalStub(
        localPath: doc.localFilePath,
        remoteUrl: doc.remoteUrl,
      )) {
        continue;
      }
      freed += LocalCacheEstimates.bytesFor(
        localPath: doc.localFilePath,
        byteSizeBytes: doc.sizeBytes > 0 ? doc.sizeBytes : null,
      );
      _documents[doc.id] = doc.copyWith(clearLocalFilePath: true);
      changed = true;
    }
    if (changed) await _persist();
    return freed;
  }
}
