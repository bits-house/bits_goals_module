import 'package:bits_goals_module/src/goals_module_contract.dart';

abstract class AccessControlService {
  bool hasPermission(GoalsModulePermission permission);
}
