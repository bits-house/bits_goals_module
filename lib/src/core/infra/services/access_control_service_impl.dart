import 'package:bits_goals_module/src/goals_module_contract.dart';

import '../../domain/services/access_control_service.dart';

class AccessControlServiceImpl implements AccessControlService {
  final GoalsModuleConfig _config;

  AccessControlServiceImpl(this._config);

  @override
  bool hasPermission(GoalsModulePermission permission) {
    if (permission == GoalsModulePermission.none) {
      return true;
    }
    final currentRole = _config.getCurrentUser().role;
    final allowedPermissions = _config.rolePermissions[currentRole] ?? [];
    return allowedPermissions.contains(permission);
  }
}
