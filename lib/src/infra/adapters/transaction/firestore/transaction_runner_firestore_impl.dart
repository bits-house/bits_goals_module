import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';
import 'package:bits_goals_module/src/core/application/ports/transaction/transaction_runner.dart';
import 'package:bits_goals_module/src/infra/adapters/transaction/firestore/app_transaction_firestore_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionRunnerFirestoreImpl implements TransactionRunner {
  final FirebaseFirestore _firestore;

  TransactionRunnerFirestoreImpl({
    required FirebaseFirestore firestoreInstance,
  }) : _firestore = firestoreInstance;

  @override
  Future<T> run<T>(
    Future<T> Function(AppTransaction sharedTransaction) action,
  ) async {
    final result = await _firestore.runTransaction((transaction) async {
      /// 1. Instantiate the `AppTransaction` implementation that will be passed to the [action].
      final firestoreSharedTransaction = AppTransactionFirestoreImpl(
        transaction: transaction,
        firestore: _firestore,
      );

      /// 2. Execute the [action]. Usually provided by an use case, which contains transaction
      /// operations from different modules/apps.
      ///
      /// The use case will perform its operations using the AppTransaction interface, but
      /// under the hood, all calls will be executed within the same Firestore transaction,
      /// ensuring atomicity and consistency across all operations.
      ///
      /// if any operation within the [action] fails (throws), the entire transaction will be
      /// rolled back by Firestore, and the error will be propagated up to the caller of
      /// this `run` method.
      return await action(firestoreSharedTransaction);
    });

    /// 3. Return the result of the transaction. If the transaction was successful, this will be
    /// the value returned by the [action]. If the transaction failed, an exception or a domain-specific
    /// failure from data layer functions called inside [runTransaction] will be thrown
    /// and this line will not be reached.
    return result;
  }
}
