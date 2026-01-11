import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyRevenueGoal Entity', () {
    // ============================================================
    /// FIXTURES
    // ============================================================
    final tYear = Year.fromInt(2025);
    final tMonth = Month.fromInt(1);
    final tTarget = Money.fromDouble(1000.00);
    final tProgress = Money.fromDouble(250.00);
    final IdUuidV7 testUuid =
        IdUuidV7.fromString('123e4567-e89b-12d3-a456-426614174000');

    MonthlyRevenueGoal createGoal({
      Money? target,
      Money? progress,
    }) {
      return MonthlyRevenueGoal.create(
        year: tYear,
        month: tMonth,
        target: target ?? tTarget,
        progress: progress ?? tProgress,
        id: testUuid,
      );
    }

    // ============================================================
    /// CONSTRUCTION & EQUALITY
    // ============================================================

    test('should be created with correct properties', () {
      final goal = createGoal();

      expect(goal.year, tYear);
      expect(goal.month, tMonth);
      expect(goal.target, tTarget);
      expect(goal.progress, tProgress);
      expect(goal.id, testUuid);
    });

    test('should support value equality (Equatable)', () {
      final goal1 = createGoal();
      final goal2 = createGoal();

      expect(goal1, equals(goal2));
    });

    test('should not be equal if properties differ', () {
      final goal1 = createGoal(progress: Money.fromDouble(100));
      final goal2 = createGoal(progress: Money.fromDouble(200));

      expect(goal1, isNot(equals(goal2)));
    });

    test('should default progress to zero if not provided in factory', () {
      // Act
      final goal = MonthlyRevenueGoal.create(
        year: tYear,
        month: tMonth,
        target: tTarget,
        progress: null,
      );

      // Assert
      expect(goal.progress, equals(Money.fromCents(0)));
    });

    // ============================================================
    /// DOMAIN VALIDATIONS
    /// ============================================================

    test(
      'should throw MonthlyRevenueGoalFailure when target is zero',
      () {
        // Arrange
        final zeroTarget = Money.fromCents(0);

        // Act & Assert
        expect(
          () => createGoal(target: zeroTarget),
          throwsA(
            isA<MonthlyRevenueGoalFailure>().having(
              (failure) => failure.reason,
              'reason',
              MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget,
            ),
          ),
        );
      },
    );

    test(
      'should throw MonthlyRevenueGoalFailure when target is negative',
      () {
        // Arrange
        final negativeTarget = Money.fromDouble(-10.00);

        // Act & Assert
        expect(
          () => createGoal(target: negativeTarget),
          throwsA(
            isA<MonthlyRevenueGoalFailure>().having(
              (failure) => failure.reason,
              'reason',
              MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget,
            ),
          ),
        );
      },
    );

    // ============================================================
    /// GETTERS
    // ============================================================

    test('target getter should return the exact Money value stored', () {
      // Arrange
      final expectedTarget = Money.fromCents(99900); // 999.00
      final goal = createGoal(target: expectedTarget);

      // Act
      final result = goal.target;

      // Assert
      expect(result, equals(expectedTarget));
      // Ensure the value (cents) is preserved during the 'copy' mechanism in the getter
      expect(result.cents, 99900);
    });

    test('progress getter should return the exact Money value stored', () {
      // Arrange
      final expectedProgress = Money.fromCents(12345); // 123.45
      final goal = createGoal(progress: expectedProgress);

      // Act
      final result = goal.progress;

      // Assert
      expect(result, equals(expectedProgress));
      // Ensure the value (cents) is preserved during the 'copy' mechanism in the getter
      expect(result.cents, 12345);
    });

    // ============================================================
    /// STRINGIFY
    // ============================================================

    test('toString() should return readable representation (Default Equatable)',
        () {
      final goal = createGoal();

      // Act
      final result = goal.toString();

      // Assert
      expect(result, startsWith('MonthlyRevenueGoal'));

      // Verify
      expect(result, contains('Year(2025)'));
      expect(result, contains('Month(1)'));
      expect(result, contains(tTarget.toString()));
      expect(result, contains(tProgress.toString()));
    });
  });
}
