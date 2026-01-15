import 'package:bits_goals_module/src/core/data/data_sources/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/platform/network_info.dart';

class AnnualRevenueGoalRepositoryImpl implements AnnualRevenueGoalRepository {
  final AnnualRevenueGoalRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  AnnualRevenueGoalRepositoryImpl({
    required AnnualRevenueGoalRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<AnnualRevenueGoal> create(AnnualRevenueGoal goal) async {
    try {
      if (!await _networkInfo.isConnected) {
        throw const RepositoryFailure(
          reason: RepositoryFailureReason.connectionError,
        );
      }

      final monthlyModels = goal.monthlyGoals
          .map((entity) => MonthlyRevenueGoalRemoteModel.fromEntity(entity))
          .toList();

      await _remoteDataSource.createMonthlyGoalsForYear(
        year: goal.year.value,
        goals: monthlyModels,
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
        reason: RepositoryFailureReason.infra,
        cause: e,
      );
    } catch (e) {
      throw RepositoryFailure(
        reason: RepositoryFailureReason.infra,
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
      final yearInt = await _remoteDataSource.getCurrentYear();
      return Year.fromInt(yearInt);
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        reason: RepositoryFailureReason.infra,
        cause: e,
      );
    }
  }
}
