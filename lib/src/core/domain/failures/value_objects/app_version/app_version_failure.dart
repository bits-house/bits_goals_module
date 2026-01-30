import 'package:bits_goals_module/src/core/domain/failures/value_objects/app_version/app_version_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/failure.dart';

class AppVersionFailure extends Failure {
  final AppVersionFailureReason reason;

  const AppVersionFailure(this.reason);

  @override
  String toString() {
    return 'AppVersionFailure{reason: $reason}';
  }
}
