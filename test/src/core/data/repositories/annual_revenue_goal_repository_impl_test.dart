import 'package:bits_goals_module/src/core/application/exceptions/rate_limiter_exception.dart';
import 'package:bits_goals_module/src/core/data/data_sources/annual_revenue_goal_remote_data_source.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:bits_goals_module/src/core/data/models/action_log_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/data/repositories/annual_revenue_goal_repository_impl.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_type.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/core/domain/policies/goals_module_permission.dart';
import 'package:bits_goals_module/src/core/application/ports/infra_services/network_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// =============================================================================
// MOCKS & FAKES
// =============================================================================

class MockRemoteDataSource extends Mock
    implements AnnualRevenueGoalRemoteDataSource {}

class MockNetworkService extends Mock implements NetworkService {}

class FakeMonthlyGoalList extends Fake
    implements List<MonthlyRevenueGoalRemoteModel> {}

class FakeActionLogModel extends Fake implements ActionLogModel {}

class FakeAnnualRevenueGoal extends Fake implements AnnualRevenueGoal {}

// =============================================================================
// TEST SUITE
// =============================================================================

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late MockNetworkService mockNetworkService;
  late AnnualRevenueGoalRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeMonthlyGoalList());
    registerFallbackValue(FakeActionLogModel());
    registerFallbackValue(FakeAnnualRevenueGoal());
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockNetworkService = MockNetworkService();

    repository = AnnualRevenueGoalRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkService: mockNetworkService,
    );
  });

  ActionLog createValidLog({
    required GoalsModulePermission requiredPermission,
  }) {
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
      requiredPermission: requiredPermission,
      actionType: ActionType.create,
      useCaseId: 'create_annual_revenue_goal',
      newDataMapped: const {'snapshot': 'ok'},
    );
  }

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

  group('AnnualRevenueGoalRepositoryImpl', () {
    group('create', () {
      test(
        'should return goal when create succeeds with online connection',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenAnswer((_) async {});

          // Act
          final result = await repository.create(
            goal: aggregate,
            log: log,
          );

          // Assert
          expect(result, equals(aggregate));
          verify(() => mockNetworkService.isConnected).called(1);
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
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await repository.create(
            goal: aggregate,
            log: log,
          );

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
        'should throw AnnualRevenueGoalRepFailure with conflict reason when goal exists',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
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
            () => repository.create(
              goal: aggregate,
              log: log,
            ),
            throwsA(
              isA<AnnualRevenueGoalRepFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalRepFailureReason
                    .annualGoalForYearAlreadyExists,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalRepFailure with rateLimitExceeded reason and duration when rate limited',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          const waitDuration = Duration(seconds: 42);

          const rateLimitException = RateLimiterException(
            functionId: 'create_goals',
            remainingDuration: waitDuration,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);

          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenThrow(rateLimitException);

          // Act & Assert
          expect(
            () => repository.create(
              goal: aggregate,
              log: log,
            ),
            throwsA(
              isA<AnnualRevenueGoalRepFailure>()
                  .having(
                    (f) => f.reason,
                    'reason',
                    AnnualRevenueGoalRepFailureReason.rateLimitExceeded,
                  )
                  .having(
                    (f) => f.rateLimitRemainingDuration,
                    'rateLimitRemainingDuration',
                    waitDuration,
                  ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalRepFailure with permissionDenied reason when access denied',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
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
            () => repository.create(
              goal: aggregate,
              log: log,
            ),
            throwsA(
              isA<AnnualRevenueGoalRepFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalRepFailureReason.permissionDenied,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalRepFailure with connectionError for unexpected ServerException',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
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
            () => repository.create(
              goal: aggregate,
              log: log,
            ),
            throwsA(
              isA<AnnualRevenueGoalRepFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalRepFailureReason.connectionError,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalRepFailure with connectionError for generic exception',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );
          final exception = Exception('Generic error');

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenThrow(exception);

          // Act & Assert
          expect(
            () => repository.create(
              goal: aggregate,
              log: log,
            ),
            throwsA(
              isA<AnnualRevenueGoalRepFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalRepFailureReason.connectionError,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalRepFailure when offline',
        () async {
          // Arrange
          final aggregate = createValidAggregate();
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => false);

          // Act & Assert
          expect(
            () => repository.create(
              goal: aggregate,
              log: log,
            ),
            throwsA(
              isA<AnnualRevenueGoalRepFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalRepFailureReason.connectionError,
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
          final log = createValidLog(
            requiredPermission: GoalsModulePermission.manageGlobalGoals,
          );

          when(() => mockNetworkService.isConnected)
              .thenAnswer((_) async => true);
          when(
            () => mockRemoteDataSource.createMonthlyGoalsForYear(
              year: any(named: 'year'),
              goals: any(named: 'goals'),
              log: any(named: 'log'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await repository.create(
            goal: aggregate,
            log: log,
          );

          // Assert
          verify(() => mockNetworkService.isConnected).called(1);
        },
      );
    });
  });
}
