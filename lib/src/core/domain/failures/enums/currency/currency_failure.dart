import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/enums/currency/currency_failure_reason.dart';

class CurrencyFailure extends Failure {
  final CurrencyFailureReason reason;

  const CurrencyFailure(this.reason);

  @override
  String toString() {
    return 'CurrencyFailure{reason: $reason}';
  }
}
