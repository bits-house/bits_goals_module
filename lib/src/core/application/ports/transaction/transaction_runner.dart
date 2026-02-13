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
  /// 2. **Pass the `tx` object.** All repositories called within [action] MUST receive
  ///    and use the provided `tx` argument to ensure they write to the same temporary buffer.
  /// 3. **Keep it fast.** Database transactions lock resources. Avoid calling external APIs
  ///    (HTTP requests) inside this block.
  /// 4. **Same Transaction Boundary.** All repositories invoked inside [action]
  ///    must operate on the same underlying database/connection.
  ///    This runner guarantees atomicity only within a single storage engine
  ///    (e.g. one SQL database or one Firestore instance).
  ///
  /// ---
  ///
  /// ### Example: Orchestrating Orders and Goals
  /// ```dart
  /// // 1. Orders Module (or main app):
  /// class CreateOrderUseCase {
  ///   // ... dependencies injected
  ///
  ///   Future<void> call(Order order) async {
  ///     // The Runner starts the atomic block
  ///     await transactionRunner.run((tx) async {
  ///
  ///       // We pass 'tx' so the repo writes to the transaction buffer
  ///       await ordersRepository.save(order, tx);
  ///
  ///       // 2. Module B: Update the Goals
  ///       // We calculate and save the goals progress atomically
  ///       final goalsUpdate = GoalsUpdateObject.create(params...);
  ///       await goalsUpdatePort.applyProgress(goalsUpdate, tx);
  ///
  ///     }); // <--- Automatic Commit happens here if no errors occur.
  ///   }
  /// }
  /// ```
  ///
  /// ---
  ///
  /// ### Example Implementations (Infra)
  ///
  /// Orders repository persists its own aggregate:
  /// ```dart
  /// class OrdersRepositoryImpl implements OrdersRepository {
  ///   @override
  ///   Future<void> save(Order order, AppTransaction tx) async {
  ///     await tx.put(
  ///       resource: 'orders',
  ///       id: order.id,
  ///       data: {
  ///         'sellerId': order.sellerId,
  ///         'amount': order.amount,
  ///         'productId': order.productId,
  ///         'createdAt': order.createdAt.toIso8601String(),
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// Goals module increments its own projection:
  /// ```dart
  /// class GoalsUpdatePortImpl implements GoalsUpdatePort {
  ///   @override
  ///   Future<void> applyProgress(
  ///     GoalsUpdateObject update,
  ///     AppTransaction tx,
  ///   ) async {
  ///     final monthKey =
  ///         '${update.date.year}${update.date.month.toString().padLeft(2, '0')}';
  ///
  ///     final goalId = '${update.sellerId}_$monthKey';
  ///
  ///     final existing = await tx.get(
  ///       resource: 'goals_monthly',
  ///       id: goalId,
  ///     );
  ///
  ///     if (existing == null) {
  ///       await tx.put(
  ///         resource: 'goals_monthly',
  ///         id: goalId,
  ///         data: {
  ///           'sellerId': update.sellerId,
  ///           'month': monthKey,
  ///           'revenue': update.amount,
  ///           'ordersCount': 1,
  ///         },
  ///       );
  ///       return;
  ///     }
  ///
  ///     await tx.update(
  ///       resource: 'goals_monthly',
  ///       id: goalId,
  ///       data: {
  ///         'revenue': (existing['revenue'] ?? 0) + update.amount,
  ///         'ordersCount': (existing['ordersCount'] ?? 0) + 1,
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// ---
  ///
  /// Returns the result of [action] (of type [T]) if committed successfully.
  Future<T> run<T>(
    Future<T> Function(AppTransaction tx) action,
  );
}
