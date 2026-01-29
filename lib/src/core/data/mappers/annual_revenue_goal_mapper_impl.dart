import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/application/ports/annual_revenue_goal_mapper.dart';

class AnnualRevenueGoalMapperImpl implements AnnualRevenueGoalMapper {
  const AnnualRevenueGoalMapperImpl();

  @override
  Map<String, dynamic> map(AnnualRevenueGoal goal) {
    return {
      'year': goal.year.value,
      'monthly_goals': goal.monthlyGoals
          .map(
            (g) => {
              'id': g.id.value,
              'month': g.month.value,
              'year': g.year.value,
              'target_cents': g.target.cents,
              'progress_cents': g.progress.cents,
            },
          )
          .toList(growable: false),
      'total_annual_target_cents': goal.totalAnnualTarget.cents,
    };
  }
}
