import 'package:bits_goals_module/src/infra/config/data_sources/firestore_config.dart';
import 'package:bits_goals_module/src/infra/config/data_sources/remote_data_src_config.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreConfig', () {
    const String tMonthlyCollection = 'monthly_goals_test';
    const String tAnnualCollection = 'annual_meta_test';
    const String tLogsCollection = 'action_logs_test';

    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('should create FirestoreConfig with correct values', () {
      // Act
      final config = FirestoreConfig(
        firestore: fakeFirestore,
        monthlyRevenueGoalsCollectionName: tMonthlyCollection,
        annualRevenueGoalsMetaCollectionName: tAnnualCollection,
        goalsActionLogsCollectionName: tLogsCollection,
      );

      // Assert
      expect(config.client, equals(fakeFirestore));
      expect(config.monthlyRevenueGoalsCollection, equals(tMonthlyCollection));
      expect(
          config.annualRevenueGoalsMetaCollection, equals(tAnnualCollection));
      expect(config.goalsActionLogsCollection, equals(tLogsCollection));
    });

    test(
        'should ensure the returned client is the same as the injected one (Singleton/Reference)',
        () {
      // Arrange
      final config = FirestoreConfig(
        firestore: fakeFirestore,
        monthlyRevenueGoalsCollectionName: tMonthlyCollection,
        annualRevenueGoalsMetaCollectionName: tAnnualCollection,
        goalsActionLogsCollectionName: tLogsCollection,
      );

      // Assert
      // Verifying reference equality
      expect(config.client, same(fakeFirestore));
    });

    test(
        'should maintain the integrity of collection names even with similar strings',
        () {
      // Arrange
      const String collectionA = 'goals_v1';
      const String collectionB = 'goals_v2';
      const String collectionC = 'goals_logs';

      // Act
      final config = FirestoreConfig(
        firestore: fakeFirestore,
        monthlyRevenueGoalsCollectionName: collectionA,
        annualRevenueGoalsMetaCollectionName: collectionB,
        goalsActionLogsCollectionName: collectionC,
      );

      // Assert
      expect(config.monthlyRevenueGoalsCollection, equals(collectionA));
      expect(config.annualRevenueGoalsMetaCollection, equals(collectionB));
      expect(config.goalsActionLogsCollection, equals(collectionC));

      // Negative check: ensure no internal assignment mix-up
      expect(config.monthlyRevenueGoalsCollection, isNot(equals(collectionB)));
    });

    test(
        'should allow retrieval of the client through the RemoteDataSourceConfig interface',
        () {
      // Arrange
      final RemoteDataSourceConfig config = FirestoreConfig(
        firestore: fakeFirestore,
        monthlyRevenueGoalsCollectionName: tMonthlyCollection,
        annualRevenueGoalsMetaCollectionName: tAnnualCollection,
        goalsActionLogsCollectionName: tLogsCollection,
      );

      // Act & Assert
      // Verifying if the interface override getter is working
      expect(config.client, isA<FakeFirebaseFirestore>());
    });

    test('should throw AssertionError when any collection name is empty', () {
      // Arrange
      const String validName = 'valid_collection';
      const String emptyName = '';

      // Assert - Test for Monthly Revenue Goals
      expect(
        () => FirestoreConfig(
          firestore: fakeFirestore,
          monthlyRevenueGoalsCollectionName: emptyName,
          annualRevenueGoalsMetaCollectionName: validName,
          goalsActionLogsCollectionName: validName,
        ),
        throwsAssertionError,
      );

      // Assert - Test for Annual Revenue Meta
      expect(
        () => FirestoreConfig(
          firestore: fakeFirestore,
          monthlyRevenueGoalsCollectionName: validName,
          annualRevenueGoalsMetaCollectionName: emptyName,
          goalsActionLogsCollectionName: validName,
        ),
        throwsAssertionError,
      );

      // Assert - Test for Action Logs
      expect(
        () => FirestoreConfig(
          firestore: fakeFirestore,
          monthlyRevenueGoalsCollectionName: validName,
          annualRevenueGoalsMetaCollectionName: validName,
          goalsActionLogsCollectionName: emptyName,
        ),
        throwsAssertionError,
      );
    });
  });
}
