import 'package:bits_goals_module/src/core/application/ports/transaction/app_transaction.dart';
import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:dartz/dartz.dart';

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
  /// 2. **Pass the `tx` object.** All transaction-aware ports/repositories called within [action]
  ///    MUST receive and use the provided `tx` argument to ensure they write to the same
  ///    transactional boundary.
  /// 3. **Keep it fast.** Database transactions lock resources. Avoid calling external APIs
  ///    (HTTP requests) inside this block.
  /// 4. **Same Transaction Boundary.** All repositories invoked inside [action]
  ///    must operate on the same underlying database/connection.
  ///    This runner guarantees atomicity only within a single storage engine
  ///    (e.g. one SQL database or one Firestore instance).
  ///
  /// ---
  ///
  /// ### Example: Orchestrating Orders (Host App) and Goals (This Module)
  ///
  /// Orchestration happens in the host app.
  /// ```dart
  /// // 1. Orders Module / Host App (Application layer)
  /// class CreateOrderUseCase {
  ///   CreateOrderUseCase({
  ///     required this.transactionRunner,
  ///     required this.ordersRepository,
  ///     required this.applyGoalsProgressUseCase,
  ///   });
  ///
  ///   final TransactionRunner transactionRunner;
  ///   final OrdersRepository ordersRepository;
  ///   final ApplyGoalsProgressUseCase applyGoalsProgressUseCase;
  ///
  ///   Future<Either<Failure, Unit>> call(Order order) async {
  ///     // The Runner starts the atomic block
  ///     return transactionRunner.run((tx) async {
  ///       // Pass `tx` so all writes share the same boundary
  ///       final saveOrderResult = await ordersRepository.save(order, tx);
  ///       if (saveOrderResult.isLeft()) return saveOrderResult;
  ///
  ///       // 2. Goals Module (Application layer)
  ///       final params = ApplyGoalsProgressParams(
  ///         sellerId: order.sellerId,
  ///         amountCents: order.amountCents,
  ///         occurredAt: order.createdAt,
  ///         tx: tx,
  ///       );
  ///       ...
  ///     }); // <--- Commit happens only if Right(...) is returned.
  ///   }
  /// }
  /// ```
  ///
  /// ---
  ///
  /// ### Example: Orders save (Host App) with Repo + DataSource
  ///
  /// This example follows the same dependency flow as ADR-0014:
  /// `Application (port/repo contract) ← Data (repo impl) ← Infra (data source impl)`.
  ///
  /// **1) Application Port** (host app):
  /// ```dart
  /// abstract class OrdersRepository {
  ///   Future<Either<Failure, Unit>> save(Order order, AppTransaction tx);
  /// }
  /// ```
  ///
  /// **2) Data layer** (host app): repository implementation + data source contract
  ///
  /// Repo impl do its job and passes the tx down to the data source, with the serialized data.
  ///
  /// ```dart
  /// class OrdersRepositoryImpl implements OrdersRepository {
  ///   OrdersRepositoryImpl(this._ds);
  ///   final OrdersDataSource _ds;
  ///
  ///   @override
  ///   Future<Either<Failure, Unit>> save(Order order, AppTransaction tx) async {
  ///     try {
  ///       await _ds.putOrder(
  ///         id: order.id,
  ///         data: {
  ///           'sellerId': order.sellerId,
  ///           'amountCents': order.amountCents,
  ///           'createdAt': order.createdAt.toIso8601String(),
  ///         },
  ///         tx: tx,
  ///       );
  ///       return const Right(unit);
  ///     } catch (e) {
  ///       // Translate technical exceptions into Failures.
  ///       return Left(OrdersSaveFailure.unexpected(cause: e));
  ///     }
  ///   }
  /// }
  ///
  /// abstract class OrdersDataSource {
  ///   Future<void> putOrder({
  ///     required String id,
  ///     required Map<String, dynamic> data,
  ///     required AppTransaction tx,
  ///   });
  /// }
  /// ```
  ///
  /// **3) Infra layer** (host app): data source implementation using `AppTransaction`
  /// ```dart
  /// class TxOrdersDataSource implements OrdersDataSource {
  ///   @override
  ///   Future<void> putOrder({
  ///     required String id,
  ///     required Map<String, dynamic> data,
  ///     required AppTransaction tx,
  ///   }) {
  ///     return tx.put(resource: 'orders', id: id, data: data);
  ///   }
  /// }
  /// ```
  ///
  /// ---
  ///
  /// ### Example: ApplyGoalsProgressUseCase (This Module)
  ///
  /// Same idea, but inside this plugin. Note how the params contain **only primitives**
  /// from the host app and the shared `AppTransaction` to avoid circular dependencies.
  ///
  /// **1) Application layer**: Use Case + Params
  /// ```dart
  /// class ApplyGoalsProgressUseCase
  ///     implements ParamsUseCase<Unit, ApplyGoalsProgressParams> {
  ///   ApplyGoalsProgressUseCase({required this.repository});
  ///   final GoalsMonthlyProgressRepository repository;
  ///
  ///   @override
  ///   GoalsModulePermission get requiredPermission =>
  ///       GoalsModulePermission.none;
  ///
  ///   @override
  ///   Future<Either<Failure, Unit>> call(ApplyGoalsProgressParams params) async {
  ///     try {
  ///       final goalId = GoalId.from(params);
  ///
  ///       final existing = await repository.getById(goalId, params.tx);
  ///       if (existing == null) {
  ///         await repository.create(
  ///           id: goalId,
  ///           sellerId: params.sellerId,
  ///           monthKey: params.monthKey,
  ///           revenueCents: params.amountCents,
  ///           ordersCount: 1,
  ///           tx: params.tx,
  ///         );
  ///         return const Right(unit);
  ///       }
  ///
  ///       await repository.update(
  ///         id: goalId,
  ///         revenueCents: existing.revenueCents + params.amountCents,
  ///         ordersCount: existing.ordersCount + 1,
  ///         tx: params.tx,
  ///       );
  ///       ...
  ///     }
  ///   }
  /// }
  /// ```
  /// The same goes for the repository and data source implementations inside this module,
  /// which also receive the `AppTransaction` and use it to ensure all operations are part of
  /// the same transaction.
  Future<Either<Failure, T>> run<T>(
    Future<Either<Failure, T>> Function(AppTransaction tx) action,
  );
}
