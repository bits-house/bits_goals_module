import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';

/// Repository for managing [AnnualRevenueGoal] aggregates.
///
/// Implementations live in the data layer.
abstract class AnnualRevenueGoalRepository {
  /// Persists a new [AnnualRevenueGoal] aggregate.
  ///
  /// Throws:
  /// - [RepositoryFailure] for persistence errors
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
  Future<AnnualRevenueGoal> create({
    required AnnualRevenueGoal goal,
    required ActionLog log,
  });

  /// Gets the current year, to not get year from local offline system clock.
  ///
  /// Throws:
  /// - [RepositoryFailure]
  ///
  /// Returns:
  /// - The current year as a [Year] value object.
  Future<Year> getCurrentYear();
}
