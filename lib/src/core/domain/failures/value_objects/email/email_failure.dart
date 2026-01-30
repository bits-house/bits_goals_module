import 'package:bits_goals_module/src/core/domain/failures/value_objects/email/email_failure_reason.dart';

class EmailFailure implements Exception {
  final EmailFailureReason reason;

  const EmailFailure(this.reason);

  @override
  String toString() => 'EmailFailure: $reason';
}
