import 'package:bits_goals_module/src/core/application/exceptions/rate_limiter_exception.dart';
import 'package:bits_goals_module/src/core/application/ports/infra_services/rate_limiter_service.dart';
import 'package:bits_goals_module/src/core/data/data_sources/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/annual_revenue_goal_meta_remote_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/infra/config/data_sources/firestore_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnualRevenueGoalRemoteDataSourceFirestoreImpl
    implements AnnualRevenueGoalRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Where monthly revenue goals are stored.
  final String _monthlyCollection;

  /// Where annual revenue goal metadata is stored to enforce uniqueness
  /// and optimize queries.
  final String _annualMeta;

  /// Where logs are stored.
  final String _logsCollection;

  final RateLimiterService _rateLimiter;

  AnnualRevenueGoalRemoteDataSourceFirestoreImpl({
    required FirestoreConfig config,
    required RateLimiterService rateLimiter,
  })  : _firestore = config.client,
        _monthlyCollection = config.monthlyRevenueGoalsCollection,
        _annualMeta = config.annualRevenueGoalsMetaCollection,
        _logsCollection = config.goalsActionLogsCollection,
        _rateLimiter = rateLimiter;

  @override
  Future<void> createMonthlyGoalsForYear({
    required int year,
    required List<MonthlyRevenueGoalRemoteModel> goals,
    required ActionLogModel log,
  }) async {
    try {
      await _rateLimiter.run(
        maxAttempts: 1,
        windowDuration: const Duration(seconds: 2),
        functionId: 'createMonthlyGoalsForYear($year)',
        function: () async {
          // Use transaction to ensure atomicity.
          await _firestore.runTransaction((transaction) async {
            final metaRef =
                _firestore.collection(_annualMeta).doc(year.toString());

            // Check if the year meta-document already exists to prevent duplicates.
            final metaSnapshot = await transaction.get(metaRef);
            if (metaSnapshot.exists) {
              throw const ServerException(
                reason: ServerExceptionReason.conflict,
              );
            }

            // Write the year metadata document.
            final metaModel = AnnualRevenueGoalMetaRemoteModel.fromYear(year);
            transaction.set(metaRef, metaModel.toMap());

            // Write all monthly goals.
            for (final goal in goals) {
              final goalRef = _firestore
                  .collection(_monthlyCollection)
                  .doc(goal.uuidV7.value);
              transaction.set(goalRef, goal.toMap());
            }

            // Log the action.
            final logRef = _firestore.collection(_logsCollection).doc(
                  log.uuidV7.value,
                );
            transaction.set(logRef, log.toMap());
          });
        },
      );
    } catch (e) {
      // Exceptions caught during the transaction.
      // Rethrow ServerException.
      if (e is ServerException) {
        rethrow;
      }

      if (e is RateLimiterException) {
        // Rethrow rate limit exceptions as is.
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
      throw ServerException(
        reason: ServerExceptionReason.unexpected,
        error: e,
      );
    }
  }
}
