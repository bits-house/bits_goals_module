import 'package:bits_goals_module/src/infra/config/data_sources/firestore_config.dart';
import 'package:bits_goals_module/src/infra/data_sources/firestore/annual_revenue_goal_firestore_data_source_impl.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Helper to simulate Firestore transaction failures.
class ErrorThrowingFirestore extends FakeFirebaseFirestore {
  final Object errorToThrow;
  ErrorThrowingFirestore(this.errorToThrow);

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    throw errorToThrow;
  }
}

class MockFirestoreConfig extends Mock implements FirestoreConfig {}

void main() {
  late AnnualRevenueGoalFirestoreDataSource dataSource;
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreConfig config;

  // Constants for collection names
  const tYear = 2026;
  const tMonthlyCol = 'monthly_revenue_goals';
  const tAnnualCol = 'annual_revenue_goals_meta';
  const tLogsCol = 'goals_action_logs';

  // Reusable test models
  final tLogModel = ActionLogModel();

  final tGoalModel = MonthlyRevenueGoalRemoteModel.fromEntity(
    MonthlyRevenueGoal.create(
      id: IdUuidV7.fromString('018b1f3c-8c08-7e3f-9b0d-7b2f4c6e8a1d'),
      month: Month.fromInt(1),
      year: Year.fromInt(tYear),
      target: Money.fromCents(100000),
      progress: Money.fromCents(0),
    ),
  );

  group('AnnualRevenueGoalFirestoreDataSource Implementation Tests', () {
    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      config = FirestoreConfig(
        firestore: fakeFirestore,
        annualRevenueGoalsMetaCollectionName: tAnnualCol,
        monthlyRevenueGoalsCollectionName: tMonthlyCol,
        goalsActionLogsCollectionName: tLogsCol,
      );
      dataSource = AnnualRevenueGoalFirestoreDataSource(config);
    });

    group('Success Scenarios', () {
      test(
        'should commit all data (meta, goals, and logs) in a single atomic transaction',
        () async {
          // Act
          await dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: [tGoalModel],
            log: tLogModel,
          );

          // Assert: 1. Check Year Metadata
          final metaDoc = await fakeFirestore
              .collection(tAnnualCol)
              .doc(tYear.toString())
              .get();
          expect(metaDoc.exists, isTrue);
          expect(metaDoc.data()?['year'], tYear);

          // Assert: 2. Check Monthly Goal Document
          final goalDoc = await fakeFirestore
              .collection(tMonthlyCol)
              .doc(tGoalModel.uuidV7.value)
              .get();
          expect(goalDoc.exists, isTrue);
          expect(goalDoc.data()?['target_cents'], 100000);

          // Assert: 3. Check Action Log Entry
          final logs = await fakeFirestore.collection(tLogsCol).get();
          expect(logs.docs.length, 1);
          expect(logs.docs.first.data()['action'], 'setup_2026_goals');
        },
      );

      test(
        'should support creating multiple monthly goals in the same transaction',
        () async {
          final multipleGoals = List.generate(
            3,
            (index) => MonthlyRevenueGoalRemoteModel.fromEntity(
              MonthlyRevenueGoal.create(
                id: IdUuidV7.generate(),
                month: Month.fromInt(index + 1),
                year: Year.fromInt(tYear),
                target: Money.fromCents(50000),
                progress: Money.fromCents(0),
              ),
            ),
          );

          await dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: multipleGoals,
            log: tLogModel,
          );

          final goalsSnapshot =
              await fakeFirestore.collection(tMonthlyCol).get();
          expect(goalsSnapshot.docs.length, 3);
        },
      );
    });

    group('Conflict & Rollback Scenarios', () {
      test(
        'should throw ServerException.conflict and ROLLBACK all changes if year meta already exists',
        () async {
          // Arrange: Pre-existing year metadata
          await fakeFirestore
              .collection(tAnnualCol)
              .doc(tYear.toString())
              .set({'year': tYear});

          // Act & Assert
          final call = dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: [tGoalModel],
            log: tLogModel,
          );

          await expectLater(
            call,
            throwsA(isA<ServerException>().having(
              (e) => e.reason,
              'reason',
              ServerExceptionReason.conflict,
            )),
          );

          // Verify Rollback: No goals or logs should have been written
          final goalsInDb = await fakeFirestore.collection(tMonthlyCol).get();
          final logsInDb = await fakeFirestore.collection(tLogsCol).get();

          expect(goalsInDb.docs, isEmpty,
              reason: 'Transaction failed, goals should not exist');
          expect(logsInDb.docs, isEmpty,
              reason: 'Transaction failed, logs should not exist');
        },
      );
    });

    group('Error Handling & Firebase Mapping', () {
      /// Helper to inject a failing Firestore client into the DataSource
      void setupErrorEnvironment(Object firebaseError) {
        final badClient = ErrorThrowingFirestore(firebaseError);
        final mockConfig = MockFirestoreConfig();

        when(() => mockConfig.client).thenReturn(badClient);
        when(() => mockConfig.monthlyRevenueGoalsCollection)
            .thenReturn(tMonthlyCol);
        when(() => mockConfig.annualRevenueGoalsMetaCollection)
            .thenReturn(tAnnualCol);
        when(() => mockConfig.goalsActionLogsCollection).thenReturn(tLogsCol);

        dataSource = AnnualRevenueGoalFirestoreDataSource(mockConfig);
      }

      test(
          'should map "permission-denied" code to ServerExceptionReason.permissionDenied',
          () async {
        setupErrorEnvironment(
            FirebaseException(plugin: 'firestore', code: 'permission-denied'));

        expect(
          () => dataSource.createMonthlyGoalsForYear(
              year: tYear, goals: [tGoalModel], log: tLogModel),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.permissionDenied,
          )),
        );
      });

      test(
          'should map "unavailable" (network) code to ServerExceptionReason.connectionError',
          () async {
        setupErrorEnvironment(
            FirebaseException(plugin: 'firestore', code: 'unavailable'));

        expect(
          () => dataSource.createMonthlyGoalsForYear(
              year: tYear, goals: [tGoalModel], log: tLogModel),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.connectionError,
          )),
        );
      });

      test('should map unknown exceptions to ServerExceptionReason.unexpected',
          () async {
        setupErrorEnvironment(
            Exception('Memory overflow or unexpected Dart error'));

        expect(
          () => dataSource.createMonthlyGoalsForYear(
              year: tYear, goals: [tGoalModel], log: tLogModel),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.unexpected,
          )),
        );
      });
    });
  });
}
