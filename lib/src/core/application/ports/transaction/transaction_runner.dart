import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';

/// [TransactionRunner] defines the contract responsible for executing a unit of work
/// within a transactional boundary.
///
/// It orchestrates the lifecycle of a transaction,
/// ensuring that all operations executed through the provided
/// [AppTransaction] instance are:
///
/// - atomic
/// - consistent
/// - isolated
///
/// The implementation is responsible for:
/// - starting the transaction
/// - providing the transactional context
/// - committing on success
/// - rolling back on failure
///
/// This abstraction allows application use-cases to remain
/// persistence-agnostic while still guaranteeing transactional
/// consistency and atomicity across multiple operations and modules.
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
/// ### Implementation Details
/// The concrete implementation (in the Infrastructure Layer) handles the messy details:
/// - Firestore: `firestore.runTransaction(...)`
/// - SQL: `db.transaction(...)`
/// - Testing: `FakeTransactionRunner`
abstract class TransactionRunner {
  /// Executes a unit of work within a transactional boundary.
  ///
  /// This method creates a temporary [AppTransaction] context and passes it
  /// to your [action].
  ///
  /// ### Critical Rules:
  /// 1. **Do not use `this` runner inside the action.** The action is already running inside one.
  /// 2. **Pass the `sharedTransaction` object.** All transaction-aware ports called within [action]
  ///    MUST receive and use the provided `sharedTransaction` argument to ensure they write to the same
  ///    transactional boundary.
  /// 3. **Keep it fast.** Database transactions lock resources. Avoid calling external APIs
  ///    (HTTP requests) inside this block.
  /// 4. **Same Transaction Boundary.** All ports invoked inside [action]
  ///    must operate on the same underlying database/connection.
  ///    This runner guarantees atomicity only within a single storage engine
  ///    (e.g. one SQL database or one Firestore instance).
  /// 5. **Retry safety.** Some implementations (e.g. Firestore) may retry the transactional
  ///    callback on contention. Keep the action idempotent and free of side effects,
  ///    don’t do things inside the transaction that you can’t safely repeat, such as:
  ///    - HTTP calls (charge credit card, send email/push)
  ///    - Writing to another database/service
  ///    - Publishing events
  /// 6. **Transaction Outcome:**
  ///
  ///     If the action throws:
  ///       - the transaction MUST be rolled back by the implementation
  ///       - the exception is rethrown to the caller/use case
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// final result = await transactionRunner.run((sharedTransaction) async {
  ///   await ordersWriter.updateOrder(orderId, updatedOrder, sharedTransaction);
  ///   await goalsProgressUpdater.updateGoal(goalId, updatedGoal, sharedTransaction);
  ///   return someResult;
  /// });
  /// ```
  Future<T> run<T>(
    Future<T> Function(AppTransaction sharedTransaction) action,
  );
}
