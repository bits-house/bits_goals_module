import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';

/// Central interface for all Use Cases types in the application.
/// MUST only be extended by other Use Case interfaces.
/// All use cases interfaces MUST extend this base interface.
abstract class UseCaseBase {
  /// The permission required to execute this use case.
  /// Implementations should override this to specify the needed permission.
  /// The caller is responsible for checking this permission before invoking the use case.
  /// If no permission is required, must return [GoalsModulePermission.none].
  GoalsModulePermission get requiredPermission;
}
