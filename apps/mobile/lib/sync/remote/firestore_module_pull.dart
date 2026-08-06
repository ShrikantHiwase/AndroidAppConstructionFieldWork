import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../features/documents/domain/document_models.dart';
import '../../features/dpr/domain/dpr_models.dart';
import '../../features/site_ops/domain/site_ops_models.dart';
import 'module_remote_pull.dart';

class FirestoreModulePull implements ModuleRemotePull {
  FirestoreModulePull({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<DailyProgressReport>> pullDprs(String projectId) async {
    final snap = await _db
        .collection(FirestoreCollections.dprs)
        .where('projectId', isEqualTo: projectId)
        .get();
    return snap.docs.map((d) {
      final data = Map<String, Object?>.from(d.data());
      data['id'] = data['id'] ?? d.id;
      return DailyProgressReport.fromJson(data);
    }).toList();
  }

  @override
  Future<List<SafetyRecord>> pullSafety(String projectId) async {
    return _pull(
      FirestoreCollections.safetyRecords,
      projectId,
      SafetyRecord.fromJson,
    );
  }

  @override
  Future<List<QaInspection>> pullInspections(String projectId) async {
    return _pull(
      FirestoreCollections.inspections,
      projectId,
      QaInspection.fromJson,
    );
  }

  @override
  Future<List<LabourMuster>> pullMuster(String projectId) async {
    return _pull(
      FirestoreCollections.attendanceLogs,
      projectId,
      LabourMuster.fromJson,
    );
  }

  @override
  Future<List<MaterialLog>> pullMaterials(String projectId) async {
    return _pull(
      FirestoreCollections.materialLogs,
      projectId,
      MaterialLog.fromJson,
    );
  }

  @override
  Future<List<DocFolder>> pullFolders(String projectId) async {
    return _pull(
      FirestoreCollections.folders,
      projectId,
      DocFolder.fromJson,
    );
  }

  @override
  Future<List<ProjectDocument>> pullDocuments(String projectId) async {
    return _pull(
      FirestoreCollections.documents,
      projectId,
      ProjectDocument.fromJson,
    );
  }

  @override
  Future<List<DrawingPin>> pullPins(String projectId) async {
    return _pull(
      FirestoreCollections.drawingPins,
      projectId,
      DrawingPin.fromJson,
    );
  }

  Future<List<T>> _pull<T>(
    String collection,
    String projectId,
    T Function(Map<String, Object?>) fromJson,
  ) async {
    final snap = await _db
        .collection(collection)
        .where('projectId', isEqualTo: projectId)
        .get();
    return snap.docs.map((d) {
      final data = Map<String, Object?>.from(d.data());
      data['id'] = data['id'] ?? d.id;
      return fromJson(data);
    }).toList();
  }
}
