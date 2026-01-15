import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';

/// Remote data source for managing annual revenue goals.
///
/// Implementations interact with remote services (e.g., REST API, Firestore, etc.)
abstract class AnnualRevenueGoalRemoteDataSource {
  /// Persists a list of [MonthlyRevenueGoalRemoteModel].
  ///
  /// Throws:
  /// - [ServerExceptionType.conflict] if monthly goals for the specified year already exist
  /// - [ServerExceptionType.permissionDenied] if permission is denied
  /// - [ServerException] for other server errors
  ///
  /// Rules (for the implementer):
  /// - This operation MUST be atomic: either all monthly goals are persisted,
  ///     or nothing is persisted at all.
  /// - MUST validate if monthly goals for the specified year already exist atomically,
  ///     with the write operation (it cannot be a separate read operation).
  Future<void> createMonthlyGoalsForYear({
    required int year,
    required List<MonthlyRevenueGoalRemoteModel> goals,
  });
}
