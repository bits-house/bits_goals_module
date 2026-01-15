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
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AnnualRevenueGoalFirestoreDataSource dataSource;

  const kCollectionData = 'monthly_revenue_goals';
  const kCollectionMeta = 'annual_revenue_goals_meta';

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
  // FakeFirestore - Logic
  // ===========================================================================
  group('AnnualRevenueGoalFirestoreDataSource (Logic with FakeFirestore)', () {
    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = AnnualRevenueGoalFirestoreDataSource(fakeFirestore);
    });

    test(
      'should save data successfully when the year does not exist yet',
      () async {
        // Act
        await dataSource.createMonthlyGoalsForYear(
          year: tYear,
          goals: tGoalsList,
        );

        // Assert
        final metaSnapshot = await fakeFirestore
            .collection(kCollectionMeta)
            .doc(tYear.toString())
            .get();

        expect(metaSnapshot.exists, isTrue);
        expect(metaSnapshot.data()?['year'], equals(tYear));

        final goal1Snapshot = await fakeFirestore
            .collection(kCollectionData)
            .doc(tGoalModel1.uuidV7.value)
            .get();

        expect(goal1Snapshot.exists, isTrue);
        expect(goal1Snapshot.data()?['target_cents'],
            equals(tGoalModel1.target.cents));
      },
    );

    test(
      'should throw [ServerException(conflict)] if the year already exists',
      () async {
        // Arrange
        await fakeFirestore
            .collection(kCollectionMeta)
            .doc(tYear.toString())
            .set({'year': tYear, 'created_at': DateTime.now()});

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
      },
    );
  });

  // ===========================================================================
  // Errors with Mocktail
  // ===========================================================================
  group('AnnualRevenueGoalFirestoreDataSource (Errors with Mocktail)', () {
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      dataSource = AnnualRevenueGoalFirestoreDataSource(mockFirestore);
    });

    test(
      'should throw [ServerException(permissionDenied)] when transaction fails with permission-denied',
      () async {
        // Arrange
        // We only mock the entry of the transaction.
        // Since it fails immediately, we don't need to mock Collection/Doc References.
        when(() => mockFirestore.runTransaction(any())).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );

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
      'should throw [ServerException(connectionError)] when Firestore throws generic error',
      () async {
        // Arrange
        when(() => mockFirestore.runTransaction(any())).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
        );

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
  });
}
