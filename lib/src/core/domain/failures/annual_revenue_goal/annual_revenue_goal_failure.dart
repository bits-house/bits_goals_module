import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:equatable/equatable.dart';
import 'annual_revenue_goal_failure_reason.dart';

class AnnualRevenueGoalFailure extends Failure with EquatableMixin {
  final AnnualRevenueGoalFailureReason reason;

  const AnnualRevenueGoalFailure(this.reason);

  @override
  List<Object?> get props => [reason];

  @override
  bool get stringify => true;
}
