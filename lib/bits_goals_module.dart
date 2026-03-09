import 'package:bits_goals_module/bits_goals_module.dart';
import 'package:bits_goals_module/src/core/application/ports/access_control_service.dart';
import 'package:bits_goals_module/src/core/application/ports/rate_limiter_service.dart';
import 'package:bits_goals_module/src/core/data/mappers/annual_revenue_goal_action_log_mapper_impl.dart';
import 'package:bits_goals_module/src/core/data/repositories/annual_revenue_goal_repository_impl.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/infra/adapters/access_control_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/app_info_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/device_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/metadata_collector_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/network_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/rate_limiter_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/real_time_service_impl.dart';
import 'package:bits_goals_module/src/infra/data_sources/firestore/annual_revenue_goal_remote_data_source_firestore_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

import 'src/core/presentation/state_management/reactivity_flutter/app_provider.dart';

// =================================================================
// Exports
// =================================================================

// Config exports
export 'src/infra/config/goals_module_config.dart';
export 'src/infra/config/data_sources/firestore_config.dart';

// Domain Value Objects exports
export 'src/core/domain/value_objects/logged_in_user.dart';
export 'src/core/domain/value_objects/user_role.dart';

// Domain Enums exports
export 'src/core/domain/enums/goals_module_permission.dart';
export 'src/core/domain/enums/currency.dart';

// ----------------------------------------------------------------
// Features exports
// ----------------------------------------------------------------

// Widget exports
export 'src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_button.dart';

// ================================================================
// BitsGoalsModule - Main module class
// ================================================================

// TODO: Refactor dependency injection approach in this module.
class BitsGoalsModule {
  /// Makes a [GoalsModuleConfig] available to the goals module through
  /// [BuildContext].
  ///
  /// Any widget inside [child] can access it via `context.get<GoalsModuleConfig>()`.
  static Widget init({
    required GoalsModuleConfig config,
    required Widget child,
  }) {
    final rateLimiter = RateLimiterServiceImpl();
    final accessControl = AccessControlServiceImpl(config);
    final Client httpClient = Client();
    return AppProvider<GoalsModuleConfig>(
      resource: config,
      child: AppProvider<RateLimiterService>(
        resource: rateLimiter,
        child: AppProvider<AccessControlService>(
          resource: accessControl,
          child: AppProvider<CreateAnnualRevenueGoal>(
            resource: CreateAnnualRevenueGoal(
              repository: AnnualRevenueGoalRepositoryImpl(
                networkService: NetworkServiceImpl(),
                remoteDataSource:
                    AnnualRevenueGoalRemoteDataSourceFirestoreImpl(
                  config: config.remoteDataSrcConfig as FirestoreConfig,
                  rateLimiter: rateLimiter,
                ),
              ),
              accessControl: accessControl,
              metadataCollector: ActionLogMetadataProviderImpl(
                appInfoService: AppInfoServiceImpl(),
                deviceService: DeviceServiceImpl(),
                networkService: NetworkServiceImpl(),
              ),
              goalMapper: const AnnualRevenueGoalActionLogMapperImpl(),
              realTimeService: RealTimeServiceImpl(
                client: httpClient,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
