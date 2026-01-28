import 'package:bits_goals_module/src/core/domain/services/interfaces/access_control_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_config.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';

/// Implementation of Access Control Service.
///
/// This service acts as the bridge between the [LoggedInUser] (which holds the role name)
/// and the [GoalsModuleConfig] (which holds the host app defined roles and permissions).
class AccessControlServiceImpl implements AccessControlService {
  final GoalsModuleConfig _config;

  AccessControlServiceImpl(this._config);

  @override
  bool hasPermission(GoalsModulePermission permission) {
    if (permission == GoalsModulePermission.none) {
      return true;
    }

    final currentRoleName = _config.getCurrentUser().roleName;

    final userRoleEntity = _config.roles.firstWhere(
      (role) => role.roleName == currentRoleName,
      // Security Fallback: If the user has a role that is not defined in the config
      // (e.g., 'deprecated_role'), we return a safe 'guest' role with NO permissions.
      orElse: () => _getFallbackRole(),
    );

    return userRoleEntity.hasPermission(permission);
  }

  @override
  LoggedInUser get loggedInUser => _config.getCurrentUser();

  /// Creates a safe fallback role with minimum privileges.
  UserRole _getFallbackRole() {
    return UserRole(
      roleName: 'undefined_fallback',
      rolePermissions: const [GoalsModulePermission.none],
    );
  }
}
