import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransactionFirestoreImpl implements AppTransaction {
  final Transaction _transaction;
  final FirebaseFirestore _firestore;

  AppTransactionFirestoreImpl({
    required Transaction transaction,
    required FirebaseFirestore firestore,
  })  : _transaction = transaction,
        _firestore = firestore;

  DocumentReference _getRef(String resource, Object id) {
    return _firestore.collection(resource).doc(id as String);
  }

  @override
  Future<void> delete({
    required String resource,
    required Object id,
  }) async {
    final ref = _getRef(resource, id);
    _transaction.delete(ref);
  }

  @override
  Future<void> put({
    required String resource,
    required Object id,
    required Map<String, dynamic> data,
  }) async {
    final ref = _getRef(resource, id);
    _transaction.set(ref, data);
  }

  @override
  Future<void> update({
    required String resource,
    required Object id,
    required Map<String, dynamic> data,
  }) async {
    final ref = _getRef(resource, id);
    _transaction.update(ref, data);
  }

  @override
  Future<Map<String, dynamic>?> get({
    required String resource,
    required Object id,
  }) async {
    final ref = _getRef(resource, id);
    final snapshot = await _transaction.get(ref);
    if (!snapshot.exists) {
      return null;
    }
    return snapshot.data() as Map<String, dynamic>?;
  }
}
