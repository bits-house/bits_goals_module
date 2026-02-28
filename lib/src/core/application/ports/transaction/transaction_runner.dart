import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';

/// [TransactionRunner] defines the contract responsible for executing a unit of work
/// within a transactional boundary.
///
/// It orchestrates the lifecycle of a transaction,
/// ensuring that all operations executed through the provided
/// [AppTransaction] instance are atomic and consistent, even across multiple modules
/// and use cases.
///
/// The implementation is responsible for:
/// - starting the transaction
/// - providing the transactional context
/// - committing on success
/// - rolling back on failure
///
/// This abstraction allows application use-cases to remain
/// persistence-agnostic, as long they share the same data source.
///
/// The underlying implementation may map to:
///
/// - Firestore transactions
/// - SQL database transactions
/// - In-memory transactional contexts
///
/// ---
///
/// ### Why use this?
/// - **Cross-Module Consistency:** Allows you to update an *Order* (Module A/main app) and
///   a *Goal* (Module B) in the same split second. Either both update, or neither does.
/// - **Decoupling:** One module can update its data without needing to know about the other
///   module's implementation details. Use Cases don't need to know infrastructure details.
/// - **Testability:** You can easily mock this runner to execute actions immediately
///   without a real database during unit tests.
///
/// ---
///
/// ### Implementation
/// The concrete implementation (in this module's Infrastructure Layer) should handle the details
/// like:
/// - Firestore: `firestore.runTransaction(...)`
/// - SQL: `db.transaction(...)`
/// - Testing: `FakeTransactionRunner`
abstract class TransactionRunner {
  /// [run] executes a unit of work within a transactional boundary.
  ///
  /// This method creates a temporary [AppTransaction] context and passes it
  /// to your [action].
  ///
  /// ### Critical Rules:
  /// 1. **Do not use `this` runner inside the action.** The action is already running inside
  ///    a `this` runner.
  /// 2. **Pass the `sharedTransaction` object.** All transaction-aware ports called within [action]
  ///    MUST receive and use the provided `sharedTransaction` argument to ensure they write to the same
  ///    transactional boundary.
  /// 3. **Same Transaction Boundary.** All ports invoked inside [action]
  ///    must operate on the same underlying database/connection.
  ///    This runner guarantees atomicity only within a single storage engine
  ///    (e.g. one SQL database or one Firestore instance).
  /// 4. **Retry safety.** Some implementations (e.g. Firestore) may retry the transactional
  ///    callback on contention. Keep the action idempotent and free of side effects,
  ///    don’t do things inside the transaction that the database/service cannot repeat, such as:
  ///    - HTTP calls (e.g., updates to external services)
  ///    - Writing to another database
  ///    - Publishing events
  /// 5. **Transaction Outcome:**
  ///     If the action throws:
  ///       - the transaction MUST be rolled back by the implementation
  ///       - the exception is rethrown to the caller/use case as-is
  ///
  /// ---
  ///
  /// ### Usage Example:
  /// ```dart
  /// final T result = await transactionRunner.run((sharedTransaction) async {
  ///
  ///   // (Host App repository method - updateOrder)
  ///   await ordersWriter.updateOrder(orderId, updatedOrder, sharedTransaction);
  ///
  ///   // (Repository method from Goals Module, example only - updateGoal)
  ///   await goalsProgressUpdater.updateGoal(goalId, updatedGoal, sharedTransaction);
  ///
  ///   return someResult;
  /// });
  /// ```
  /// In this example, [updateOrder] is a data-layer repository method that accepts
  /// a [sharedTransaction] to execute validations and writes within a single
  /// transaction boundary, without calling other infrastructure methods.
  ///
  /// This method may throw a generic [Exception] (e.g., an unexpected error) or a
  /// domain-specific [Failure] (e.g., [OrderNotFoundFailure] thrown by the repository) to be
  /// handled by the use case. In either scenario, the transaction is automatically rolled back,
  /// and the original exception or failure is rethrown as-is.
  Future<T> run<T>(
    Future<T> Function(AppTransaction sharedTransaction) action,
  );
}
