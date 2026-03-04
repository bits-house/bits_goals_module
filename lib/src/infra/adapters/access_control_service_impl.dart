import 'package:bits_goals_module/src/core/application/ports/access_control_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_config.dart';
import 'package:bits_goals_module/src/core/domain/enums/goals_module_permission.dart';

/// Implementation of Access Control Service.
///
/// This service acts as the bridge between the [LoggedInUser] (which holds the role name)
/// and the [GoalsModuleConfig] (which holds the host app defined roles and permissions).
class AccessControlServiceImpl implements AccessControlService {
  final GoalsModuleConfig _config;

  AccessControlServiceImpl(this._config);

  @override
  LoggedInUser get loggedInUser => _config.getCurrentUser();

  @override
  bool hasPermission(GoalsModulePermission permission) {
    UserRole getFallbackRole() {
      return UserRole(
        roleName: 'undefined_fallback',
        rolePermissions: const [GoalsModulePermission.none],
      );
    }

    if (permission == GoalsModulePermission.none) {
      return true;
    }

    final currentUserRoleName = loggedInUser.roleName;
    final userRole = _config.getRoles().firstWhere(
          (role) => role.roleName == currentUserRoleName,
          // Security Fallback: If the user has a role that is not defined in the config
          // (e.g., 'deprecated_role'), we return a safe 'guest' role with NO permissions.
          orElse: () => getFallbackRole(),
        );

    return userRole.hasPermission(permission);
  }
}
