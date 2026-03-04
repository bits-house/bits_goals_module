import 'package:bits_goals_module/src/core/data/exceptions/rate_limit_exceeded_exception.dart';
import 'package:bits_goals_module/src/core/data/data_sources/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/application/ports/network_service.dart';

class AnnualRevenueGoalRepositoryImpl implements AnnualRevenueGoalRepository {
  final AnnualRevenueGoalRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  AnnualRevenueGoalRepositoryImpl({
    required AnnualRevenueGoalRemoteDataSource remoteDataSource,
    required NetworkService networkService,
  })  : _remoteDataSource = remoteDataSource,
        _networkService = networkService;

  @override
  Future<AnnualRevenueGoal> create({
    required AnnualRevenueGoal goal,
    required ActionLog log,
  }) async {
    try {
      if (!await _networkService.isConnected) {
        throw const AnnualRevenueGoalRepFailure(
          reason: AnnualRevenueGoalRepFailureReason.connectionError,
        );
      }

      final monthlyModels = goal.monthlyGoals
          .map((entity) => MonthlyRevenueGoalRemoteModel.fromEntity(entity))
          .toList();

      final logModel = ActionLogModel.create(log);

      await _remoteDataSource.createMonthlyGoalsForYear(
        year: goal.year.value,
        goals: monthlyModels,
        log: logModel,
      );

      return goal;
    } on AnnualRevenueGoalRepFailure {
      rethrow;
    } on RateLimitExceededException catch (e) {
      throw AnnualRevenueGoalRepFailure(
        reason: AnnualRevenueGoalRepFailureReason.rateLimitExceeded,
        rateLimitRemainingDuration: e.remainingDuration,
      );
    } on ServerException catch (e) {
      if (e.reason == ServerExceptionReason.conflict) {
        throw const AnnualRevenueGoalRepFailure(
          reason:
              AnnualRevenueGoalRepFailureReason.annualGoalForYearAlreadyExists,
        );
      } else if (e.reason == ServerExceptionReason.permissionDenied) {
        throw const AnnualRevenueGoalRepFailure(
          reason: AnnualRevenueGoalRepFailureReason.permissionDenied,
        );
      }

      throw AnnualRevenueGoalRepFailure(
        reason: AnnualRevenueGoalRepFailureReason.connectionError,
        message:
            'ServerException caught by AnnualRevenueGoalRepositoryImpl: ${e.error}',
      );
    } catch (e) {
      throw AnnualRevenueGoalRepFailure(
        reason: AnnualRevenueGoalRepFailureReason.connectionError,
        message:
            'Unexpected error caught by AnnualRevenueGoalRepositoryImpl: $e',
      );
    }
  }
}
