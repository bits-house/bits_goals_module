import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure.dart';
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
  ///     either the entire aggregate (annual + monthly goals) is persisted,
  ///     or nothing is persisted at all.)
  /// - One year can have at most one annual revenue goal.
  ///     If an annual revenue goal for the specified year already exists,
  ///     an Failure MUST be thrown.
  Future<AnnualRevenueGoal> create(AnnualRevenueGoal goal);

  /// Gets the current year, to not get year from local offline system clock, so
  ///
  ///
  /// Throws:
  /// - [RepositoryFailure]
  ///
  /// Returns:
  /// - The current year as a [Year] value object.
  Future<Year> getCurrentYear();
}
