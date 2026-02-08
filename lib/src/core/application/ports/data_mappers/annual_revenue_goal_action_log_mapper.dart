import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';

/// Port used to create an audit/log snapshot from a domain entity.
///
/// Implementations live in the data layer.
abstract class AnnualRevenueGoalActionLogMapper {
  Map<String, dynamic> map(AnnualRevenueGoal goal);
}
