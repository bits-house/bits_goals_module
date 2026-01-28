import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/use_cases/use_case_base.dart';
import 'package:dartz/dartz.dart';

/// Interface for Use Cases that require parameters.
abstract class ParamsUseCase<Type, Params> extends UseCaseBase {
  /// Executes the use case with the given [params].
  /// Returns either a [Failure] or the expected [Type] result.
  Future<Either<Failure, Type>> call(Params params);
}
