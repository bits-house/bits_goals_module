import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/ip_address/ip_address_failure_reason.dart';

class IpAddressFailure extends Failure {
  final IpAddressFailureReason reason;

  const IpAddressFailure(this.reason);

  @override
  String toString() {
    return 'IpAddressFailure{reason: $reason}';
  }
}
