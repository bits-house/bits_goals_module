import 'package:bits_goals_module/src/core/data/data_sources/remote_data/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnualRevenueGoalFirestoreDataSource
    implements AnnualRevenueGoalRemoteDataSource {
  final FirebaseFirestore _firestore;

  static const String _monthlyGoalsCollection = 'monthly_revenue_goals';

  const AnnualRevenueGoalFirestoreDataSource(this._firestore);

  @override
  Future<void> createMonthlyGoalsForYear({
    required int year,
    required List<MonthlyRevenueGoalRemoteModel> goals,
  }) {
    // TODO: implement saveMonthlyGoalsForYear
    throw UnimplementedError();
  }
}
