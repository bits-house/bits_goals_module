import 'package:bits_goals_module/src/core/data/data_sources/remote_data/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/infra/platform/network_info.dart';

class AnnualRevenueGoalRepositoryImpl implements AnnualRevenueGoalRepository {
  final AnnualRevenueGoalRemoteDataSource _remoteDataSource;
  final RemoteTimeDataSource _remoteTimeSource;
  final NetworkInfo _networkInfo;

  AnnualRevenueGoalRepositoryImpl({
    required AnnualRevenueGoalRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required RemoteTimeDataSource remoteTimeDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _remoteTimeSource = remoteTimeDataSource;

  @override
  Future<AnnualRevenueGoal> create({
    required AnnualRevenueGoal goal,
    required ActionLog log,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw const RepositoryFailure(
          reason: RepositoryFailureReason.connectionError,
        );
      }

      final monthlyModels = goal.monthlyGoals
          .map((entity) => MonthlyRevenueGoalRemoteModel.fromEntity(entity))
          .toList();

      final logModel = ActionLogModel.fromEntity(log);

      await _remoteDataSource.createMonthlyGoalsForYear(
        year: goal.year.value,
        goals: monthlyModels,
        log: logModel,
      );

      return goal;
    } on RepositoryFailure {
      rethrow;
    } on ServerException catch (e) {
      if (e.reason == ServerExceptionReason.conflict) {
        throw const RepositoryFailure(
          reason: RepositoryFailureReason.annualGoalForYearAlreadyExists,
        );
      } else if (e.reason == ServerExceptionReason.permissionDenied) {
        throw const RepositoryFailure(
          reason: RepositoryFailureReason.permissionDenied,
        );
      }

      throw RepositoryFailure(
        reason: RepositoryFailureReason.connectionError,
        cause: e,
      );
    } catch (e) {
      throw RepositoryFailure(
        reason: RepositoryFailureReason.connectionError,
        cause: e,
      );
    }
  }

  @override
  Future<Year> getCurrentYear() async {
    try {
      if (!await _networkInfo.isConnected) {
        throw const RepositoryFailure(
          reason: RepositoryFailureReason.connectionError,
        );
      }
      final yearInt = await _remoteTimeSource.getCurrentYear();
      return Year.fromInt(yearInt);
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        reason: RepositoryFailureReason.connectionError,
        cause: e,
      );
    }
  }
}
