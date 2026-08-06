import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/document_models.dart';
import '../domain/documents_repository.dart';

class LocalDocumentsRepository implements DocumentsRepository {
  LocalDocumentsRepository(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _foldersKey = 'docs.folders';
  static const _documentsKey = 'docs.documents';
  static const _seededKey = 'docs.seeded_projects';

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
    _foldersController.add(_folders.values.toList());
    _documentsController.add(_documents.values.toList());
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
    final now = DateTime.now().toUtc();

    DocFolder addFolder({
      required String name,
      required FolderKind kind,
      String? parentId,
    }) {
      final folder = DocFolder(
        id: _id('folder'),
        orgId: orgId,
        projectId: projectId,
        name: name,
        kind: kind,
        parentId: parentId,
      );
      _folders[folder.id] = folder;
      return folder;
    }

    final structural = addFolder(name: 'Structural', kind: FolderKind.discipline);
    final mep = addFolder(name: 'MEP', kind: FolderKind.discipline);
    final drawings = addFolder(
      name: 'Drawings',
      kind: FolderKind.documentType,
      parentId: structural.id,
    );
    final specs = addFolder(
      name: 'Specifications',
      kind: FolderKind.documentType,
      parentId: structural.id,
    );
    final schedules = addFolder(
      name: 'Schedules',
      kind: FolderKind.documentType,
      parentId: mep.id,
    );

    void addDoc({
      required DocFolder folder,
      required String name,
      required String contentType,
      required DocContentType kind,
      String? textContent,
      List<String> pdfPages = const [],
      bool downloaded = false,
    }) {
      final doc = ProjectDocument(
        id: _id('doc'),
        orgId: orgId,
        projectId: projectId,
        folderId: folder.id,
        name: name,
        contentType: contentType,
        kind: kind,
        createdBy: 'seed',
        createdByName: 'System',
        createdAt: now,
        updatedAt: now,
        sizeBytes: (textContent?.length ?? pdfPages.join().length),
        downloaded: downloaded,
        textContent: textContent,
        pdfPages: pdfPages,
      );
      _documents[doc.id] = doc;
    }

    addDoc(
      folder: drawings,
      name: 'GA Plan Level 02.pdf',
      contentType: 'application/pdf',
      kind: DocContentType.pdf,
      pdfPages: const [
        'GA PLAN — LEVEL 02\nGrid A–F · Scale 1:100\nNorth arrow toward site gate.\nOpening schedules referenced on sheet S-201.',
        'SECTION A-A\nBeam B2: 300x600\nSlab thickness 150mm\nNote: hold pour until QA sign-off.',
        'REVISION LOG\nRev A — IFC issued\nRev B — beam depth updated\nSearch tip: look for "B2" or "QA".',
      ],
    );
    addDoc(
      folder: specs,
      name: 'Concrete mix notes.txt',
      contentType: 'text/plain',
      kind: DocContentType.txt,
      textContent:
          'CONCRETE MIX NOTES\n\nM30 for columns.\nM25 for slabs.\nCure 7 days minimum.\nPhoto evidence required on pour day.',
      downloaded: true,
    );
    addDoc(
      folder: schedules,
      name: 'Cable tray schedule.csv',
      contentType: 'text/csv',
      kind: DocContentType.csv,
      textContent:
          'tag,level,size_mm,length_m\nCT-01,L2,300,42\nCT-02,L2,450,18\nCT-03,L3,300,25\n',
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
      sizeBytes: (input.textContent?.length ?? input.pdfPages.join().length),
      downloaded: true,
      synced: false,
      textContent: input.textContent,
      pdfPages: input.pdfPages,
    );
    _documents[doc.id] = doc;
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
    await _persist();
    return folder;
  }
}
