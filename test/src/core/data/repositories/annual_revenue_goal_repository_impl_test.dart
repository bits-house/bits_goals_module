import 'package:bits_goals_module/src/core/data/data_sources/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/data/repositories/annual_revenue_goal_repository_impl.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/platform/network_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// =============================================================================
// MOCKS & FAKES
// =============================================================================

class MockRemoteDataSource extends Mock
    implements AnnualRevenueGoalRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeMonthlyGoalList extends Fake
    implements List<MonthlyRevenueGoalRemoteModel> {}

// =============================================================================
// TEST SUITE
// =============================================================================

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late AnnualRevenueGoalRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeMonthlyGoalList());
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AnnualRevenueGoalRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  AnnualRevenueGoal createValidAggregate() {
    final tYear = Year.fromInt(2026);
    final months = List.generate(12, (index) {
      return MonthlyRevenueGoal.create(
        month: Month.fromInt(index + 1),
        target: Money.fromCents(100000),
        year: tYear,
      );
    });
    return AnnualRevenueGoal.create(year: tYear, monthlyGoals: months);
  }

  group('AnnualRevenueGoalRepositoryImpl', () {
    // =========================================================================
    // METHOD: create
    // =========================================================================
    group('create', () {
      test(
        'should decompose the Aggregate into 12 Models and call the RemoteDataSource with the correct list',
        () async {
          // Arrange
          final aggregate = createValidAggregate();

          when(() => mockRemoteDataSource.createMonthlyGoalsForYear(
                year: any(named: 'year', that: equals(aggregate.year.value)),
                goals: any(named: 'goals'),
              )).thenAnswer((_) async {});
          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Act
          final result = await repository.create(aggregate);

          // Assert
          expect(result, equals(aggregate));

          verify(() => mockRemoteDataSource.createMonthlyGoalsForYear(
                year: any(named: 'year', that: equals(aggregate.year.value)),
                goals: any(
                  named: 'goals',
                  that: isA<List<MonthlyRevenueGoalRemoteModel>>()
                      .having((list) => list.length, 'length', 12)
                      .having(
                          (list) => list.first.target.cents, 'cents', 100000),
                ),
              )).called(1);
          verify(() => mockNetworkInfo.isConnected).called(1);
        },
      );

      test(
        'should throw [RepositoryFailure] with [annualGoalForYearAlreadyExists] when DataSource indicates conflict',
        () async {
          // Arrange
          final aggregate = createValidAggregate();

          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
            ),
          ).thenThrow(
            ServerException(reason: ServerExceptionReason.conflict),
          );
          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Act
          final call = repository.create;

          // Assert
          expect(
            () => call(aggregate),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.annualGoalForYearAlreadyExists,
              ),
            ),
          );
          verify(() => mockNetworkInfo.isConnected).called(1);
        },
      );

      test(
        'should throw [RepositoryFailure] with [infra] reason when an unexpected exception occurs',
        () async {
          // Arrange
          final aggregate = createValidAggregate();

          when(() => mockRemoteDataSource.createMonthlyGoalsForYear(
                year: any(named: 'year'),
                goals: any(named: 'goals'),
              )).thenThrow(Exception('Firestore Connection Error'));
          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Act
          final call = repository.create;

          // Assert
          expect(
            () => call(aggregate),
            throwsA(isA<RepositoryFailure>()),
          );
          verify(() => mockNetworkInfo.isConnected).called(1);
        },
      );

      test(
          'should throw [RepositoryFailure] with [permissionDenied] reason when DataSource indicates permission denied',
          () async {
        // Arrange
        final aggregate = createValidAggregate();

        when(
          () => mockRemoteDataSource.createMonthlyGoalsForYear(
            year: any(named: 'year'),
            goals: any(named: 'goals'),
          ),
        ).thenThrow(
          ServerException(reason: ServerExceptionReason.permissionDenied),
        );
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Act
        final call = repository.create;

        // Assert
        expect(
          () => call(aggregate),
          throwsA(
            isA<RepositoryFailure>().having(
              (f) => f.reason,
              'reason',
              RepositoryFailureReason.permissionDenied,
            ),
          ),
        );
        verify(() => mockNetworkInfo.isConnected).called(1);
      });
    });

    test(
        'should throw [RepositoryFailure] with [connectionError] reason when unexpected ServerException is thrown',
        () async {
      // Arrange
      final aggregate = createValidAggregate();

      when(
        () => mockRemoteDataSource.createMonthlyGoalsForYear(
          year: any(named: 'year'),
          goals: any(named: 'goals'),
        ),
      ).thenThrow(
        ServerException(reason: ServerExceptionReason.unexpected),
      );
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // Act
      final call = repository.create;

      // Assert
      expect(
        () => call(aggregate),
        throwsA(
          isA<RepositoryFailure>().having(
            (f) => f.reason,
            'reason',
            RepositoryFailureReason.connectionError,
          ),
        ),
      );
      verify(() => mockNetworkInfo.isConnected).called(1);
    });

    group('create (Offline)', () {
      test(
        'should throw [RepositoryFailure] with [connectionError] reason AND NOT call remote data source',
        () async {
          // Arrange
          final aggregate = createValidAggregate();

          when(() => mockNetworkInfo.isConnected)
              .thenAnswer((_) async => false);

          // Act
          final call = repository.create;

          // Assert
          expect(
            () => call(aggregate),
            throwsA(isA<RepositoryFailure>().having(
              (f) => f.reason,
              'reason',
              RepositoryFailureReason.connectionError,
            )),
          );

          verifyZeroInteractions(mockRemoteDataSource);
          verify(() => mockNetworkInfo.isConnected).called(1);
        },
      );
    });

    // =========================================================================
    // METHOD: getCurrentYear
    // =========================================================================
    group('getCurrentYear', () {
      test(
        'should return the correct [Year] value object retrieved from DataSource',
        () async {
          // Arrange
          const tServerYear = 2025;
          when(() => mockRemoteDataSource.getCurrentYear())
              .thenAnswer((_) async => tServerYear);
          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Act
          final result = await repository.getCurrentYear();

          // Assert
          expect(result, isA<Year>());
          expect(result.value, equals(tServerYear));
          verify(() => mockRemoteDataSource.getCurrentYear()).called(1);
        },
      );

      test(
        'should throw [RepositoryFailure] when DataSource fails',
        () async {
          // Arrange
          when(() => mockRemoteDataSource.getCurrentYear())
              .thenThrow(Exception('Time out'));
          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Act
          final call = repository.getCurrentYear;

          // Assert
          expect(() => call(), throwsA(isA<RepositoryFailure>()));
        },
      );

      test(
        'should throw [RepositoryFailure] with [connectionError] reason AND NOT call remote data source when offline',
        () async {
          // Arrange
          when(() => mockNetworkInfo.isConnected)
              .thenAnswer((_) async => false);

          // Act
          final call = repository.getCurrentYear;

          // Assert
          expect(
            () => call(),
            throwsA(isA<RepositoryFailure>().having(
              (f) => f.reason,
              'reason',
              RepositoryFailureReason.connectionError,
            )),
          );

          verifyZeroInteractions(mockRemoteDataSource);
          verify(() => mockNetworkInfo.isConnected).called(1);
        },
      );
    });
  });
}
