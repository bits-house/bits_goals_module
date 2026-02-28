import 'package:flutter/widgets.dart';

import 'src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'src/infra/config/goals_module_config.dart';

// Config exports
export 'src/infra/config/goals_module_config.dart';
export 'src/infra/config/data_sources/firestore_config.dart';

// Domain Value Objects exports
export 'src/core/domain/value_objects/logged_in_user.dart';
export 'src/core/domain/value_objects/user_role.dart';

// Domain Policies exports
export 'src/core/domain/policies/goals_module_permission.dart';

// Widget exports
export 'src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_button.dart';

class BitsGoalsModule {
  /// Makes a [GoalsModuleConfig] available to the goals module through
  /// [BuildContext].
  ///
  /// Any widget inside [child] can access it via `context.get<GoalsModuleConfig>()`.
  static Widget init({
    required GoalsModuleConfig config,
    required Widget child,
  }) {
    return AppProvider<GoalsModuleConfig>(
      resource: config,
      child: child,
    );
  }
}
