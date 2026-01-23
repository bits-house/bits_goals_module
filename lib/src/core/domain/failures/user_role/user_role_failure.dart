import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/user_role/user_role_failure_reason.dart';

class UserRoleFailure extends Failure {
  final UserRoleFailureReason reason;

  const UserRoleFailure(this.reason);

  @override
  String toString() {
    return 'UserRoleFailure{reason: $reason}';
  }
}
