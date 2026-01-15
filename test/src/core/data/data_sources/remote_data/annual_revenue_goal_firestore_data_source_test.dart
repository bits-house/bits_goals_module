import 'package:bits_goals_module/src/core/data/data_sources/remote_data/annual_revenue_goal_firestore_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// HELPER: ErrorThrowingFirestore
// =============================================================================
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

// =============================================================================
// TESTS
// =============================================================================

void main() {
  late AnnualRevenueGoalFirestoreDataSource dataSource;
  late FakeFirebaseFirestore fakeFirestore;

  const kCollectionData =
      AnnualRevenueGoalFirestoreDataSource.monthlyCollection;
  const kCollectionMeta = AnnualRevenueGoalFirestoreDataSource.annualMeta;

  // Test Data
  final tGoalModel1 = MonthlyRevenueGoalRemoteModel.fromEntity(
    MonthlyRevenueGoal.create(
      id: IdUuidV7.fromString('018b1f3c-8c08-7e3f-9b0d-7b2f4c6e8a1d'),
      month: Month.fromInt(1),
      year: Year.fromInt(2026),
      target: Money.fromCents(50000),
      progress: Money.fromCents(0),
    ),
  );

  final tGoalModel2 = MonthlyRevenueGoalRemoteModel.fromEntity(
    MonthlyRevenueGoal.create(
      id: IdUuidV7.fromString('018b1f3c-8c08-7e3f-9b0d-7b2f4c6e8a1e'),
      month: Month.fromInt(2),
      year: Year.fromInt(2026),
      target: Money.fromCents(60000),
      progress: Money.fromCents(0),
    ),
  );

  final tGoalsList = [tGoalModel1, tGoalModel2];
  const tYear = 2026;

  // ===========================================================================
  // GROUP 1: LOGIC & SUCCESS (Uses FakeFirestore)
  // ===========================================================================
  group('AnnualRevenueGoalFirestoreDataSource (Business Logic)', () {
    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = AnnualRevenueGoalFirestoreDataSource(fakeFirestore);
    });

    test(
      'should save meta-data AND monthly goals successfully when year is new',
      () async {
        // Act
        await dataSource.createMonthlyGoalsForYear(
          year: tYear,
          goals: tGoalsList,
        );

        // Assert 1: Meta document created
        final metaSnapshot = await fakeFirestore
            .collection(kCollectionMeta)
            .doc(tYear.toString())
            .get();

        expect(metaSnapshot.exists, isTrue);
        expect(metaSnapshot.data()?['year'], equals(tYear));

        // Assert 2: All Monthly goals created
        final goal1Snapshot = await fakeFirestore
            .collection(kCollectionData)
            .doc(tGoalModel1.uuidV7.value)
            .get();
        final goal2Snapshot = await fakeFirestore
            .collection(kCollectionData)
            .doc(tGoalModel2.uuidV7.value)
            .get();

        expect(goal1Snapshot.exists, isTrue);
        expect(goal1Snapshot.data()?['target_cents'], 50000);

        expect(goal2Snapshot.exists, isTrue);
        expect(goal2Snapshot.data()?['target_cents'], 60000);
      },
    );

    test(
      'should throw [ServerException(conflict)] AND NOT save data if year exists',
      () async {
        // Arrange: Pre-populate the meta document to simulate existing year
        await fakeFirestore
            .collection(kCollectionMeta)
            .doc(tYear.toString())
            .set({'year': tYear});

        // Act & Assert
        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: tGoalsList,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.conflict,
          )),
        );

        // Assert Logic: Ensure the monthly goals were NOT created (Atomicity check)
        final goalSnapshot = await fakeFirestore
            .collection(kCollectionData)
            .doc(tGoalModel1.uuidV7.value)
            .get();

        expect(goalSnapshot.exists, isFalse,
            reason: 'Should not write goals if conflict occurs');
      },
    );
  });

  // ===========================================================================
  // GROUP 2: EXCEPTION HANDLING (Uses ErrorThrowingFirestore)
  // ===========================================================================

  group('AnnualRevenueGoalFirestoreDataSource (Exception Handling)', () {
    test(
      'should throw [ServerException(permissionDenied)] when Firestore throws permission-denied',
      () {
        // Arrange
        final badFirestore = ErrorThrowingFirestore(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );
        dataSource = AnnualRevenueGoalFirestoreDataSource(badFirestore);

        // Act & Assert
        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: tGoalsList,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.permissionDenied,
          )),
        );
      },
    );

    test(
      'should throw [ServerException(connectionError)] when Firestore throws unavailable/other',
      () {
        // Arrange
        final badFirestore = ErrorThrowingFirestore(
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
        );
        dataSource = AnnualRevenueGoalFirestoreDataSource(badFirestore);

        // Act & Assert
        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: tGoalsList,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.connectionError,
          )),
        );
      },
    );

    test(
      'should throw [ServerException(unexpected)] when a non-Firebase exception occurs',
      () {
        // Arrange
        final badFirestore = ErrorThrowingFirestore(
          Exception('Some generic dart error parsing json or whatever'),
        );
        dataSource = AnnualRevenueGoalFirestoreDataSource(badFirestore);

        // Act & Assert
        expect(
          () => dataSource.createMonthlyGoalsForYear(
            year: tYear,
            goals: tGoalsList,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.reason,
            'reason',
            ServerExceptionReason.unexpected,
          )),
        );
      },
    );
  });
}
