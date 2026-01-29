import 'package:bits_goals_module/src/core/data/data_sources/remote_data/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/data/repositories/annual_revenue_goal_repository_impl.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_type.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:bits_goals_module/src/infra/platform/network_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// =============================================================================
// MOCKS & FAKES
// =============================================================================

class MockRemoteDataSource extends Mock
    implements AnnualRevenueGoalRemoteDataSource {}

class MockRemoteTimeDataSource extends Mock implements RemoteTimeDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeMonthlyGoalList extends Fake
    implements List<MonthlyRevenueGoalRemoteModel> {}

class FakeActionLogModel extends Fake implements ActionLogModel {}

// =============================================================================
// TEST SUITE
// =============================================================================

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late MockRemoteTimeDataSource mockRemoteTimeDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late AnnualRevenueGoalRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeMonthlyGoalList());
    registerFallbackValue(FakeActionLogModel());
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockRemoteTimeDataSource = MockRemoteTimeDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AnnualRevenueGoalRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
      remoteTimeDataSource: mockRemoteTimeDataSource,
    );
  });

  AnnualRevenueGoal createValidAggregate({Year? year}) {
    final tYear = year ?? Year.fromInt(2026);
    final months = List.generate(12, (index) {
      return MonthlyRevenueGoal.create(
        month: Month.fromInt(index + 1),
        target: Money.fromCents(100000),
        year: tYear,
      );
    });
    return AnnualRevenueGoal.build(year: tYear, monthlyGoals: months);
  }

  ActionLog createValidActionLog() {
    return ActionLog.create(
      user: LoggedInUser.create(
        uid: 'user-123',
        roleName: 'admin',
        email: 'test@example.com',
        displayName: 'Test User',
      ),
      userIpAddress: IpAddress('192.168.1.1'),
      userDeviceInfo: DeviceInfo('iPhone 13, iOS 15.4'),
      appVersion: AppVersion('1.0.0'),
      requiredPermission: GoalsModulePermission.values.first,
      actionType: ActionType.create,
      useCaseId: 'create-annual-revenue-goal',
      newDataMapped: const {'year': 2026, 'target': 100000},
    );
  }

  group('AnnualRevenueGoalRepositoryImpl', () {
    group('create', () {
      test(
        'should return goal when create succeeds with online connection',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenAnswer((_) async {});

          // Act
          final result = await repository.create(goal: aggregate, log: log);

          // Assert
          expect(result, equals(aggregate));
          verify(() => mockNetworkInfo.isConnected).called(1);
          verify(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).called(1);
        },
      );

      test(
        'should decompose aggregate into 12 monthly models correctly',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await repository.create(goal: aggregate, log: log);

          // Assert
          verify(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: aggregate.year.value,
              goals: any(
                named: 'goals',
                that: isA<List<MonthlyRevenueGoalRemoteModel>>()
                    .having((g) => g.length, 'length', 12),
              ),
              log: any(named: 'log'),
            ),
          ).called(1);
        },
      );

      test(
        'should throw RepositoryFailure with conflict reason when goal exists',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenThrow(
            const ServerException(reason: ServerExceptionReason.conflict),
          );

          // Act & Assert
          expect(
            () => repository.create(goal: aggregate, log: log),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.annualGoalForYearAlreadyExists,
              ),
            ),
          );
        },
      );

      test(
        'should throw RepositoryFailure with permissionDenied reason when access denied',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenThrow(
            const ServerException(
              reason: ServerExceptionReason.permissionDenied,
            ),
          );

          // Act & Assert
          expect(
            () => repository.create(goal: aggregate, log: log),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.permissionDenied,
              ),
            ),
          );
        },
      );

      test(
        'should throw RepositoryFailure with connectionError for unexpected ServerException',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenThrow(
            const ServerException(reason: ServerExceptionReason.unexpected),
          );

          // Act & Assert
          expect(
            () => repository.create(goal: aggregate, log: log),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.connectionError,
              ),
            ),
          );
        },
      );

      test(
        'should throw RepositoryFailure with connectionError for generic exception',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();
          final exception = Exception('Generic error');

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => repository.create(goal: aggregate, log: log),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.connectionError,
              ),
            ),
          );
        },
      );

      test(
        'should throw RepositoryFailure when offline',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected)
              .thenAnswer((_) async => false);

          // Act & Assert
          expect(
            () => repository.create(goal: aggregate, log: log),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.connectionError,
              ),
            ),
          );

          verifyNever(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          );
        },
      );

      test(
        'should verify network check before data source call',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidActionLog();

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await repository.create(goal: aggregate, log: log);

          // Assert
          verify(() => mockNetworkInfo.isConnected).called(1);
        },
      );
    });

    group('getCurrentYear', () {
      test(
        'should return year when request succeeds',
        () async {
          // Arrange
          const serverYear = 2025;

          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(() => mockRemoteTimeDataSource.getCurrentYear())
              .thenAnswer((_) async => serverYear);

          // Act
          final result = await repository.getCurrentYear();

          // Assert
          expect(result, isA<Year>());
          expect(result.value, equals(serverYear));
          verify(() => mockNetworkInfo.isConnected).called(1);
          verify(() => mockRemoteTimeDataSource.getCurrentYear()).called(1);
        },
      );

      test(
        'should throw RepositoryFailure when data source fails',
        () async {
          // Arrange
          when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(() => mockRemoteTimeDataSource.getCurrentYear())
              .thenThrow(Exception('Network error'));

          // Act & Assert
          expect(
            () => repository.getCurrentYear(),
            throwsA(isA<RepositoryFailure>()),
          );
        },
      );

      test(
        'should throw RepositoryFailure with connectionError when offline',
        () async {
          // Arrange
          when(() => mockNetworkInfo.isConnected)
              .thenAnswer((_) async => false);

          // Act & Assert
          expect(
            () => repository.getCurrentYear(),
            throwsA(
              isA<RepositoryFailure>().having(
                (f) => f.reason,
                'reason',
                RepositoryFailureReason.connectionError,
              ),
            ),
          );

          verifyNever(() => mockRemoteTimeDataSource.getCurrentYear());
        },
      );

      test(
        'should not call time data source when offline',
        () async {
          // Arrange
          when(() => mockNetworkInfo.isConnected)
              .thenAnswer((_) async => false);

          // Act
          try {
            await repository.getCurrentYear();
          } catch (_) {}

          // Assert
          verifyNever(() => mockRemoteTimeDataSource.getCurrentYear());
        },
      );
    });
  });
}
