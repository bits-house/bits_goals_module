import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:equatable/equatable.dart';

/// Represents a global annual revenue goal.
///
/// This is an Aggregate Root
class AnnualRevenueGoal extends Equatable {
  /// The year this goal is set for.
  /// Natural key for the aggregate.
  final Year _year;

  /// 12 [MonthlyRevenueGoal], one for each month of the year.
  final List<MonthlyRevenueGoal> _monthlyGoals;

  // ========================
  // Constructor
  // ========================

  /// Private constructor to enforce invariants
  const AnnualRevenueGoal._({
    required Year year,
    required List<MonthlyRevenueGoal> monthlyGoals,
  })  : _year = year,
        _monthlyGoals = monthlyGoals;

  /// Factory constructor that validates all domain invariants
  /// before creating an instance of [AnnualRevenueGoal].
  factory AnnualRevenueGoal.create({
    required Year year,
    required List<MonthlyRevenueGoal> monthlyGoals,
  }) {
    final goals = List<MonthlyRevenueGoal>.of(monthlyGoals);

    _validateMonthsCount(goals);
    _validateUniqueMonths(goals);
    _validateYearsConsistency(goals, year);
    _validateGoalTargets(goals);

    goals.sort(
      (a, b) => a.month.value.compareTo(b.month.value),
    );

    return AnnualRevenueGoal._(
      year: year,
      monthlyGoals: List<MonthlyRevenueGoal>.unmodifiable(goals),
    );
  }

  // =========================
  // Getters
  // =========================

  List<MonthlyRevenueGoal> get monthlyGoals => List.unmodifiable(_monthlyGoals);

  Year get year => Year.fromInt(_year.value);

  /// Total annual target is calculated as the sum of
  /// already-rounded monthly targets.
  Money get totalAnnualTarget {
    final totalCents = _monthlyGoals
        .map((g) => g.target.cents)
        .reduce((value, element) => value + element);

    return Money.fromCents(totalCents);
  }

  // =========================
  // Domain Validations
  // =========================

  static void _validateMonthsCount(List<MonthlyRevenueGoal> goals) {
    if (goals.length != 12) {
      throw const AnnualRevenueGoalFailure(
        AnnualRevenueGoalFailureReason.invalidMonthsCount,
      );
    }
  }

  static void _validateUniqueMonths(List<MonthlyRevenueGoal> goals) {
    final uniqueMonths = goals.map((g) => g.month).toSet();

    if (uniqueMonths.length != 12) {
      throw const AnnualRevenueGoalFailure(
        AnnualRevenueGoalFailureReason.duplicateMonth,
      );
    }
  }

  static void _validateYearsConsistency(
    List<MonthlyRevenueGoal> goals,
    Year year,
  ) {
    /// All monthly goals must belong to the same year as the annual goal
    final hasInvalidYear = goals.any((g) => g.year != year);

    if (hasInvalidYear) {
      throw const AnnualRevenueGoalFailure(
        AnnualRevenueGoalFailureReason.yearMismatch,
      );
    }
  }

  static void _validateGoalTargets(List<MonthlyRevenueGoal> goals) {
    /// Negative or zero monthly goals are not allowed
    final hasInvalidMonthlyGoal = goals.any((g) => g.target.cents <= 0);

    if (hasInvalidMonthlyGoal) {
      throw const AnnualRevenueGoalFailure(
        AnnualRevenueGoalFailureReason.invalidMonthlyRevenueGoal,
      );
    }

    final totalAnnualTargetCents = goals
        .map((g) => g.target.cents)
        .reduce((value, element) => value + element);

    if (totalAnnualTargetCents <= 0) {
      throw const AnnualRevenueGoalFailure(
        AnnualRevenueGoalFailureReason.zeroOrNegativeAnnualGoal,
      );
    }
  }

  // =========================
  // Equatable Overrides
  // =========================

  @override
  List<Object?> get props => [
        _year,
        _monthlyGoals,
      ];

  @override
  bool get stringify => true;
}
