import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';

/// Domain-level port used to create an audit/log snapshot from a domain entity.
abstract class AnnualRevenueGoalMapper {
  Map<String, dynamic> map(AnnualRevenueGoal goal);
}
