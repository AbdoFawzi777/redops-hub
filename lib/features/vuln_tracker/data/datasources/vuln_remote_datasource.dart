import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vulnerability.dart';
import '../models/vuln_model.dart';

class VulnRemoteDataSource {
  VulnRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('vulnerabilities');

  Stream<List<Vulnerability>> watchAll() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return _fromFirestore(doc.data());
      }).toList();
    });
  }

  Future<List<Vulnerability>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => _fromFirestore(doc.data())).toList();
  }

  Future<void> save(Vulnerability vulnerability) async {
    final data = _toFirestore(vulnerability);
    await _collection.doc(vulnerability.id).set(data);
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  Vulnerability _fromFirestore(Map<String, dynamic> data) {
    final model = VulnModel(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      severityIndex: data['severityIndex'] as int,
      statusIndex: data['statusIndex'] as int,
      typeIndex: data['typeIndex'] as int,
      projectName: data['projectName'] as String,
      cveId: data['cveId'] as String?,
      assignedTo: data['assignedTo'] as String?,
      reproductionSteps: data['reproductionSteps'] as String?,
      remediationCode: data['remediationCode'] as String?,
      pocCode: data['pocCode'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      commentsJson: (data['commentsJson'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      createdAtMs: data['createdAtMs'] as int,
      updatedAtMs: data['updatedAtMs'] as int,
    );
    return model.toEntity();
  }

  Map<String, dynamic> _toFirestore(Vulnerability vulnerability) {
    final model = VulnModel.fromEntity(vulnerability);
    return {
      'id': model.id,
      'title': model.title,
      'description': model.description,
      'severityIndex': model.severityIndex,
      'statusIndex': model.statusIndex,
      'typeIndex': model.typeIndex,
      'projectName': model.projectName,
      'cveId': model.cveId,
      'assignedTo': model.assignedTo,
      'reproductionSteps': model.reproductionSteps,
      'remediationCode': model.remediationCode,
      'pocCode': model.pocCode,
      'tags': model.tags,
      'commentsJson': model.commentsJson,
      'createdAtMs': model.createdAtMs,
      'updatedAtMs': model.updatedAtMs,
    };
  }
}
