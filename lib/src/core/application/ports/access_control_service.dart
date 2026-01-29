import 'package:bits_goals_module/src/core/domain/policies/goals_module_permission.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';

/// Application port for authorization/permission checks.
///
/// This is not a domain service. Implementations live in Infra.
abstract class AccessControlService {
  bool hasPermission(GoalsModulePermission permission);

  LoggedInUser get loggedInUser;
}
