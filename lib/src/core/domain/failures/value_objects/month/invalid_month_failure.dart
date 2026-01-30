import 'package:bits_goals_module/src/core/domain/failures/failure.dart';

import 'invalid_month_reason.dart';

class InvalidMonthFailure extends Failure {
  final InvalidMonthReason reason;

  const InvalidMonthFailure(this.reason);

  @override
  String toString() {
    return 'InvalidMonthFailure{reason: $reason}';
  }
}
