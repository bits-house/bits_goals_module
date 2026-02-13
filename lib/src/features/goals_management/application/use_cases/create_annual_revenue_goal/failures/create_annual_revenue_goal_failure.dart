import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:equatable/equatable.dart';

class CreateAnnualRevenueGoalFailure extends Failure with EquatableMixin {
  final CreateAnnualRevenueGoalFailureReason reason;
  final Object? cause;

  /// Optional: when the failure is due to rate limiting
  final Duration? retryAfter;

  const CreateAnnualRevenueGoalFailure({
    super.message,
    required this.reason,
    this.retryAfter,
    this.cause,
  });

  @override
  List<Object?> get props => [
        message,
        reason,
        retryAfter,
        cause,
      ];

  @override
  bool get stringify => true;
}
