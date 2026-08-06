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
import '../domain/site_ops_models.dart';

abstract class SiteOpsRepository {
  Stream<List<SafetyRecord>> watchSafety(String projectId);
  Stream<List<QaInspection>> watchInspections(String projectId);
  Stream<List<LabourMuster>> watchMuster(String projectId);
  Stream<List<MaterialLog>> watchMaterials(String projectId);

  Future<SafetyRecord> addSafety({
    required AuthSession session,
    required SafetyKind kind,
    required String title,
    required String notes,
    bool hasPhoto = false,
    String? photoLocalPath,
    int? photoByteSizeBytes,
  });

  Future<QaInspection> addInspection({
    required AuthSession session,
    required String title,
    required List<InspectionItem> items,
  });

  Future<LabourMuster> addMuster({
    required AuthSession session,
    required String trade,
    required String subcontractor,
    required int headcount,
    bool geofenceOk = true,
  });

  Future<MaterialLog> addMaterial({
    required AuthSession session,
    required MaterialLogKind kind,
    required String material,
    required double quantity,
    required String unit,
    String? activityRef,
  });
}

class LocalSiteOpsRepository implements SiteOpsRepository, SyncableStore {
  LocalSiteOpsRepository(
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

  static const _safetyKey = 'siteops.safety';
  static const _inspKey = 'siteops.inspections';
  static const _musterKey = 'siteops.muster';
  static const _matKey = 'siteops.materials';
  static const _outboxKey = 'siteops.outbox';

  final _safety = <String, SafetyRecord>{};
  final _inspections = <String, QaInspection>{};
  final _muster = <String, LabourMuster>{};
  final _materials = <String, MaterialLog>{};

  final _safetyC = StreamController<List<SafetyRecord>>.broadcast();
  final _inspC = StreamController<List<QaInspection>>.broadcast();
  final _musterC = StreamController<List<LabourMuster>>.broadcast();
  final _matC = StreamController<List<MaterialLog>>.broadcast();
  int _seq = 0;

  String _id(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}_${++_seq}';

  void _load() {
    for (final r in _prefs.getStringList(_safetyKey) ?? const []) {
      final e = SafetyRecord.fromJson(Map<String, Object?>.from(jsonDecode(r) as Map));
      _safety[e.id] = e;
    }
    for (final r in _prefs.getStringList(_inspKey) ?? const []) {
      final e = QaInspection.fromJson(Map<String, Object?>.from(jsonDecode(r) as Map));
      _inspections[e.id] = e;
    }
    for (final r in _prefs.getStringList(_musterKey) ?? const []) {
      final e = LabourMuster.fromJson(Map<String, Object?>.from(jsonDecode(r) as Map));
      _muster[e.id] = e;
    }
    for (final r in _prefs.getStringList(_matKey) ?? const []) {
      final e = MaterialLog.fromJson(Map<String, Object?>.from(jsonDecode(r) as Map));
      _materials[e.id] = e;
    }
    _outbox.load();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _safetyKey,
      _safety.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _inspKey,
      _inspections.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _musterKey,
      _muster.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _matKey,
      _materials.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _outbox.persist();
    _emit();
  }

  void _emit() {
    _safetyC.add(_safety.values.toList());
    _inspC.add(_inspections.values.toList());
    _musterC.add(_muster.values.toList());
    _matC.add(_materials.values.toList());
  }

  Future<void> _persistEntitiesOnly() async {
    await _prefs.setStringList(
      _safetyKey,
      _safety.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _inspKey,
      _inspections.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _musterKey,
      _muster.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _matKey,
      _materials.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _emit();
  }

  void _ensure(AuthSession session) {
    if (!canMutateSiteOps(session.activeRole)) {
      throw SiteOpsException('Client accounts are read-only for site ops');
    }
  }

  @override
  Stream<List<SafetyRecord>> watchSafety(String projectId) async* {
    List<SafetyRecord> f() => _safety.values
        .where((e) => e.projectId == projectId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield f();
    yield* _safetyC.stream.map((_) => f());
  }

  @override
  Stream<List<QaInspection>> watchInspections(String projectId) async* {
    List<QaInspection> f() => _inspections.values
        .where((e) => e.projectId == projectId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield f();
    yield* _inspC.stream.map((_) => f());
  }

  @override
  Stream<List<LabourMuster>> watchMuster(String projectId) async* {
    List<LabourMuster> f() => _muster.values
        .where((e) => e.projectId == projectId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield f();
    yield* _musterC.stream.map((_) => f());
  }

  @override
  Stream<List<MaterialLog>> watchMaterials(String projectId) async* {
    List<MaterialLog> f() => _materials.values
        .where((e) => e.projectId == projectId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield f();
    yield* _matC.stream.map((_) => f());
  }

  @override
  Future<SafetyRecord> addSafety({
    required AuthSession session,
    required SafetyKind kind,
    required String title,
    required String notes,
    bool hasPhoto = false,
    String? photoLocalPath,
    int? photoByteSizeBytes,
  }) async {
    _ensure(session);
    if (title.trim().isEmpty) throw SiteOpsException('Title required');
    final photoRequired = kind != SafetyKind.toolboxTalk;
    final attached = hasPhoto ||
        (photoLocalPath != null && photoLocalPath.isNotEmpty);
    if (photoRequired && !attached) {
      throw SiteOpsException('Photo evidence required for ${kind.name}');
    }
    final now = DateTime.now().toUtc();
    final pendingUpload =
        attached && photoLocalPath != null && photoLocalPath.isNotEmpty;
    final record = SafetyRecord(
      id: _id('safety'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      kind: kind,
      title: title.trim(),
      notes: notes.trim(),
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      photoRequired: photoRequired,
      hasPhoto: attached,
      photoLocalPath: photoLocalPath,
      photoByteSizeBytes: photoByteSizeBytes,
      pendingPhotoUpload: pendingUpload,
    );
    _safety[record.id] = record;
    if (pendingUpload) {
      final path = photoLocalPath;
      final fileName = path.split('/').last;
      _outbox.enqueue(
        collection: FirestoreCollections.safetyRecords,
        documentId: record.id,
        operation: OutboxOperation.upload,
        payload: StorageUploadRequest(
          orgId: record.orgId,
          projectId: record.projectId,
          parentType: 'safety_records',
          parentId: record.id,
          attachmentId: 'photo',
          fileName: fileName.isEmpty ? 'safety.jpg' : fileName,
          contentType: 'image/jpeg',
          localPath: path,
        ).toPayload(),
      );
    }
    _outbox.enqueue(
      collection: FirestoreCollections.safetyRecords,
      documentId: record.id,
      operation: OutboxOperation.create,
      payload: record.toJson(),
    );
    await _persist();
    return record;
  }

  @override
  Future<QaInspection> addInspection({
    required AuthSession session,
    required String title,
    required List<InspectionItem> items,
  }) async {
    _ensure(session);
    if (title.trim().isEmpty) throw SiteOpsException('Title required');
    if (items.isEmpty) throw SiteOpsException('Add checklist items');
    for (final item in items) {
      if (item.result == InspectionResult.fail &&
          item.photoOnFail &&
          !item.hasPhoto) {
        throw SiteOpsException('Photo required on fail: ${item.label}');
      }
    }
    final preparedItems = items.map((item) {
      final path = item.photoLocalPath;
      final needsUpload =
          path != null && path.isNotEmpty && item.photoRemoteUrl == null;
      return needsUpload
          ? item.copyWith(pendingPhotoUpload: true, hasPhoto: true)
          : item;
    }).toList();

    final insp = QaInspection(
      id: _id('insp'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      title: title.trim(),
      items: preparedItems,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
    );
    _inspections[insp.id] = insp;
    for (final item in preparedItems) {
      final path = item.photoLocalPath;
      if (!item.pendingPhotoUpload || path == null || path.isEmpty) continue;
      final fileName = path.split('/').last;
      _outbox.enqueue(
        collection: FirestoreCollections.inspections,
        documentId: insp.id,
        operation: OutboxOperation.upload,
        payload: StorageUploadRequest(
          orgId: insp.orgId,
          projectId: insp.projectId,
          parentType: 'inspections',
          parentId: insp.id,
          attachmentId: item.id,
          fileName: fileName.isEmpty ? 'qa_fail.jpg' : fileName,
          contentType: 'image/jpeg',
          localPath: path,
        ).toPayload(),
      );
    }
    _outbox.enqueue(
      collection: FirestoreCollections.inspections,
      documentId: insp.id,
      operation: OutboxOperation.create,
      payload: insp.toJson(),
    );
    await _persist();
    return insp;
  }

  @override
  Future<LabourMuster> addMuster({
    required AuthSession session,
    required String trade,
    required String subcontractor,
    required int headcount,
    bool geofenceOk = true,
  }) async {
    _ensure(session);
    if (headcount <= 0) throw SiteOpsException('Headcount must be > 0');
    final muster = LabourMuster(
      id: _id('muster'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      musterDate: DateTime.now().toUtc(),
      trade: trade.trim(),
      subcontractor: subcontractor.trim(),
      headcount: headcount,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
      geofenceOk: geofenceOk,
    );
    _muster[muster.id] = muster;
    _outbox.enqueue(
      collection: FirestoreCollections.attendanceLogs,
      documentId: muster.id,
      operation: OutboxOperation.create,
      payload: muster.toJson(),
    );
    await _persist();
    return muster;
  }

  @override
  Future<MaterialLog> addMaterial({
    required AuthSession session,
    required MaterialLogKind kind,
    required String material,
    required double quantity,
    required String unit,
    String? activityRef,
  }) async {
    _ensure(session);
    if (material.trim().isEmpty) throw SiteOpsException('Material required');
    if (quantity <= 0) throw SiteOpsException('Quantity must be > 0');
    final log = MaterialLog(
      id: _id('mat'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      kind: kind,
      material: material.trim(),
      quantity: quantity,
      unit: unit.trim().isEmpty ? 'unit' : unit.trim(),
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
      activityRef: activityRef?.trim(),
    );
    _materials[log.id] = log;
    _outbox.enqueue(
      collection: FirestoreCollections.materialLogs,
      documentId: log.id,
      operation: OutboxOperation.create,
      payload: log.toJson(),
    );
    await _persist();
    return log;
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
        switch (entry.collection) {
          case FirestoreCollections.safetyRecords:
            final cur = _safety[entry.documentId];
            if (cur != null) {
              _safety[entry.documentId] = cur.copyWith(synced: true);
            }
          case FirestoreCollections.inspections:
            final cur = _inspections[entry.documentId];
            if (cur != null) {
              _inspections[entry.documentId] = cur.copyWith(synced: true);
            }
          case FirestoreCollections.attendanceLogs:
            final cur = _muster[entry.documentId];
            if (cur != null) {
              _muster[entry.documentId] = cur.copyWith(synced: true);
            }
          case FirestoreCollections.materialLogs:
            final cur = _materials[entry.documentId];
            if (cur != null) {
              _materials[entry.documentId] = cur.copyWith(synced: true);
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
    await _persist();
  }

  OutboxEntry _resolvePayload(OutboxEntry entry) {
    if (entry.collection == FirestoreCollections.safetyRecords) {
      final cur = _safety[entry.documentId];
      if (cur != null &&
          (entry.operation == OutboxOperation.create ||
              entry.operation == OutboxOperation.update)) {
        return OutboxEntry(
          id: entry.id,
          collection: entry.collection,
          documentId: entry.documentId,
          operation: entry.operation,
          payload: cur.toJson(),
          createdAt: entry.createdAt,
          attempts: entry.attempts,
          lastError: entry.lastError,
        );
      }
    }
    if (entry.collection == FirestoreCollections.inspections) {
      final cur = _inspections[entry.documentId];
      if (cur != null &&
          (entry.operation == OutboxOperation.create ||
              entry.operation == OutboxOperation.update)) {
        return OutboxEntry(
          id: entry.id,
          collection: entry.collection,
          documentId: entry.documentId,
          operation: entry.operation,
          payload: cur.toJson(),
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

    if (entry.collection == FirestoreCollections.safetyRecords) {
      final cur = _safety[entry.documentId];
      if (cur == null) return;
      _safety[entry.documentId] = cur.copyWith(
        photoRemoteUrl: url,
        pendingPhotoUpload: false,
        hasPhoto: true,
      );
      return;
    }

    if (entry.collection == FirestoreCollections.inspections) {
      final cur = _inspections[entry.documentId];
      if (cur == null) return;
      final updatedItems = cur.items.map((item) {
        if (item.id != request.attachmentId) return item;
        return item.copyWith(
          photoRemoteUrl: url,
          pendingPhotoUpload: false,
          hasPhoto: true,
        );
      }).toList();
      _inspections[entry.documentId] = QaInspection(
        id: cur.id,
        orgId: cur.orgId,
        projectId: cur.projectId,
        title: cur.title,
        items: updatedItems,
        createdBy: cur.createdBy,
        createdByName: cur.createdByName,
        createdAt: cur.createdAt,
        synced: cur.synced,
      );
    }
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    var changed = 0;

    for (final r in await _remotePull.pullSafety(projectId)) {
      if (!_safety.containsKey(r.id)) {
        _safety[r.id] = SafetyRecord(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          kind: r.kind,
          title: r.title,
          notes: r.notes,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          photoRequired: r.photoRequired,
          hasPhoto: r.hasPhoto,
          photoLocalPath: r.photoLocalPath,
          photoByteSizeBytes: r.photoByteSizeBytes,
          photoRemoteUrl: r.photoRemoteUrl,
          pendingPhotoUpload: r.pendingPhotoUpload,
          synced: true,
        );
        changed += 1;
      }
    }
    for (final r in await _remotePull.pullInspections(projectId)) {
      if (!_inspections.containsKey(r.id)) {
        _inspections[r.id] = QaInspection(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          title: r.title,
          items: r.items,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          synced: true,
        );
        changed += 1;
      }
    }
    for (final r in await _remotePull.pullMuster(projectId)) {
      if (!_muster.containsKey(r.id)) {
        _muster[r.id] = LabourMuster(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          musterDate: r.musterDate,
          trade: r.trade,
          subcontractor: r.subcontractor,
          headcount: r.headcount,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          geofenceOk: r.geofenceOk,
          photoOptional: r.photoOptional,
          synced: true,
        );
        changed += 1;
      }
    }
    for (final r in await _remotePull.pullMaterials(projectId)) {
      if (!_materials.containsKey(r.id)) {
        _materials[r.id] = MaterialLog(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          kind: r.kind,
          material: r.material,
          quantity: r.quantity,
          unit: r.unit,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          activityRef: r.activityRef,
          synced: true,
        );
        changed += 1;
      }
    }

    if (changed > 0) await _persistEntitiesOnly();
    return changed;
  }
}
