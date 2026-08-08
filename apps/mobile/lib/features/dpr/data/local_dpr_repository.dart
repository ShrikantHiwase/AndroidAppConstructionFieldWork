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
import '../domain/dpr_models.dart';
import '../domain/dpr_repository.dart';

class LocalDprRepository
    implements DprRepository, SyncableStore, LocalMediaCache {
  LocalDprRepository(
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

  static const _key = 'dpr.reports';
  static const _outboxKey = 'dpr.outbox';
  static const _seededKey = 'dpr.seeded_projects.v1';

  final _items = <String, DailyProgressReport>{};
  final _controller = StreamController<List<DailyProgressReport>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_key) ?? const []) {
      final dpr = DailyProgressReport.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _items[dpr.id] = dpr;
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

  Future<void> _persistReportsOnly() async {
    await _prefs.setStringList(
      _key,
      _items.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _controller.add(_items.values.toList());
  }

  String _dayKey(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).toIso8601String();

  List<DailyProgressReport> _forProject(String projectId) {
    final list = _items.values.where((d) => d.projectId == projectId).toList()
      ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
    return list;
  }

  List<DprActivity> _prepareActivities(
    List<DprActivity> activities, {
    DailyProgressReport? existing,
  }) {
    final previousById = {
      for (final a in existing?.activities ?? const <DprActivity>[]) a.id: a,
    };
    return activities.map((raw) {
      final prev = previousById[raw.id];
      var activity = raw;
      if (prev != null &&
          activity.photoRemoteUrl == null &&
          prev.photoRemoteUrl != null &&
          (activity.photoLocalPath == null ||
              activity.photoLocalPath == prev.photoLocalPath)) {
        activity = activity.copyWith(
          photoRemoteUrl: prev.photoRemoteUrl,
          photoLocalPath: activity.photoLocalPath ?? prev.photoLocalPath,
          photoByteSizeBytes:
              activity.photoByteSizeBytes ?? prev.photoByteSizeBytes,
          hasPhoto: true,
          pendingPhotoUpload: false,
        );
      }
      final path = activity.photoLocalPath;
      final needsUpload =
          path != null && path.isNotEmpty && activity.photoRemoteUrl == null;
      if (needsUpload) {
        return activity.copyWith(pendingPhotoUpload: true, hasPhoto: true);
      }
      if (activity.photoRemoteUrl != null &&
          activity.photoRemoteUrl!.isNotEmpty) {
        return activity.copyWith(hasPhoto: true, pendingPhotoUpload: false);
      }
      return activity.copyWith(
        hasPhoto: false,
        pendingPhotoUpload: false,
      );
    }).toList();
  }

  bool _hasPendingUpload(String documentId, String attachmentId) {
    return _outbox.entries.any(
      (e) =>
          e.operation == OutboxOperation.upload &&
          e.documentId == documentId &&
          e.payload['attachmentId'] == attachmentId,
    );
  }

  void _enqueueActivityUploads(DailyProgressReport dpr) {
    for (final activity in dpr.activities) {
      final path = activity.photoLocalPath;
      if (!activity.pendingPhotoUpload || path == null || path.isEmpty) {
        continue;
      }
      if (_hasPendingUpload(dpr.id, activity.id)) continue;
      final fileName = path.split('/').last;
      _outbox.enqueue(
        collection: FirestoreCollections.dprs,
        documentId: dpr.id,
        operation: OutboxOperation.upload,
        payload: StorageUploadRequest(
          orgId: dpr.orgId,
          projectId: dpr.projectId,
          parentType: 'dprs',
          parentId: dpr.id,
          attachmentId: activity.id,
          fileName: fileName.isEmpty ? 'activity.jpg' : fileName,
          contentType: 'image/jpeg',
          localPath: path,
        ).toPayload(),
      );
    }
  }

  void _enqueueUpsert(DailyProgressReport dpr) {
    _outbox.enqueue(
      collection: FirestoreCollections.dprs,
      documentId: dpr.id,
      operation: OutboxOperation.create,
      payload: dpr.toJson(),
    );
  }

  @override
  Stream<List<DailyProgressReport>> watchDprs(String projectId) async* {
    yield _forProject(projectId);
    yield* _controller.stream.map((_) => _forProject(projectId));
  }

  @override
  Future<DailyProgressReport?> todayDpr(String projectId, DateTime day) async {
    final key = _dayKey(day.toUtc());
    for (final dpr in _items.values) {
      if (dpr.projectId == projectId && _dayKey(dpr.reportDate) == key) {
        return dpr;
      }
    }
    return null;
  }

  @override
  Future<DailyProgressReport> createOrUpdateToday({
    required AuthSession session,
    required CreateDprInput input,
  }) async {
    if (!canEditDpr(session.activeRole)) {
      throw DprException('Client accounts cannot edit DPR');
    }
    final day = (input.reportDate ?? DateTime.now()).toUtc();
    final existing = await todayDpr(session.activeProjectId, day);
    final now = DateTime.now().toUtc();
    final activities = _prepareActivities(
      input.activities,
      existing: existing,
    );
    if (existing != null) {
      if (existing.submitted) {
        throw DprException('Today\'s DPR is already submitted');
      }
      final updated = existing.copyWith(
        weather: input.weather.trim(),
        manpowerSummary: input.manpowerSummary.trim(),
        activities: activities,
        blockers: input.blockers.trim(),
        synced: false,
        updatedAt: now,
      );
      _items[existing.id] = updated;
      _enqueueActivityUploads(updated);
      _enqueueUpsert(updated);
      await _persist();
      return updated;
    }

    final dpr = DailyProgressReport(
      id: 'dpr_${now.microsecondsSinceEpoch}_${++_seq}',
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      reportDate: DateTime.utc(day.year, day.month, day.day),
      weather: input.weather.trim(),
      manpowerSummary: input.manpowerSummary.trim(),
      activities: activities,
      blockers: input.blockers.trim(),
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: now,
      updatedAt: now,
    );
    _items[dpr.id] = dpr;
    _enqueueActivityUploads(dpr);
    _enqueueUpsert(dpr);
    await _persist();
    return dpr;
  }

  @override
  Future<DailyProgressReport> submit({
    required AuthSession session,
    required String dprId,
  }) async {
    if (!canEditDpr(session.activeRole)) {
      throw DprException('Client accounts cannot submit DPR');
    }
    final current = _items[dprId];
    if (current == null) throw DprException('DPR not found');
    if (current.projectId != session.activeProjectId) {
      throw DprException('DPR is not in the active project');
    }
    if (current.activities.isEmpty) {
      throw DprException('Add at least one activity before submit');
    }
    final updated = current.copyWith(
      submitted: true,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    _items[dprId] = updated;
    _enqueueUpsert(updated);
    await _persist();
    return updated;
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
        final current = _items[entry.documentId];
        if (current != null) {
          _items[entry.documentId] = current.copyWith(synced: true);
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
    final cur = _items[entry.documentId];
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
    return entry;
  }

  Future<void> _flushUpload(OutboxEntry entry) async {
    final request = StorageUploadRequest.fromPayload(entry.payload);
    final url = await _storageUploader.upload(request);
    final cur = _items[entry.documentId];
    if (cur == null) return;
    final updatedActivities = cur.activities.map((activity) {
      if (activity.id != request.attachmentId) return activity;
      return activity.copyWith(
        photoRemoteUrl: url,
        pendingPhotoUpload: false,
        hasPhoto: true,
      );
    }).toList();
    _items[entry.documentId] = cur.copyWith(activities: updatedActivities);
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    final remote = await _remotePull.pullDprs(projectId);
    var changed = 0;
    for (final r in remote) {
      final local = _items[r.id];
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        _items[r.id] = DailyProgressReport(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          reportDate: r.reportDate,
          weather: r.weather,
          manpowerSummary: r.manpowerSummary,
          activities: r.activities,
          blockers: r.blockers,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
          submitted: r.submitted,
          synced: true,
        );
        changed += 1;
      }
    }
    if (changed > 0) await _persistReportsOnly();
    return changed;
  }

  @override
  LocalCacheSlice estimateLocalCache() {
    var bytes = 0;
    var reclaimable = 0;
    var reclaimableCount = 0;
    var count = 0;
    for (final dpr in _items.values) {
      for (final activity in dpr.activities) {
        final path = activity.photoLocalPath;
        if (path == null || path.isEmpty) continue;
        count += 1;
        final size = LocalCacheEstimates.bytesFor(
          localPath: path,
          byteSizeBytes: activity.photoByteSizeBytes,
        );
        bytes += size;
        if (LocalCacheEstimates.isReclaimableLocalStub(
          localPath: path,
          remoteUrl: activity.photoRemoteUrl,
        )) {
          reclaimable += size;
          reclaimableCount += 1;
        }
      }
    }
    return LocalCacheSlice(
      label: 'dpr',
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
    for (final dpr in _items.values.toList()) {
      var dprChanged = false;
      final nextActivities = dpr.activities.map((activity) {
        if (!LocalCacheEstimates.isReclaimableLocalStub(
          localPath: activity.photoLocalPath,
          remoteUrl: activity.photoRemoteUrl,
        )) {
          return activity;
        }
        freed += LocalCacheEstimates.bytesFor(
          localPath: activity.photoLocalPath,
          byteSizeBytes: activity.photoByteSizeBytes,
        );
        dprChanged = true;
        return activity.copyWith(clearPhotoLocalPath: true);
      }).toList();
      if (dprChanged) {
        _items[dpr.id] = dpr.copyWith(activities: nextActivities);
        changed = true;
      }
    }
    if (changed) await _persist();
    return freed;
  }

  @override
  Future<void> ensureSeedDprs(AuthSession session) async {
    final seeded = _prefs.getStringList(_seededKey) ?? [];
    if (seeded.contains(session.activeProjectId)) return;

    final now = DateTime.now().toUtc();
    final yesterday = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final orgId = session.activeProject.orgId;
    final projectId = session.activeProjectId;

    final (weather, manpower, activityDesc, activityLoc, blockers) =
        switch (projectId) {
      'proj_mumbai_metro' => (
          'Humid, 29°C',
          '28 on site (civil + electrical)',
          'Yard access / staging prep',
          'BKC yard',
          'Visitor badges delayed overnight',
        ),
      _ => (
          'Clear, 32°C',
          '42 on site (bar + shuttering)',
          'Level 02 slab shuttering',
          'Grid A-C',
          'Waiting on beam depth RFI answer',
        ),
    };

    final id =
        'dpr_seed_${projectId}_${yesterday.toIso8601String().split('T').first}';
    _items[id] = DailyProgressReport(
      id: id,
      orgId: orgId,
      projectId: projectId,
      reportDate: yesterday,
      weather: weather,
      manpowerSummary: manpower,
      activities: [
        DprActivity(
          id: 'act_seed_1',
          description: activityDesc,
          location: activityLoc,
        ),
      ],
      blockers: blockers,
      createdBy: 'u_engineer',
      createdByName: 'Asha Patil',
      createdAt: yesterday.add(const Duration(hours: 11, minutes: 30)),
      updatedAt: yesterday.add(const Duration(hours: 11, minutes: 45)),
      submitted: true,
      synced: true,
    );

    seeded.add(projectId);
    await _prefs.setStringList(_seededKey, seeded);
    await _persist();
  }
}

class LocalDrawingPinsRepository
    implements DrawingPinsRepository, SyncableStore, LocalMediaCache {
  LocalDrawingPinsRepository(
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

  static const _drawingsKey = 'drawings.sheets';
  static const _pinsKey = 'drawings.pins';
  static const _seededKey = 'drawings.seeded';
  static const _pinsSeededKey = 'drawings.pins_seeded.v1';
  static const _outboxKey = 'drawings.outbox';

  final _drawings = <String, DrawingSheet>{};
  final _pins = <String, DrawingPin>{};
  final _drawingsController = StreamController<List<DrawingSheet>>.broadcast();
  final _pinsController = StreamController<List<DrawingPin>>.broadcast();
  int _seq = 0;

  void _load() {
    for (final raw in _prefs.getStringList(_drawingsKey) ?? const []) {
      final sheet = DrawingSheet.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _drawings[sheet.id] = sheet;
    }
    for (final raw in _prefs.getStringList(_pinsKey) ?? const []) {
      final pin = DrawingPin.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      _pins[pin.id] = pin;
    }
    _outbox.load();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      _drawingsKey,
      _drawings.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _prefs.setStringList(
      _pinsKey,
      _pins.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _outbox.persist();
    _drawingsController.add(_drawings.values.toList());
    _pinsController.add(_pins.values.toList());
  }

  Future<void> _persistPinsOnly() async {
    await _prefs.setStringList(
      _pinsKey,
      _pins.values.map((e) => jsonEncode(e.toJson())).toList(),
    );
    _pinsController.add(_pins.values.toList());
  }

  @override
  Future<void> ensureSeedDrawings(AuthSession session) async {
    final projectId = session.activeProjectId;
    final orgId = session.activeProject.orgId;
    final sheetId = 'drawing_${projectId}_ga02';
    var changed = false;

    final seeded = _prefs.getStringList(_seededKey) ?? [];
    if (!seeded.contains(projectId)) {
      _drawings[sheetId] = DrawingSheet(
        id: sheetId,
        orgId: orgId,
        projectId: projectId,
        title: 'GA Plan Level 02',
        version: 'Rev B',
        pageCount: 3,
      );
      seeded.add(projectId);
      await _prefs.setStringList(_seededKey, seeded);
      changed = true;
    }

    // Separate key so installs that already seeded sheets still get the pin.
    final pinsSeeded = _prefs.getStringList(_pinsSeededKey) ?? [];
    if (!pinsSeeded.contains(projectId) && projectId == 'proj_pune_tower') {
      if (!_drawings.containsKey(sheetId)) {
        _drawings[sheetId] = DrawingSheet(
          id: sheetId,
          orgId: orgId,
          projectId: projectId,
          title: 'GA Plan Level 02',
          version: 'Rev B',
          pageCount: 3,
        );
        changed = true;
      }
      _pins['pin_seed_rebar'] = DrawingPin(
        id: 'pin_seed_rebar',
        orgId: orgId,
        projectId: projectId,
        drawingId: sheetId,
        page: 1,
        x: 0.42,
        y: 0.58,
        issueId: 'issue_seed_rebar',
        issueTitle: 'Rebar spacing off grid — Level 02',
        createdBy: 'u_engineer',
        createdByName: 'Asha Patil',
        createdAt: DateTime.utc(2026, 8, 1, 4, 45),
        note: 'Pin near grid B2',
        synced: true,
      );
      pinsSeeded.add(projectId);
      await _prefs.setStringList(_pinsSeededKey, pinsSeeded);
      changed = true;
    }

    if (changed) await _persist();
  }

  @override
  Stream<List<DrawingSheet>> watchDrawings(String projectId) async* {
    List<DrawingSheet> filter() =>
        _drawings.values.where((d) => d.projectId == projectId).toList();
    yield filter();
    yield* _drawingsController.stream.map((_) => filter());
  }

  @override
  Stream<List<DrawingPin>> watchPins(String drawingId) async* {
    List<DrawingPin> filter() => _pins.values
        .where((p) => p.drawingId == drawingId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    yield filter();
    yield* _pinsController.stream.map((_) => filter());
  }

  @override
  Future<DrawingPin> addPin({
    required AuthSession session,
    required CreatePinInput input,
  }) async {
    if (!canPinDrawings(session.activeRole)) {
      throw DrawingException('Client accounts cannot pin drawings');
    }
    final sheet = _drawings[input.drawingId];
    if (sheet == null || sheet.projectId != session.activeProjectId) {
      throw DrawingException('Drawing not found');
    }
    if (input.page < 1 || input.page > sheet.pageCount) {
      throw DrawingException('Page out of range');
    }
    if (input.x < 0 || input.x > 1 || input.y < 0 || input.y > 1) {
      throw DrawingException('Pin must be within the drawing page');
    }
    final path = input.photoLocalPath;
    final pendingUpload = path != null && path.isNotEmpty;
    final pin = DrawingPin(
      id: 'pin_${DateTime.now().microsecondsSinceEpoch}_${++_seq}',
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      drawingId: input.drawingId,
      page: input.page,
      x: input.x,
      y: input.y,
      issueId: input.issueId,
      issueTitle: input.issueTitle,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
      note: input.note,
      hasPhoto: pendingUpload,
      photoLocalPath: pendingUpload ? path : null,
      photoByteSizeBytes: input.photoByteSizeBytes,
      pendingPhotoUpload: pendingUpload,
    );
    _pins[pin.id] = pin;
    if (pendingUpload) {
      final localPath = path;
      final fileName = localPath.split('/').last;
      _outbox.enqueue(
        collection: FirestoreCollections.drawingPins,
        documentId: pin.id,
        operation: OutboxOperation.upload,
        payload: StorageUploadRequest(
          orgId: pin.orgId,
          projectId: pin.projectId,
          parentType: 'drawing_pins',
          parentId: pin.id,
          attachmentId: 'photo',
          fileName: fileName.isEmpty ? 'pin.jpg' : fileName,
          contentType: 'image/jpeg',
          localPath: localPath,
        ).toPayload(),
      );
    }
    _outbox.enqueue(
      collection: FirestoreCollections.drawingPins,
      documentId: pin.id,
      operation: OutboxOperation.create,
      payload: pin.toJson(),
    );
    await _persist();
    return pin;
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
        final current = _pins[entry.documentId];
        if (current != null) {
          _pins[entry.documentId] = current.copyWith(synced: true);
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
    final cur = _pins[entry.documentId];
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
    return entry;
  }

  Future<void> _flushUpload(OutboxEntry entry) async {
    final request = StorageUploadRequest.fromPayload(entry.payload);
    final url = await _storageUploader.upload(request);
    final cur = _pins[entry.documentId];
    if (cur == null) return;
    _pins[entry.documentId] = cur.copyWith(
      photoRemoteUrl: url,
      pendingPhotoUpload: false,
      hasPhoto: true,
    );
  }

  @override
  Future<int> pullRemote({required String projectId}) async {
    final remote = await _remotePull.pullPins(projectId);
    var changed = 0;
    for (final r in remote) {
      if (!_pins.containsKey(r.id)) {
        _pins[r.id] = DrawingPin(
          id: r.id,
          orgId: r.orgId,
          projectId: r.projectId,
          drawingId: r.drawingId,
          page: r.page,
          x: r.x,
          y: r.y,
          issueId: r.issueId,
          issueTitle: r.issueTitle,
          createdBy: r.createdBy,
          createdByName: r.createdByName,
          createdAt: r.createdAt,
          note: r.note,
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
    if (changed > 0) await _persistPinsOnly();
    return changed;
  }

  @override
  LocalCacheSlice estimateLocalCache() {
    var bytes = 0;
    var reclaimable = 0;
    var reclaimableCount = 0;
    var count = 0;
    for (final pin in _pins.values) {
      final path = pin.photoLocalPath;
      if (path == null || path.isEmpty) continue;
      count += 1;
      final size = LocalCacheEstimates.bytesFor(
        localPath: path,
        byteSizeBytes: pin.photoByteSizeBytes,
      );
      bytes += size;
      if (LocalCacheEstimates.isReclaimableLocalStub(
        localPath: path,
        remoteUrl: pin.photoRemoteUrl,
      )) {
        reclaimable += size;
        reclaimableCount += 1;
      }
    }
    return LocalCacheSlice(
      label: 'pins',
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
    for (final pin in _pins.values.toList()) {
      if (!LocalCacheEstimates.isReclaimableLocalStub(
        localPath: pin.photoLocalPath,
        remoteUrl: pin.photoRemoteUrl,
      )) {
        continue;
      }
      freed += LocalCacheEstimates.bytesFor(
        localPath: pin.photoLocalPath,
        byteSizeBytes: pin.photoByteSizeBytes,
      );
      _pins[pin.id] = pin.copyWith(clearPhotoLocalPath: true);
      changed = true;
    }
    if (changed) await _persist();
    return freed;
  }
}
