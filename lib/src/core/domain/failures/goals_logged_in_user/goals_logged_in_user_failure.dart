import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/goals_logged_in_user/goals_logged_in_user_failure_reason.dart';

class GoalsLoggedInUserFailure extends Failure {
  final GoalsLoggedInUserFailureReason reason;

  const GoalsLoggedInUserFailure(this.reason);

  @override
  String toString() {
    return 'GoalsLoggedInUserFailure: $reason';
  }
}
