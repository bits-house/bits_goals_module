import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';
import 'package:bits_goals_module/src/core/application/ports/transaction/transaction_runner.dart';
import 'package:bits_goals_module/src/infra/adapters/transaction/firestore/app_transaction_firestore_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A Firestore-specific implementation of [TransactionRunner].
///
/// This class acts as a bridge between the application's generic transaction
/// interface and Firebase Firestore's transaction mechanism. It ensures that
/// multiple operations across different modules can be executed atomically.
class TransactionRunnerFirestoreImpl implements TransactionRunner {
  final FirebaseFirestore _firestore;

  TransactionRunnerFirestoreImpl({
    required FirebaseFirestore firestoreInstance,
  }) : _firestore = firestoreInstance;

  /// Executes the provided [action] within a single Firestore transaction.
  ///
  /// The [action] is usually provided by a use case and contains operations from
  /// different modules or apps. It receives an [AppTransaction] interface, but
  /// under the hood, all calls are routed to the same Firestore transaction,
  /// ensuring atomicity and data consistency.
  ///
  /// ### Success & Failure:
  /// * **Success:** If the transaction succeeds, it returns the result of type [T]
  ///   produced by the [action].
  /// * **Failure:** If any operation within the [action] fails (throws),
  ///   the entire transaction is rolled back by Firestore. The exception or
  ///   domain-specific failure will be propagated up to the caller of this method.
  @override
  Future<T> run<T>(
    Future<T> Function(AppTransaction sharedTransaction) action,
  ) async {
    return await _firestore.runTransaction((fireTransaction) async {
      // 1. Instantiate [AppTransactionFirestoreImpl]. This wraps the Firestore-specific
      // transaction into the generic [AppTransaction] interface expected by the [action].
      final sharedTransactionWrapper = AppTransactionFirestoreImpl(
        transaction: fireTransaction,
        firestore: _firestore,
      );

      // 2. Execute the action with the shared transaction instance.
      return await action(sharedTransactionWrapper);
    });
  }
}
