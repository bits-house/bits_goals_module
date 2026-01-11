import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_reason.dart';
import 'package:equatable/equatable.dart';

class InvalidYearFailure extends Failure with EquatableMixin {
  final InvalidYearReason reason;

  const InvalidYearFailure(this.reason);

  @override
  List<Object?> get props => [reason];
}
