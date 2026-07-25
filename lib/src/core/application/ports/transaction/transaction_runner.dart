import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';

/// [TransactionRunner] defines the contract responsible for executing a unit of work
/// within a transactional boundary.
///
/// It orchestrates the lifecycle of a transaction, ensuring that all operations executed
/// through [AppTransaction] instance are atomic and consistent, even across
/// multiple modules and use cases.
///
/// The implementation is responsible for:
/// - starting the transaction
/// - providing the transactional context
/// - committing on success
/// - rolling back on failure
///
/// The underlying implementation may map to:
/// - Firestore transactions: firestore.runTransaction(...)
/// - In-memory transactional contexts: for testing purposes (e.g., FakeTransactionRunner)
/// - Any other transactional mechanism provided by the host application or infrastructure.
///
/// Why use this?
/// - **Cross-Module Consistency:** Allows you to update an *Order* (e.g. Main App) and
///   a *Goal* (this module) in the same split second. Either both update, or neither does.
/// - **Decoupling:** One module can update its data without needing to know about the other
///   module's implementation details. The caller doesn't need to know infrastructure details.
abstract class TransactionRunner {
  /// [run] executes a unit of work within a transactional boundary.
  ///
  /// This method creates a temporary [AppTransaction] and passes it
  /// to your [action].
  ///
  /// ### Critical Rules:
  /// 1. **Single Data Source:** All methods within [action] must share the same
  ///    database connection. Atomicity is guaranteed only within a single storage engine
  ///    (e.g., both need to write to the same Firestore instance or SQL database).
  /// 2. **Retry safety.** Some implementations (e.g. Firestore) may retry the transactional
  ///    callback on contention. Keep the action idempotent and free of side effects,
  ///    don’t do things inside the [action] that the database/service cannot repeat, such as:
  ///    - HTTP calls (e.g., updates to external services)
  ///    - Writing to another database
  ///    - Publishing events
  ///    (reading operations are generally safe, but be mindful of side effects from reads as well)
  /// 3. **Transaction Outcome:**
  ///     If the action throws:
  ///       - the transaction MUST be rolled back by the implementation (e.g., Firestore automatically rolls back on exceptions)
  ///       - the exception is rethrown to the caller/use case as-is
  /// 4. **Use Only The `sharedTransaction`.** All transaction-aware methods called within [action]
  ///     MUST receive and use the provided `sharedTransaction` argument to ensure atomicity.
  ///
  /// ---
  ///
  /// Example (Host App):
  ///
  /// ```dart
  /// final result = await transactionRunner.run((sharedTransaction) async {
  ///
  ///   await hostAppRepository.updateOrder(updatedOrder, sharedTransaction);
  ///   await updateGoalsFromOrder(updatedOrder, sharedTransaction);
  ///
  ///   return someResult;
  /// });
  /// ```
  ///
  /// In this example,
  ///
  /// [transactionRunner] is executed within a Host App use case (Application layer),
  /// orchestrating both an order update and the corresponding goals progress update
  /// (from the Goals Module) within a single transactional boundary. If any of the two updates fail,
  /// both operations are rolled back, ensuring data consistency across modules.
  ///
  /// [updateOrder] is a repository method (implemented in the host app's data layer) that accepts
  /// a [sharedTransaction] to execute the persistence logic within the transaction context.
  ///
  /// [updateGoalsFromOrder] is a example use case from the Goals Module that also accepts the
  /// [sharedTransaction] to ensure its operations are part of the same transaction.
  ///
  /// [run] may throw a generic [Exception] (e.g., an unexpected error) or a domain-specific [Failure]
  /// (e.g., [OrderNotFoundFailure] thrown by the repository). In either scenario, the transaction
  /// is automatically rolled back, and the original exception or failure is rethrown as-is.
  ///
  /// The caller (e.g., Host App use case) is responsible for handling the exception/failure and providing
  /// appropriate feedback to the user, including failures from Goals Module, from the use case(s) it
  /// calls within the transaction.
  Future<T> run<T>(
    Future<T> Function(AppTransaction sharedTransaction) action,
  );
}
