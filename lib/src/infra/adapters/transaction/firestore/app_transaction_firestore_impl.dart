import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransactionFirestoreImpl implements AppTransaction {
  final Transaction _sdkTransaction;
  final FirebaseFirestore _firestore;

  AppTransactionFirestoreImpl({
    required Transaction sdkTransaction,
    required FirebaseFirestore firestore,
  })  : _sdkTransaction = sdkTransaction,
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
    _sdkTransaction.delete(ref);
  }

  @override
  Future<void> put({
    required String resource,
    required Object id,
    required Map<String, dynamic> data,
  }) async {
    final ref = _getRef(resource, id);
    _sdkTransaction.set(ref, data);
  }

  @override
  Future<void> update({
    required String resource,
    required Object id,
    required Map<String, dynamic> data,
  }) async {
    final ref = _getRef(resource, id);
    _sdkTransaction.update(ref, data);
  }

  @override
  Future<Map<String, dynamic>?> get({
    required String resource,
    required Object id,
  }) async {
    final ref = _getRef(resource, id);
    final snapshot = await _sdkTransaction.get(ref);
    if (!snapshot.exists) {
      return null;
    }
    return snapshot.data() as Map<String, dynamic>?;
  }
}
