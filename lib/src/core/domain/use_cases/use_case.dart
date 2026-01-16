import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/use_cases/params/no_params.dart';
import 'package:bits_goals_module/src/goals_module_contract.dart';
import 'package:dartz/dartz.dart';

/// Generic interface for a Use Case in the application.
abstract class UseCase<Type, Params> {
  /// The permission required to execute this use case.
  /// Implementations should override this to specify the needed permission.
  /// The caller is responsible for checking this permission before invoking the use case.
  /// If no permission is required, return [GoalsModulePermission.none].
  GoalsModulePermission get requiredPermission;

  /// Executes the use case with the given [params].
  /// Returns either a [Failure] or the expected [Type] result.
  /// If no parameters are needed, use [NoParams] as [Params].
  Future<Either<Failure, Type>> call(Params params);
}
