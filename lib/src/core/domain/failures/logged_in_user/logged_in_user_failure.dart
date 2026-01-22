import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure_reason.dart';

class LoggedInUserFailure extends Failure {
  final LoggedInUserFailureReason reason;

  const LoggedInUserFailure(this.reason);

  @override
  String toString() {
    return 'LoggedInUserFailure: $reason';
  }
}
