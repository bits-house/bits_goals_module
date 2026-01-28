import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';

abstract class AccessControlService {
  bool hasPermission(GoalsModulePermission permission);

  LoggedInUser get loggedInUser;
}
