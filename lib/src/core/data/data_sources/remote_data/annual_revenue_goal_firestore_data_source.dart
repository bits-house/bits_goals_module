import 'package:bits_goals_module/src/core/data/data_sources/remote_data/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/annual_revenue_goal_meta_remote_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnualRevenueGoalFirestoreDataSource
    implements AnnualRevenueGoalRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Where monthly revenue goals are stored.
  static const String monthlyCollection = 'monthly_revenue_goals';

  /// Where annual revenue goal metadata is stored to enforce uniqueness
  /// and optimize queries.
  static const String annualMeta = 'annual_revenue_goals_meta';

  const AnnualRevenueGoalFirestoreDataSource(this._firestore);

  @override
  Future<void> createMonthlyGoalsForYear({
    required int year,
    required List<MonthlyRevenueGoalRemoteModel> goals,
  }) async {
    try {
      // We use a transaction to ensure atomicity.
      await _firestore.runTransaction((transaction) async {
        final metaRef = _firestore.collection(annualMeta).doc(year.toString());

        // 1. Atomic Check: Read before write.
        // We check if the year meta-document already exists to prevent duplicates.
        final metaSnapshot = await transaction.get(metaRef);
        if (metaSnapshot.exists) {
          throw const ServerException(
            reason: ServerExceptionReason.conflict,
          );
        }

        // 2. Write the meta document.
        final metaModel = AnnualRevenueGoalMetaRemoteModel(year: year);
        transaction.set(metaRef, metaModel.toMap());

        // 3. Write all monthly goals.
        for (final goal in goals) {
          final goalRef =
              _firestore.collection(monthlyCollection).doc(goal.uuidV7.value);
          transaction.set(goalRef, goal.toMap());
        }
      });
    } catch (e) {
      // Exceptions caught during the transaction.
      if (e is ServerException) {
        rethrow;
      }

      // Handle Firestore-specific exceptions.
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw const ServerException(
            reason: ServerExceptionReason.permissionDenied,
          );
        }
        throw const ServerException(
          reason: ServerExceptionReason.connectionError,
        );
      }

      // Fallback for any other exceptions.
      throw const ServerException(
        reason: ServerExceptionReason.unexpected,
      );
    }
  }
}
