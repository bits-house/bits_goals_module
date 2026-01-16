/// Defines the set of permissions available within the Goals Module.
/// One per use case that requires access control.
enum GoalsModulePermission {
  createAnnualGoal,
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
  ///   'admin': [GoalsModulePermission.createAnnualGoal],
  ///   'user': [],
  /// },
  /// ...
  /// );
  /// ```
  final Map<String, List<GoalsModulePermission>> rolePermissions;

  /// Callback to fetch the current user's role.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  /// ...
  /// getCurrentUserRole: () => mainAppService.getCurrentUserRole(),
  /// // Ex: () => 'admin' or 'seller' based on logged-in user
  /// );
  /// ```
  /// This allows dynamic retrieval of the user's role at runtime.
  final String Function() getCurrentUserRole;

  GoalsModuleConfig({
    required this.rolePermissions,
    required this.getCurrentUserRole,
  });
}
