import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure_reason.dart';

/// Failure class for AnnualRevenueGoalRepository operations.
///
/// Encapsulates specific failure reasons related to annual revenue
/// goal repository operations.
///
/// Between the repository and the use cases,
/// to abstract away data layer details and provide
class AnnualRevenueGoalRepFailure extends Failure {
  final AnnualRevenueGoalRepFailureReason reason;

  /// Optional field to provide additional context about the failure
  final Duration? rateLimitRemainingDuration;
  final Object? cause;

  const AnnualRevenueGoalRepFailure({
    super.message,
    required this.reason,
    this.rateLimitRemainingDuration,
    this.cause,
  });

  @override
  String toString() {
    return 'AnnualRevenueGoalRepFailure{'
        'reason: $reason, '
        'cause: $cause, '
        'rateLimitRemainingDuration: $rateLimitRemainingDuration, '
        'message: $message,'
        '}';
  }
}
