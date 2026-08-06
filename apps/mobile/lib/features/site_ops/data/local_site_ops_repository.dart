import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

class LocalSiteOpsRepository implements SiteOpsRepository {
  LocalSiteOpsRepository(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _safetyKey = 'siteops.safety';
  static const _inspKey = 'siteops.inspections';
  static const _musterKey = 'siteops.muster';
  static const _matKey = 'siteops.materials';

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
    _safetyC.add(_safety.values.toList());
    _inspC.add(_inspections.values.toList());
    _musterC.add(_muster.values.toList());
    _matC.add(_materials.values.toList());
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
  }) async {
    _ensure(session);
    if (title.trim().isEmpty) throw SiteOpsException('Title required');
    final photoRequired = kind != SafetyKind.toolboxTalk;
    if (photoRequired && !hasPhoto) {
      throw SiteOpsException('Photo evidence required for ${kind.name}');
    }
    final now = DateTime.now().toUtc();
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
      hasPhoto: hasPhoto,
    );
    _safety[record.id] = record;
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
    final insp = QaInspection(
      id: _id('insp'),
      orgId: session.activeProject.orgId,
      projectId: session.activeProjectId,
      title: title.trim(),
      items: items,
      createdBy: session.user.id,
      createdByName: session.user.displayName,
      createdAt: DateTime.now().toUtc(),
    );
    _inspections[insp.id] = insp;
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
    await _persist();
    return log;
  }
}
