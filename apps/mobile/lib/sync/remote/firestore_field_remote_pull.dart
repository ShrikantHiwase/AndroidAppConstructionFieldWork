import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../features/issues/domain/issue_models.dart';
import 'field_remote_pull.dart';

class FirestoreFieldRemotePull implements FieldRemotePull {
  FirestoreFieldRemotePull({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Issue>> pullIssues(String projectId) async {
    final snap = await _db
        .collection(FirestoreCollections.issues)
        .where('projectId', isEqualTo: projectId)
        .get();
    return snap.docs
        .map((d) {
          final data = Map<String, Object?>.from(d.data());
          data['id'] = data['id'] ?? d.id;
          return Issue.fromJson(data);
        })
        .toList();
  }

  @override
  Future<List<Rfi>> pullRfis(String projectId) async {
    final snap = await _db
        .collection(FirestoreCollections.rfis)
        .where('projectId', isEqualTo: projectId)
        .get();
    return snap.docs
        .map((d) {
          final data = Map<String, Object?>.from(d.data());
          data['id'] = data['id'] ?? d.id;
          return Rfi.fromJson(data);
        })
        .toList();
  }
}
