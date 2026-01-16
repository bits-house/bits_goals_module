import 'package:bits_goals_module/src/core/domain/value_objects/goals_logged_in_user.dart';

/// Defines the set of permissions available within the Goals Module.
enum GoalsModulePermission {
  /// No special permission required.
  none,

  manageGlobalGoals,
}

/// Configuration class for Goals Module access control.
/// Defines roles and their associated permissions.
/// Must be provided during module initialization.
class GoalsModuleConfig {
  /// Map of: Role Name (String) -> List of Permissions.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  /// rolePermissions: {
  ///   'admin': [GoalsModulePermission.manageGlobalGoals],
  ///   'user': [],
  /// },
  /// ...
  /// );
  /// ```
  final Map<String, List<GoalsModulePermission>> rolePermissions;

  /// Callback to fetch the current user's role and other details.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  /// ...
  /// getCurrentUser: () => mainAppService.getCurrentUser(),
  /// // returns GoalsLoggedInUser (goals module user representation)
  /// ```
  final GoalsLoggedInUser Function() getCurrentUser;

  GoalsModuleConfig({
    // TODO: Create Firestore config as an implementation of data source integration abstraction,
    //  with option to set collection names, pass custom Firestore instances, etc.
    // TODO: Create data source integration abstraction
    required this.rolePermissions,
    required this.getCurrentUser,
  });
}
