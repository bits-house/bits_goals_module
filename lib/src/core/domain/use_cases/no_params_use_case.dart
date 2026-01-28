import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/use_cases/use_case_base.dart';
import 'package:dartz/dartz.dart';

/// Interface for Use Cases that do not require parameters.
abstract class NoParamsUseCase<Type> extends UseCaseBase {
  /// Returns either a [Failure] or the expected [Type] result.
  Future<Either<Failure, Type>> call();
}
