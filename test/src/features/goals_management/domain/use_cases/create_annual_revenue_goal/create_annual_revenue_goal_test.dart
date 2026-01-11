import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/repositories/yearly_revenue_goal_repository.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/create_annual_revenue_goal_params.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/features/goals_management/domain/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnnualRevenueGoalRepository extends Mock
    implements AnnualRevenueGoalRepository {}

class FakeAnnualRevenueGoal extends Fake implements AnnualRevenueGoal {}

void main() {
  late CreateAnnualRevenueGoal useCase;
  late MockAnnualRevenueGoalRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeAnnualRevenueGoal());
  });

  setUp(() {
    mockRepository = MockAnnualRevenueGoalRepository();
    useCase = CreateAnnualRevenueGoal(mockRepository);
  });

  group('CreateAnnualRevenueGoal UseCase', () {
    // ============================================================
    // FIXTURES
    // ============================================================
    final tCurrentYear = Year.fromInt(2025);
    final tValidYear = Year.fromInt(2026);
    final tPastYear = Year.fromInt(2024);
    final tMoney = Money.fromDouble(12000.00);

    final tParams = CreateAnnualRevenueGoalParams(
      year: tValidYear,
      annualRevenueTarget: tMoney,
    );

    final tAnnualGoal = AnnualRevenueGoal.create(
      year: tValidYear,
      monthlyGoals: List.generate(
        12,
        (index) => MonthlyRevenueGoal.create(
          year: tValidYear,
          month: Month.fromInt(index + 1),
          target: Money.fromDouble(1000.00),
        ),
      ),
    );

    // ============================================================
    // SUCCESS SCENARIOS
    // ============================================================

    test(
      'should create and persist annual goal when parameters are valid',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        when(() => mockRepository.create(any()))
            .thenAnswer((_) async => tAnnualGoal);

        // Act
        final result = await useCase(tParams);

        // Assert
        expect(result, Right(tAnnualGoal));

        verify(() => mockRepository.getCurrentYear()).called(1);
        verify(() => mockRepository.create(any(that: isA<AnnualRevenueGoal>())))
            .called(1);
      },
    );

    // ============================================================
    // VALIDATION FAILURES (PRE-DOMAIN)
    // ============================================================

    test(
      'should return Left(pastYear) when year is before current year',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        final params = CreateAnnualRevenueGoalParams(
          year: tPastYear,
          annualRevenueTarget: tMoney,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(
          result,
          const Left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason.pastYear,
            ),
          ),
        );

        verify(() => mockRepository.getCurrentYear()).called(1);
        verifyNever(() => mockRepository.create(any()));
      },
    );

    // ============================================================
    // DOMAIN FAILURES (INTEGRATION WITH ENTITIES)
    // ============================================================

    test(
      'should return Left(zeroOrNegativeTarget) when annual target is negative',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: Money.fromDouble(-1200.00),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);

        result.fold(
          (failure) {
            expect(failure, isA<CreateAnnualRevenueGoalFailure>());
            expect((failure as CreateAnnualRevenueGoalFailure).reason,
                CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget);
          },
          (_) => fail('Should be Left'),
        );
      },
    );

    test(
      'should return Left(zeroOrNegativeTarget) when target is exactly zero',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: Money.fromCents(0),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(
          result,
          const Left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget,
            ),
          ),
        );
      },
    );

    test(
      'should return Left(internal) when generic AnnualRevenueGoalFailure occurs',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        const unexpectedDomainFailure = AnnualRevenueGoalFailure(
          AnnualRevenueGoalFailureReason.invalidMonthsCount, // Arbitrary reason
        );

        when(() => mockRepository.create(any()))
            .thenThrow(unexpectedDomainFailure);

        // Act
        final result = await useCase(tParams);

        // Assert
        expect(result.isLeft(), true);
        final failure = result.fold(
            (l) => l as CreateAnnualRevenueGoalFailure, (r) => null)!;

        expect(failure.reason, CreateAnnualRevenueGoalFailureReason.internal);
        expect(failure.cause, unexpectedDomainFailure);
      },
    );

    // ==============================================
    // MONTHLY GOALS  DISTRIBUTION
    // ==============================================

    test(
      'should correctly distribute the annual target into 12 monthly goals before persisting',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        when(() => mockRepository.create(any())).thenAnswer(
          (invocation) async =>
              invocation.positionalArguments.first as AnnualRevenueGoal,
        );

        final params = CreateAnnualRevenueGoalParams(
          year: tValidYear,
          annualRevenueTarget: Money.fromDouble(12000.00),
        );

        // Act
        await useCase(params);

        // Assert
        final captured =
            verify(() => mockRepository.create(captureAny())).captured;
        final savedGoal = captured.first as AnnualRevenueGoal;

        expect(savedGoal.year, tValidYear);
        expect(savedGoal.totalAnnualTarget, Money.fromDouble(12000.00));

        expect(savedGoal.monthlyGoals.length, 12);

        expect(savedGoal.monthlyGoals.first.target.cents, 100000);
      },
    );

    // ============================================================
    // REPOSITORY FAILURES
    // ============================================================

    test(
      'should return Left(annualGoalForYearAlreadyExists) when repository fails with conflict',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        when(() => mockRepository.create(any())).thenThrow(
          const RepositoryFailure(
            reason: RepositoryFailureReason.annualGoalForYearAlreadyExists,
          ),
        );

        // Act
        final result = await useCase(tParams);

        // Assert
        expect(
          result,
          const Left(
            CreateAnnualRevenueGoalFailure(
              reason: CreateAnnualRevenueGoalFailureReason
                  .annualGoalForYearAlreadyExists,
            ),
          ),
        );
      },
    );

    test(
      'should return Left(permissionDenied) when repository fails with permission error',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        const repoFailure = RepositoryFailure(
          reason: RepositoryFailureReason.permissionDenied,
        );

        when(() => mockRepository.create(any())).thenThrow(repoFailure);

        // Act
        final result = await useCase(tParams);

        // Assert
        result.fold(
          (l) {
            expect(l, isA<CreateAnnualRevenueGoalFailure>());
            final f = l as CreateAnnualRevenueGoalFailure;
            expect(f.reason,
                CreateAnnualRevenueGoalFailureReason.permissionDenied);
            expect(f.cause, repoFailure);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    test(
      'should return Left(connectionError) when repository fails with unknown reason',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        const repoFailure = RepositoryFailure(
          reason: RepositoryFailureReason.infra,
        );

        when(() => mockRepository.create(any())).thenThrow(repoFailure);

        // Act
        final result = await useCase(tParams);

        // Assert
        result.fold(
          (l) {
            final f = l as CreateAnnualRevenueGoalFailure;
            expect(
                f.reason, CreateAnnualRevenueGoalFailureReason.connectionError);
            expect(f.cause, repoFailure);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    // ============================================================
    // GENERIC FAILURES
    // ============================================================

    test(
      'should return Left(internal) when an unexpected exception occurs',
      () async {
        // Arrange
        when(() => mockRepository.getCurrentYear())
            .thenAnswer((_) async => tCurrentYear);

        final exception = Exception('Unexpected system crash');
        when(() => mockRepository.create(any())).thenThrow(exception);

        // Act
        final result = await useCase(tParams);

        // Assert
        result.fold(
          (l) {
            final f = l as CreateAnnualRevenueGoalFailure;
            expect(f.reason, CreateAnnualRevenueGoalFailureReason.internal);
            expect(f.cause, exception);
          },
          (r) => fail('Should be Left'),
        );
      },
    );

    test('Failure should support stringify and equality', () {
      const failure1 = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.pastYear,
        cause: 'Any cause',
        message: 'Test message',
      );
      const failure2 = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.pastYear,
        cause: 'Any cause',
        message: 'Test message',
      );
      const failureDiff = CreateAnnualRevenueGoalFailure(
        reason: CreateAnnualRevenueGoalFailureReason.connectionError,
      );

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
      expect(failure1.toString(), contains('CreateAnnualRevenueGoalFailure'));
    });
  });
}
