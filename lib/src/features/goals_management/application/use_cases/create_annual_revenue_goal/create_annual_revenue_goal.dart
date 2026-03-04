import 'package:bits_goals_module/src/core/application/dtos/action_log_metadata_dto.dart';
import 'package:bits_goals_module/src/core/application/ports/access_control_service.dart';
import 'package:bits_goals_module/src/core/application/ports/action_log_metadata_provider.dart';
import 'package:bits_goals_module/src/core/application/ports/real_time_service.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_type.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/application/ports/data_mappers/annual_revenue_goal_action_log_mapper.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/enums/goals_module_permission.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/domain/services/split_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/application/use_cases/params_use_case.dart';
import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';

import 'package:dartz/dartz.dart';

/// ## Use Case: Create Annual Revenue Goal
///
/// **User Story:**
/// As a sales manager, I want to create an annual revenue goal for a specific year,
/// so that I can set clear sales targets for my team.
///
/// **Acceptance Criteria:**
/// * Input: Target annual revenue amount and Year.
/// * Output: A persisted Annual Goal containing 12 Monthly Goals.
/// * Logic: Automatically splits the target into 12 unique months, handling cent remainders.
///
/// **Domain Invariants & Rules:**
/// * **Year:** Must be >= current year and unique in the database.
/// * **Distribution:** The annual target is split across exactly 12 unique months.
/// * **Financials:** All targets must be > 0. Sum of months == Annual Target.
/// * **Permission:** User must have rights to create annual goals.
/// * **Logging:** An ActionLog is created for auditing.
///
/// **Error Scenarios:**
/// * [CreateAnnualRevenueGoalFailureReason.pastYear] - Year is in the past.
/// * [CreateAnnualRevenueGoalFailureReason.annualGoalForYearAlreadyExists] - Goal for year already exists.
/// * [CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget] - Input or split resulted in <= 0 values.
/// * [CreateAnnualRevenueGoalFailureReason.permissionDenied] - User lacks rights.
/// * [CreateAnnualRevenueGoalFailureReason.rateLimitExceeded] - Rate limit exceeded.
/// * Other unexpected and infrastructure errors.

class CreateAnnualRevenueGoal
    implements ParamsUseCase<AnnualRevenueGoal, CreateAnnualRevenueGoalParams> {
  final AnnualRevenueGoalRepository repository;
  final AccessControlService accessControl;
  final ActionLogMetadataProvider metadataCollector;
  final AnnualRevenueGoalActionLogMapper goalMapper;
  final RealTimeService realTimeService;

  CreateAnnualRevenueGoal({
    required this.repository,
    required this.accessControl,
    required this.metadataCollector,
    required this.goalMapper,
    required this.realTimeService,
  });

  @override
  GoalsModulePermission get requiredPermission =>
      GoalsModulePermission.createAnnualRevenueGoals;

  @override
  Future<Either<CreateAnnualRevenueGoalFailure, AnnualRevenueGoal>> call(
    CreateAnnualRevenueGoalParams params,
  ) async {
    const useCaseId = 'create_annual_revenue_goal';
    try {
      /// User must have permission to create annual revenue goals
      final hasPermission = accessControl.hasPermission(
        requiredPermission,
      );
      if (!hasPermission) {
        return const Left(
          CreateAnnualRevenueGoalFailure(
            reason: CreateAnnualRevenueGoalFailureReason.permissionDenied,
          ),
        );
      }

      /// Convert params to Value Objects, validating invariants in the process
      final year = Year.fromInt(params.year);
      final currency = Currency.fromISO4217(params.currencyISO4217Code);
      final target = Money.fromDouble(
        value: params.annualRevenueTarget,
        currency: currency,
      );

      /// Annual revenue target must be greater than zero
      if (target.cents <= 0) {
        return left(
          const CreateAnnualRevenueGoalFailure(
            reason: CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget,
          ),
        );
      }

      /// Year must be equal or greater than current year
      final currentYear = await realTimeService.getCurrentYear();
      if (year.isBefore(currentYear)) {
        return left(
          const CreateAnnualRevenueGoalFailure(
            reason: CreateAnnualRevenueGoalFailureReason.pastYear,
          ),
        );
      }

      /// Generate monthly goals using domain service
      /// (this will validate MonthlyRevenueGoal invariants)
      const splitGoal = SplitAnnualRevenueGoal();
      final monthlyGoals = splitGoal(
        year: year,
        annualGoalTarget: target,
      );

      /// Create AnnualRevenueGoal aggregate
      /// (this will validate AnnualRevenueGoal invariants)
      final annualGoal = AnnualRevenueGoal.build(
        year: year,
        monthlyGoals: monthlyGoals,
      );

      /// Create ActionLog
      final ActionLogMetadataDto metadata = await metadataCollector.metadata;
      final log = ActionLog.create(
        actionType: ActionType.create,
        useCaseId: useCaseId,
        requiredPermission: requiredPermission,
        newDataMapped: goalMapper.map(annualGoal),
        user: accessControl.loggedInUser,
        appVersion: metadata.appVersion,
        userDeviceInfo: metadata.userDeviceInfo,
        userIpAddress: metadata.userIpAddress,
      );

      /// Persist atomically
      final savedGoal = await repository.create(
        goal: annualGoal,
        log: log,
      );

      return right(savedGoal);
    }

    /// =============================
    /// Error handling
    /// =============================

    /// RepositoryFailure
    on AnnualRevenueGoalRepFailure catch (repositoryFailure) {
      switch (repositoryFailure.reason) {
        case AnnualRevenueGoalRepFailureReason.annualGoalForYearAlreadyExists:
          return left(
            const CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason
                  .annualGoalForYearAlreadyExists,
            ),
          );
        case AnnualRevenueGoalRepFailureReason.permissionDenied:
          return left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason.permissionDenied,
              cause: repositoryFailure,
            ),
          );
        case AnnualRevenueGoalRepFailureReason.rateLimitExceeded:
          return left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason.rateLimitExceeded,
              retryAfter: repositoryFailure.rateLimitRemainingDuration,
            ),
          );
        default:
          return left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason.connectionError,
              cause: repositoryFailure,
            ),
          );
      }
    } catch (e) {
      return left(
        CreateAnnualRevenueGoalFailure(
          reason: CreateAnnualRevenueGoalFailureReason.unexpected,
          cause: e,
        ),
      );
    }
  }
}
