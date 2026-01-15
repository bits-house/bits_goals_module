import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'annual_revenue_goal_failure_reason.dart';

class AnnualRevenueGoalFailure extends Failure {
  final AnnualRevenueGoalFailureReason reason;

  const AnnualRevenueGoalFailure(this.reason);

  @override
  String toString() {
    return 'AnnualRevenueGoalFailure{reason: $reason}';
  }
}
