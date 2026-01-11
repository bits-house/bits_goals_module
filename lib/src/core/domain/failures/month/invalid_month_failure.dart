import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:equatable/equatable.dart';

import 'invalid_month_reason.dart';

class InvalidMonthFailure extends Failure with EquatableMixin {
  final InvalidMonthReason reason;

  const InvalidMonthFailure(this.reason);

  @override
  List<Object?> get props => [reason];

  @override
  bool get stringify => true;
}
