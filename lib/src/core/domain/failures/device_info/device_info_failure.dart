import 'package:bits_goals_module/src/core/domain/failures/device_info/device_info_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/failure.dart';

class DeviceInfoFailure extends Failure {
  final DeviceInfoFailureReason reason;

  const DeviceInfoFailure(this.reason);

  @override
  String toString() {
    return 'DeviceInfoFailure{reason: $reason}';
  }
}
