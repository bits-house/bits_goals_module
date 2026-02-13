import 'package:bits_goals_module/src/core/data/exceptions/rate_limit_exceeded_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';

/// Remote data source for managing annual revenue goals.
///
/// Implementations interact with remote services (e.g., REST API, Firestore, etc.)
abstract class AnnualRevenueGoalRemoteDataSource {
  /// Persists a list of [MonthlyRevenueGoalRemoteModel].
  ///
  /// Throws:
  /// - [ServerExceptionReason.conflict] if monthly goals for the specified year already exist
  /// - [ServerExceptionReason.permissionDenied] if permission is denied
  /// - [RateLimitExceededException] if the rate limit for this operation is exceeded
  /// - [ServerExceptionReason] for other server errors
  ///
  /// Rules (for the implementer):
  /// - This operation MUST be atomic: either all monthly goals and logs are persisted,
  ///     or nothing is persisted at all.
  /// - MUST validate if monthly goals for the specified year already exist atomically,
  ///     with the write operation (it cannot be a separate read operation).
  /// - MUST write logs using the [ActionLogModel] provided with the operation.
  /// - MUST enforce rate limiting to avoid abuse/bugs that could cause excessive writes.
  Future<void> createMonthlyGoalsForYear({
    required int year,
    required List<MonthlyRevenueGoalRemoteModel> goals,
    required ActionLogModel log,
  });
}
