import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_reason.dart';
import 'package:equatable/equatable.dart';

class InvalidMoneyFailure extends Failure with EquatableMixin {
  final InvalidMoneyReason reason;

  const InvalidMoneyFailure(this.reason);

  @override
  List<Object?> get props => [reason];

  @override
  bool get stringify => true;
}
