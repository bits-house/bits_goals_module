import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure.dart';

/// Repository for managing [AnnualRevenueGoal] aggregates.
///
/// Implementations live in the data layer.
abstract class AnnualRevenueGoalRepository {
  /// Persists a new [AnnualRevenueGoal] aggregate.
  ///
  /// Throws:
  /// - [AnnualRevenueGoalRepFailure] for persistence errors
  ///
  /// Returns:
  /// - The persisted [AnnualRevenueGoal] aggregate
  ///
  /// Rules (for the implementer):
  /// - This operation MUST be atomic:
  ///     either the entire aggregate (all monthly goals) and logs are persisted,
  ///     or nothing is persisted at all.)
  /// - One year can have at most one annual revenue goal.
  ///     If an annual revenue goal for the specified year already exists,
  ///     a Failure MUST be thrown.
  /// - MUST write logs using [ActionLog] provided.
  // TODO: Use Either for return type to properly model failures instead of throwing them,
  //  to align with ADR-0015.
  Future<AnnualRevenueGoal> create({
    required AnnualRevenueGoal goal,
    required ActionLog log,
  });
}
