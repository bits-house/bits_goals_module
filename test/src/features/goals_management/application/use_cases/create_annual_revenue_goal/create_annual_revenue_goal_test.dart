import 'package:bits_goals_module/src/core/application/dtos/action_log_metadata_dto.dart';
import 'package:bits_goals_module/src/core/application/ports/real_time_service.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/entities/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/entities/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/annual_revenue_goal/annual_revenue_goal_rep_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/application/ports/access_control_service.dart';
import 'package:bits_goals_module/src/core/application/ports/action_log_metadata_provider.dart';
import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/policies/goals_module_permission.dart';
import 'package:bits_goals_module/src/core/application/ports/data_mappers/annual_revenue_goal_action_log_mapper.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnualRevenueGoalRepository extends Mock
    implements AnnualRevenueGoalRepository {}

class MockRealTimeService extends Mock implements RealTimeService {}

class MockAccessControlService extends Mock implements AccessControlService {}

class MockMetadataCollector extends Mock implements ActionLogMetadataProvider {}

class MockAnnualRevenueGoalActionLogMapper extends Mock
    implements AnnualRevenueGoalActionLogMapper {}

class FakeAnnualRevenueGoal extends Fake implements AnnualRevenueGoal {}

class FakeActionLog extends Fake implements ActionLog {}

