import 'package:bits_goals_module/src/core/data/models/annual_revenue_goal_meta_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/application/ports/annual_revenue_goal_action_log_mapper.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';

class AnnualRevenueGoalActionLogMapperImpl
    implements AnnualRevenueGoalActionLogMapper {
  const AnnualRevenueGoalActionLogMapperImpl();

  @override
  Map<String, dynamic> map(AnnualRevenueGoal goal) {
    final monthlyGoals = goal.monthlyGoals
        .map(
          (g) => {
            MonthlyRevenueGoalRemoteSchemaV1.uuidV7: g.id.value,
            MonthlyRevenueGoalRemoteSchemaV1.month: g.month.value,
            MonthlyRevenueGoalRemoteSchemaV1.year: g.year.value,
            MonthlyRevenueGoalRemoteSchemaV1.targetCents: g.target.cents,
            MonthlyRevenueGoalRemoteSchemaV1.progressCents: g.progress.cents,
            // Current schema
            MonthlyRevenueGoalRemoteSchemaV1.schemaVersion: 1,
          },
        )
        .toList(growable: false);

    return {
      AnnualRevenueGoalMetaRemoteSchemaV1.year: goal.year.value,
      // Current schema
      AnnualRevenueGoalMetaRemoteSchemaV1.version: 1,
      // Nested monthly goals
      'monthly_goals': monthlyGoals,
    };
  }
}
