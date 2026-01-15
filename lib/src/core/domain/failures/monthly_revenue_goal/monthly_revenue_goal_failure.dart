import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';

class MonthlyRevenueGoalFailure extends Failure {
  final MonthlyRevenueGoalFailureReason reason;

  const MonthlyRevenueGoalFailure(this.reason);

  @override
  String toString() {
    return 'MonthlyRevenueGoalFailure{reason: $reason}';
  }
}