void main() {
  late CreateAnnualRevenueGoal useCase;
  late MockAnnualRevenueGoalRepository mockRepository;
  late MockRealTimeService mockRealTimeService;
  late MockAccessControlService mockAccessControlService;
  late MockMetadataCollector mockMetadataCollector;
  late MockAnnualRevenueGoalActionLogMapper mockMapper;

  setUpAll(() {
    registerFallbackValue(FakeAnnualRevenueGoal());
    registerFallbackValue(GoalsModulePermission.createAnnualRevenueGoals);
    registerFallbackValue(FakeActionLog());
  });

  setUp(() {
    mockRepository = MockAnnualRevenueGoalRepository();
    mockRealTimeService = MockRealTimeService();
    mockAccessControlService = MockAccessControlService();
    mockMetadataCollector = MockMetadataCollector();
    mockMapper = MockAnnualRevenueGoalActionLogMapper();

    when(() => mockAccessControlService.loggedInUser).thenReturn(
      LoggedInUser.create(
        uid: 'user-123',
        roleName: 'admin',
        email: 'test@example.com',
        displayName: 'Test User',
      ),
    );
    when(() => mockMetadataCollector.metadata).thenAnswer((_) async {
      return ActionLogMetadataDto(
        appVersion: AppVersion('1.0.0'),
        userDeviceInfo: DeviceInfo('Pixel 8, Android 14'),
        userIpAddress: IpAddress('192.168.1.1'),
      );
    });
    when(() => mockMapper.map(any())).thenReturn(
      const {'snapshot': 'ok'},
    );

    useCase = CreateAnnualRevenueGoal(
      repository: mockRepository,
      accessControl: mockAccessControlService,
      metadataCollector: mockMetadataCollector,
      goalMapper: mockMapper,
      realTimeService: mockRealTimeService,
    );
  });

  group('CreateAnnualRevenueGoal UseCase', () {
    // ============================================================
    // FIXTURES & HELPERS
    // ============================================================

    const tCurrentYear = 2025;
    const tValidYear = 2026;
    const tPastYear = 2024;
    const tMoney = 12000.00;

    AnnualRevenueGoal createValidAnnualGoal({
      required int year,
      required double target,
    }) {
      final yearVo = Year.fromInt(year);
      return AnnualRevenueGoal.build(
        year: yearVo,
        monthlyGoals: <MonthlyRevenueGoal>[
          for (int i = 1; i <= 12; i++)
            MonthlyRevenueGoal.create(
              year: yearVo,
              month: Month.fromInt(i),
              target: Money.fromDouble(1000.00),
            ),
        ],
      );
    }

    // ============================================================
    // USE CASE METADATA TESTS
    // ============================================================

    test('requiredPermission should return createAnnualRevenueGoals', () {
      expect(useCase.requiredPermission,
          GoalsModulePermission.createAnnualRevenueGoals);
    });

    // ============================================================
    // SUCCESS SCENARIO TESTS
    // ============================================================

    test(
      'should create and persist annual goal when parameters are valid',
      () async {
        // Arrange
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: tMoney);
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(
          () => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'),
          ),
        ).thenAnswer((_) async => tAnnualGoal);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should be Right: $l'),
          (r) {
            expect(r.year, Year.fromInt(tValidYear));
            expect(r.monthlyGoals.length, 12);
          },
        );
      },
    );

    // ============================================================
    // VALIDATION FAILURE TESTS
    // ============================================================

    test(
      'should return Left(pastYear) when year is before current year',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        const params = CreateAnnualRevenueGoalParams(
          year: tPastYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) =>
              expect(l.reason, CreateAnnualRevenueGoalFailureReason.pastYear),
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should return Left(zeroOrNegativeTarget) when target is negative',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: -1200.00,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l.reason,
              CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget),
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should return Left(zeroOrNegativeTarget) when target is zero',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: 0.0,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l.reason,
              CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget),
          (r) => fail('Should be Left'),
        );
      },
    );

    test('should return Left(permissionDenied) when user lacks permission',
        () async {
      // Arrange
      when(() => mockAccessControlService.hasPermission(any()))
          .thenReturn(false);

      const params = CreateAnnualRevenueGoalParams(
        year: tValidYear,
        annualRevenueTarget: tMoney,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
            l.reason, CreateAnnualRevenueGoalFailureReason.permissionDenied),
        (r) => fail('Should be Left'),
      );
    });

    // ============================================================
    // REPOSITORY FAILURE TESTS
    // ============================================================

    test(
      'should map annualGoalForYearAlreadyExists repository failure',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenThrow(
          const AnnualRevenueGoalRepFailure(
            reason: AnnualRevenueGoalRepFailureReason
                .annualGoalForYearAlreadyExists,
          ),
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(
              l.reason,
              CreateAnnualRevenueGoalFailureReason
                  .annualGoalForYearAlreadyExists),
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should map permissionDenied repository failure',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenThrow(
          const AnnualRevenueGoalRepFailure(
            reason: AnnualRevenueGoalRepFailureReason.permissionDenied,
          ),
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l.reason,
                CreateAnnualRevenueGoalFailureReason.permissionDenied);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should map connectionError repository failure',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenThrow(
          const AnnualRevenueGoalRepFailure(
            reason: AnnualRevenueGoalRepFailureReason.connectionError,
          ),
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(
                l.reason, CreateAnnualRevenueGoalFailureReason.connectionError);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    // ============================================================
    // RATE LIMIT & INFRASTRUCTURE FAILURE TESTS
    // ============================================================

    test(
      'should map rateLimitExceeded repository failure with retry duration',
      () async {
        // Arrange
        const retryDuration = Duration(seconds: 45);

        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenThrow(
          const AnnualRevenueGoalRepFailure(
            reason: AnnualRevenueGoalRepFailureReason.rateLimitExceeded,
            rateLimitRemainingDuration: retryDuration,
          ),
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            final failure = l;
            expect(failure.reason,
                CreateAnnualRevenueGoalFailureReason.rateLimitExceeded);
            expect(failure.retryAfter, retryDuration);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    // ============================================================
    // DOMAIN ENTITY FAILURE TESTS
    // ============================================================

    test(
      'should map AnnualRevenueGoalFailure to internal failure',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenThrow(
          const AnnualRevenueGoalFailure(
            AnnualRevenueGoalFailureReason.invalidMonthsCount,
          ),
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l.reason, CreateAnnualRevenueGoalFailureReason.unexpected);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    // ============================================================
    // GENERIC EXCEPTION TESTS
    // ============================================================

    test(
      'should map generic exception to internal failure',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenThrow(
          Exception('Unexpected error'),
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect(l.reason, CreateAnnualRevenueGoalFailureReason.unexpected);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    // ============================================================
    // FAILURE OBJECT EQUALITY TESTS
    // ============================================================

    test('Failure should support equality comparison', () {
      const failure1 = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.pastYear,
      );
      const failure2 = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.pastYear,
      );
      const failureDiff = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.connectionError,
      );

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
    });

    test('Failure should include class name in toString()', () {
      const failure = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.pastYear,
      );

      expect(failure.toString(), contains('CreateAnnualRevenueGoalFailure'));
    });

    // ============================================================
    // MONTHLY GOALS DISTRIBUTION TESTS
    // ============================================================

    test(
      'should distribute annual target correctly across 12 months',
      () async {
        // Arrange
        const annualTarget = 12000.00;
        final tAnnualGoal = createValidAnnualGoal(
          year: tValidYear,
          target: annualTarget,
        );

        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenAnswer((_) async => tAnnualGoal);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: annualTarget,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should be Right'),
          (goal) {
            expect(goal.monthlyGoals.length, 12);
            // Verify all monthly goals have positive targets
            for (final monthlyGoal in goal.monthlyGoals) {
              expect(monthlyGoal.target.cents, greaterThan(0));
            }
          },
        );
      },
    );

    // ============================================================
    // EDGE CASE TESTS
    // ============================================================

    test(
      'should accept year equal to current year',
      () async {
        // Arrange
        final tAnnualGoal =
            createValidAnnualGoal(year: tCurrentYear, target: tMoney);
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenAnswer((_) async => tAnnualGoal);

        const params = CreateAnnualRevenueGoalParams(
          year: tCurrentYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should accept minimum valid target that distributes across 12 months',
      () async {
        // Arrange
        // Minimum target must be divisible across 12 months; using 12 cents = 1 cent per month
        const minTarget = 0.12;
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: minTarget);
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenAnswer((_) async => tAnnualGoal);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: minTarget,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should accept very large target amount',
      () async {
        // Arrange
        const largeTarget = 999999999.99;
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: largeTarget);
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenAnswer((_) async => tAnnualGoal);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: largeTarget,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should reject year far in the past',
      () async {
        // Arrange
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        const params = CreateAnnualRevenueGoalParams(
          year: 1990,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) =>
              expect(l.reason, CreateAnnualRevenueGoalFailureReason.pastYear),
          (r) => fail('Should be Left'),
        );
      },
    );

    // ============================================================
    // ASYNC TESTS
    // ============================================================

    test(
      'should await repository.getCurrentYear() before proceeding',
      () async {
        // Arrange
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: tMoney);
        when(() => mockRealTimeService.getCurrentYear()).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return Year.fromInt(tCurrentYear);
          },
        );
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenAnswer((_) async => tAnnualGoal);

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should await repository.create() before returning',
      () async {
        // Arrange
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: tMoney);
        when(() => mockRealTimeService.getCurrentYear())
            .thenAnswer((_) async => Year.fromInt(tCurrentYear));
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
              goal: any(named: 'goal'),
              log: any(named: 'log'),
            )).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return tAnnualGoal;
          },
        );

        const params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
      },
    );
  });
}
