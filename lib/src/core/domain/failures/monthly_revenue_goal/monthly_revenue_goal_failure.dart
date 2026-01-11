import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';
import 'package:equatable/equatable.dart';

class MonthlyRevenueGoalFailure extends Failure with EquatableMixin {
  final MonthlyRevenueGoalFailureReason reason;

  const MonthlyRevenueGoalFailure(this.reason);

  @override
  List<Object?> get props => [reason];

  @override
  bool get stringify => true;
}
