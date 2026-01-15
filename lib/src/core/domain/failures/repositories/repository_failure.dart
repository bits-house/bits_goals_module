import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure_reason.dart';

/// Represents infrastructure-related failures that occur during
/// data access or external system interactions.
/// These failures are typically unexpected and indicate issues
/// beyond the application's business logic.
class RepositoryFailure extends Failure {
  final RepositoryFailureReason reason;
  final Object? cause;

  const RepositoryFailure({
    super.message,
    required this.reason,
    this.cause,
  });

  @override
  String toString() {
    return 'RepositoryFailure{'
        'reason: $reason, '
        'cause: $cause, '
        'message: $message,'
        '}';
  }
}
