import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_reason.dart';

class InvalidMoneyFailure extends Failure {
  final InvalidMoneyReason reason;

  const InvalidMoneyFailure(this.reason);

  @override
  String toString() {
    return 'InvalidMoneyFailure{reason: $reason}';
  }
}
