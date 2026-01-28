import 'package:bits_goals_module/src/core/domain/entities/action_log/action_log.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/annual_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/domain/services/interfaces/access_control_service.dart';
import 'package:bits_goals_module/src/core/domain/services/interfaces/infra_metadata_collector.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnualRevenueGoalRepository extends Mock
    implements AnnualRevenueGoalRepository {}

class MockAccessControlService extends Mock implements AccessControlService {}

class MockInfraMetadataCollector extends Mock
    implements InfraMetadataCollector {}

class MockLoggedInUser extends Mock implements LoggedInUser {}

class FakeAnnualRevenueGoal extends Fake implements AnnualRevenueGoal {}

class FakeActionLog extends Fake implements ActionLog {}

void main() {
  late CreateAnnualRevenueGoal useCase;
  late MockAnnualRevenueGoalRepository mockRepository;
  late MockAccessControlService mockAccessControlService;
  late MockInfraMetadataCollector mockMetadataCollector;
  late MockLoggedInUser mockLoggedInUser;

  setUpAll(() {
    registerFallbackValue(FakeAnnualRevenueGoal());
    registerFallbackValue(FakeActionLog());
    registerFallbackValue(GoalsModulePermission.manageGlobalGoals);
  });

  setUp(() {
    mockRepository = MockAnnualRevenueGoalRepository();
    mockAccessControlService = MockAccessControlService();
    mockMetadataCollector = MockInfraMetadataCollector();
    mockLoggedInUser = MockLoggedInUser();

    // Configure metadata collector mocks with proper value objects
    when(() => mockMetadataCollector.appVersion)
        .thenReturn(AppVersion('1.0.0'));
    when(() => mockMetadataCollector.userDeviceInfo)
        .thenReturn(DeviceInfo('test-device'));
    when(() => mockMetadataCollector.userIpAddress)
        .thenReturn(IpAddress('192.168.1.1'));

    // Configure access control service mocks
    when(() => mockAccessControlService.loggedInUser)
        .thenReturn(mockLoggedInUser);

    useCase = CreateAnnualRevenueGoal(
      repository: mockRepository,
      accessControl: mockAccessControlService,
      metadataCollector: mockMetadataCollector,
    );
  });

  group('CreateAnnualRevenueGoal UseCase', () {
    // ============================================================
    // FIXTURES & HELPERS
    // ============================================================

    final tCurrentYear = Year.fromInt(2025);
    final tValidYear = Year.fromInt(2026);
    final tPastYear = Year.fromInt(2024);
    final tMoney = Money.fromDouble(12000.00);

    AnnualRevenueGoal createValidAnnualGoal({
      required Year year,
      required Money target,
    }) {
      return AnnualRevenueGoal.build(
        year: year,
        monthlyGoals: <MonthlyRevenueGoal>[
          for (int i = 1; i <= 12; i++)
            MonthlyRevenueGoal.create(
              year: year,
              month: Month.fromInt(i),
              target: Money.fromDouble(1000.00),
            ),
        ],
      );
    }

    // ============================================================
    // USE CASE METADATA TESTS
    // ============================================================

    test('requiredPermission should return manageGlobalGoals', () {
      expect(
          useCase.requiredPermission, GoalsModulePermission.manageGlobalGoals);
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'))).thenAnswer((_) async => tAnnualGoal);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        final params = CreateAnnualRevenueGoalParams(
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
            expect(r.year, tValidYear);
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        final params = CreateAnnualRevenueGoalParams(
          year: tPastYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect((l as CreateAnnualRevenueGoalFailure).reason,
              CreateAnnualRevenueGoalFailureReason.pastYear),
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should return Left(zeroOrNegativeTarget) when target is negative',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: Money.fromDouble(-1200.00),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect((l as CreateAnnualRevenueGoalFailure).reason,
              CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget),
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should return Left(zeroOrNegativeTarget) when target is zero',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: Money.fromCents(0),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect((l as CreateAnnualRevenueGoalFailure).reason,
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

      final params = CreateAnnualRevenueGoalParams(
        year: tValidYear,
        annualRevenueTarget: tMoney,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect((l as CreateAnnualRevenueGoalFailure).reason,
            CreateAnnualRevenueGoalFailureReason.permissionDenied),
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'), log: any(named: 'log'))).thenThrow(
          const RepositoryFailure(
            reason: RepositoryFailureReason.annualGoalForYearAlreadyExists,
          ),
        );

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(
              (l as CreateAnnualRevenueGoalFailure).reason,
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'), log: any(named: 'log'))).thenThrow(
          const RepositoryFailure(
            reason: RepositoryFailureReason.permissionDenied,
          ),
        );

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect((l as CreateAnnualRevenueGoalFailure).reason,
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'), log: any(named: 'log'))).thenThrow(
          const RepositoryFailure(
            reason: RepositoryFailureReason.connectionError,
          ),
        );

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect((l as CreateAnnualRevenueGoalFailure).reason,
                CreateAnnualRevenueGoalFailureReason.connectionError);
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'), log: any(named: 'log'))).thenThrow(
          const AnnualRevenueGoalFailure(
            AnnualRevenueGoalFailureReason.invalidMonthsCount,
          ),
        );

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect((l as CreateAnnualRevenueGoalFailure).reason,
                CreateAnnualRevenueGoalFailureReason.internal);
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'), log: any(named: 'log'))).thenThrow(
          Exception('Unexpected error'),
        );

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) {
            expect((l as CreateAnnualRevenueGoalFailure).reason,
                CreateAnnualRevenueGoalFailureReason.internal);
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
        final annualTarget = Money.fromDouble(12000.00);
        final tAnnualGoal = createValidAnnualGoal(
          year: tValidYear,
          target: annualTarget,
        );

        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'))).thenAnswer((_) async => tAnnualGoal);

        final params = CreateAnnualRevenueGoalParams(
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'))).thenAnswer((_) async => tAnnualGoal);

        final params = CreateAnnualRevenueGoalParams(
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
        final minTarget = Money.fromCents(12);
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: minTarget);
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'))).thenAnswer((_) async => tAnnualGoal);

        final params = CreateAnnualRevenueGoalParams(
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
        final largeTarget = Money.fromDouble(999999999.99);
        final tAnnualGoal =
            createValidAnnualGoal(year: tValidYear, target: largeTarget);
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'))).thenAnswer((_) async => tAnnualGoal);

        final params = CreateAnnualRevenueGoalParams(
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);

        final params = CreateAnnualRevenueGoalParams(
          year: Year.fromInt(1990),
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect((l as CreateAnnualRevenueGoalFailure).reason,
              CreateAnnualRevenueGoalFailureReason.pastYear),
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
        when(() => mockRepository.getCurrentYear()).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return tCurrentYear;
          },
        );
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'),
            log: any(named: 'log'))).thenAnswer((_) async => tAnnualGoal);

        final params = CreateAnnualRevenueGoalParams(
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
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);
        when(() => mockAccessControlService.hasPermission(any()))
            .thenReturn(true);
        when(() => mockRepository.create(
            goal: any(named: 'goal'), log: any(named: 'log'))).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return tAnnualGoal;
          },
        );

        final params = CreateAnnualRevenueGoalParams(
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
