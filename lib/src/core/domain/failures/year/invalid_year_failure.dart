import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_reason.dart';

class InvalidYearFailure extends Failure {
  final InvalidYearReason reason;

  const InvalidYearFailure(this.reason);

  @override
  String toString() {
    return 'InvalidYearFailure{reason: $reason}';
  }
}
