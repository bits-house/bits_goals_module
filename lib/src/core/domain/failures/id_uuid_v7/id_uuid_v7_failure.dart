import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure_reason.dart';

class IdUuidV7Failure extends Failure {
  final IdUuidV7FailureReason reason;

  const IdUuidV7Failure(this.reason);

  @override
  String toString() {
    return 'IdUuidV7Failure{reason: $reason}';
  }
}
