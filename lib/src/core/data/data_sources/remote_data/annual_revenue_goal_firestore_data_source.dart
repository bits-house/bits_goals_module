import 'package:bits_goals_module/src/core/data/data_sources/remote_data/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';

class AnnualRevenueGoalFirestoreDataSource
    implements AnnualRevenueGoalRemoteDataSource {
  @override
  Future<void> createMonthlyGoalsForYear({
    required int year,
    required List<MonthlyRevenueGoalRemoteModel> goals,
  }) {
    // TODO: implement saveMonthlyGoalsForYear
    throw UnimplementedError();
  }
}
