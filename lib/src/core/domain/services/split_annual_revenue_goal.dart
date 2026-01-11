import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';

class SplitAnnualRevenueGoal {
  /// Generates 12 monthly revenue goals by distributing the annual value,
  /// with progress initialized to zero, one for each month of the specified year.
  /// Usage:
  ///
  ///```dart
  /// final split = SplitAnnualRevenueGoal();
  /// final monthlyGoals = split(
  ///   year: Year(2026),
  ///  annualGoalTarget: Money.fromCents(120),
  /// );
  /// // This results in 12 MonthlyRevenueGoal instances, each with a target of
  /// // Money.fromCents(10) and progress of Money.fromCents(0)
  /// // for months January to December of the year 2026.
  /// ```
  const SplitAnnualRevenueGoal();

  List<MonthlyRevenueGoal> call({
    required Year year,
    required Money annualGoalTarget,
  }) {
    final splitAmounts = annualGoalTarget.split(12);

    return List.generate(12, (index) {
      return MonthlyRevenueGoal.create(
        year: year,
        month: Month.fromInt(index + 1),
        target: splitAmounts[index],
      );
    });
  }
}
