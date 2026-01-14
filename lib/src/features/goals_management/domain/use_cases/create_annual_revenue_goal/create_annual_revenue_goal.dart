import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/domain/services/split_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/use_cases/use_case.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';

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
///
/// **Error Scenarios:**
/// * [CreateAnnualRevenueGoalFailureReason.pastYear] - Year is in the past.
/// * [CreateAnnualRevenueGoalFailureReason.annualGoalForYearAlreadyExists] - Goal for year already exists.
/// * [CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget] - Input or split resulted in <= 0 values.
/// * [CreateAnnualRevenueGoalFailureReason.permissionDenied] - User lacks rights.
/// * Other unexpected and infrastructure errors.
class CreateAnnualRevenueGoal
    implements UseCase<AnnualRevenueGoal, CreateAnnualRevenueGoalParams> {
  final AnnualRevenueGoalRepository repository;

  CreateAnnualRevenueGoal(this.repository);

  @override
  Future<Either<Failure, AnnualRevenueGoal>> call(
    CreateAnnualRevenueGoalParams params,
  ) async {
    try {
      /// Annual revenue target must be greater than zero
      if (params.annualRevenueTarget.cents <= 0) {
        return left(
          const CreateAnnualRevenueGoalFailure(
            reason: CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget,
          ),
        );
      }

      /// Year must be equal or greater than current year
      final currentYear = await repository.getCurrentYear();
      if (params.year.isBefore(currentYear)) {
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
        year: params.year,
        annualGoalTarget: params.annualRevenueTarget,
      );

      /// Create AnnualRevenueGoal aggregate
      /// (this will validate AnnualRevenueGoal invariants)
      final annualGoal = AnnualRevenueGoal.create(
        year: params.year,
        monthlyGoals: monthlyGoals,
      );

      /// Persist atomically, ensuring rules are enforced
      final savedGoal = await repository.create(annualGoal);

      return right(savedGoal);
    }

    /// =============================
    /// Error handling
    /// =============================

    /// RepositoryFailure
    on RepositoryFailure catch (repositoryFailure) {
      switch (repositoryFailure.reason) {
        case RepositoryFailureReason.annualGoalForYearAlreadyExists:
          return left(
            const CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason
                  .annualGoalForYearAlreadyExists,
            ),
          );
        case RepositoryFailureReason.permissionDenied:
          return left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason.permissionDenied,
              cause: repositoryFailure,
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
          reason: CreateAnnualRevenueGoalFailureReason.internal,
          cause: e,
        ),
      );
    }
  }
}
