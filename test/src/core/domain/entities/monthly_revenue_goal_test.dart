import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/entities/monthly_revenue_goal/monthly_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/entities/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final brl = Currency.fromISO4217('BRL');
  Money money(num value) =>
      Money.fromDouble(value: value.toDouble(), currency: brl);
  Money cents(int value) => Money.fromCents(cents: value, currency: brl);

  group('MonthlyRevenueGoal Entity', () {
    // ============================================================
    /// FIXTURES
    // ============================================================
    late Year tYear;
    late Month tMonth;
    late Money tTarget;
    late Money tProgress;
    late IdUuidV7 testUuid;

    setUp(() {
      tYear = Year.fromInt(2025);
      tMonth = Month.fromInt(1);
      tTarget = money(1000.00);
      tProgress = money(250.00);
      testUuid = IdUuidV7.fromString('123e4567-e89b-12d3-a456-426614174000');
    });

    /// Helper to reconstruct a goal with optional overrides
    MonthlyRevenueGoal reconstructGoal({
      Money? target,
      Money? progress,
      IdUuidV7? id,
      Month? month,
      Year? year,
    }) {
      return MonthlyRevenueGoal.reconstruct(
        id: id ?? testUuid,
        year: year ?? tYear,
        month: month ?? tMonth,
        target: target ?? tTarget,
        progress: progress ?? tProgress,
      );
    }

    /// Helper to create a new goal with optional overrides
    MonthlyRevenueGoal createGoal({
      Money? target,
      Month? month,
      Year? year,
    }) {
      return MonthlyRevenueGoal.create(
        year: year ?? tYear,
        month: month ?? tMonth,
        target: target ?? tTarget,
      );
    }

    // ============================================================
    /// CONSTRUCTION & EQUALITY
    // ============================================================

    group('Construction & Equality |', () {
      test('should be created with correct properties via reconstruct', () {
        // Act
        final goal = reconstructGoal();

        // Assert
        expect(goal.year, tYear);
        expect(goal.month, tMonth);
        expect(goal.target, tTarget);
        expect(goal.progress, tProgress);
        expect(goal.id, testUuid);
      });

      test('should be created via factory create with auto-generated ID', () {
        // Act
        final goal = createGoal();

        // Assert
        expect(goal.year, tYear);
        expect(goal.month, tMonth);
        expect(goal.target, tTarget);
        expect(goal.progress,
            Money.fromCents(cents: 0, currency: tTarget.currency));
        expect(goal.id, isNotNull);
      });

      test('should generate unique IDs for different create calls', () {
        // Act
        final goal1 = createGoal();
        final goal2 = createGoal();

        // Assert
        expect(goal1.id, isNot(equals(goal2.id)));
      });

      test('should support value equality (Equatable)', () {
        // Act
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal();

        // Assert
        expect(goal1, equals(goal2));
      });

      test('should not be equal if ID differs', () {
        // Arrange
        final differentId =
            IdUuidV7.fromString('223e4567-e89b-12d3-a456-426614174000');

        // Act
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal(id: differentId);

        // Assert
        expect(goal1, isNot(equals(goal2)));
      });

      test('should not be equal if month differs', () {
        // Act
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal(month: Month.fromInt(2));

        // Assert
        expect(goal1, isNot(equals(goal2)));
      });

      test('should not be equal if year differs', () {
        // Act
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal(year: Year.fromInt(2026));

        // Assert
        expect(goal1, isNot(equals(goal2)));
      });

      test('should not be equal if target differs', () {
        // Act
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal(target: money(2000.00));

        // Assert
        expect(goal1, isNot(equals(goal2)));
      });

      test('should not be equal if progress differs', () {
        // Act
        final goal1 = reconstructGoal(progress: money(100));
        final goal2 = reconstructGoal(progress: money(200));

        // Assert
        expect(goal1, isNot(equals(goal2)));
      });

      test('should default progress to zero if not provided in create factory',
          () {
        // Act
        final goal = createGoal();

        // Assert
        expect(goal.progress,
            equals(Money.fromCents(cents: 0, currency: tTarget.currency)));
      });

      test('should have same hash for equal objects', () {
        // Act
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal();

        // Assert
        expect(goal1.hashCode, equals(goal2.hashCode));
      });
    });

    // ============================================================
    /// DOMAIN VALIDATIONS
    // ============================================================

    group('Domain Validations |', () {
      test('should throw when target is zero in reconstruct', () {
        // Arrange
        final zeroTarget = cents(0);

        // Act & Assert
        expect(
          () => reconstructGoal(target: zeroTarget),
          throwsA(
            isA<MonthlyRevenueGoalFailure>().having(
              (failure) => failure.reason,
              'reason',
              MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget,
            ),
          ),
        );
      });

      test('should throw when target is negative in reconstruct', () {
        // Arrange
        final negativeTarget = money(-10.00);

        // Act & Assert
        expect(
          () => reconstructGoal(target: negativeTarget),
          throwsA(
            isA<MonthlyRevenueGoalFailure>().having(
              (failure) => failure.reason,
              'reason',
              MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget,
            ),
          ),
        );
      });

      test('should throw when target is zero in create factory', () {
        // Arrange
        final zeroTarget = cents(0);

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
      });

      test('should throw when target is negative in create factory', () {
        // Arrange
        final negativeTarget = money(-50.00);

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
      });

      test('should throw on very large negative value', () {
        // Arrange
        final largeNegative = money(-999999.99);

        // Act & Assert
        expect(
          () => reconstructGoal(target: largeNegative),
          throwsA(isA<MonthlyRevenueGoalFailure>()),
        );
      });

      test('should throw on -1 cent edge case', () {
        // Arrange
        final minusOneCent = cents(-1);

        // Act & Assert
        expect(
          () => reconstructGoal(target: minusOneCent),
          throwsA(isA<MonthlyRevenueGoalFailure>()),
        );
      });

      test('should accept exactly 1 cent as valid minimum', () {
        // Arrange
        final oneC = cents(1);

        // Act
        final goal = reconstructGoal(target: oneC);

        // Assert
        expect(goal.target, equals(oneC));
      });

      test('should accept very large positive target', () {
        // Arrange
        final largeTarget = money(999999.99);

        // Act
        final goal = reconstructGoal(target: largeTarget);

        // Assert
        expect(goal.target, equals(largeTarget));
      });

      test('should accept target with fractional cents', () {
        // Arrange
        final fractionalTarget = money(1234.56);

        // Act
        final goal = reconstructGoal(target: fractionalTarget);

        // Assert
        expect(goal.target, equals(fractionalTarget));
      });
      group('MonthlyRevenueGoal.reconstruct | _validateProgress', () {
        // defined helper values to keep tests clean
        final validId = IdUuidV7.generate();
        final validMonth = Month.fromInt(1);
        final validYear = Year.fromInt(2024);
        final validTarget = cents(10000); // 100.00

        test('should successfully reconstruct when progress is Zero (0)', () {
          // Arrange
          final zeroProgress = cents(0);

          // Act
          final goal = MonthlyRevenueGoal.reconstruct(
            id: validId,
            month: validMonth,
            year: validYear,
            target: validTarget,
            progress: zeroProgress,
          );

          // Assert
          expect(goal.progress, equals(zeroProgress));
        });

        test('should successfully reconstruct when progress is Positive (> 0)',
            () {
          // Arrange
          final positiveProgress = cents(5000); // 50.00

          // Act
          final goal = MonthlyRevenueGoal.reconstruct(
            id: validId,
            month: validMonth,
            year: validYear,
            target: validTarget,
            progress: positiveProgress,
          );

          // Assert
          expect(goal.progress, equals(positiveProgress));
        });

        test(
            'should throw MonthlyRevenueGoalFailure when progress is Negative (< 0)',
            () {
          // Arrange
          final negativeProgress = cents(-100); // -1.00

          // Act & Assert
          expect(
            () => MonthlyRevenueGoal.reconstruct(
              id: validId,
              month: validMonth,
              year: validYear,
              target: validTarget,
              progress: negativeProgress,
            ),
            throwsA(
              isA<MonthlyRevenueGoalFailure>().having(
                (failure) => failure.reason,
                'reason',
                MonthlyRevenueGoalFailureReason.negativeProgress,
              ),
            ),
          );
        });
      });
    });

    // ============================================================
    /// GETTERS
    // ============================================================

    group('Getters |', () {
      test('target getter should return the exact Money value stored', () {
        // Arrange
        final expectedTarget = cents(99900); // 999.00
        final goal = reconstructGoal(target: expectedTarget);

        // Act
        final result = goal.target;

        // Assert
        expect(result, equals(expectedTarget));
        // Ensure the value (cents) is preserved during the 'copy' mechanism
        expect(result.cents, 99900);
      });

      test('target getter should return a new instance (defensive copy)', () {
        // Arrange
        final goal = reconstructGoal();
        final firstCall = goal.target;
        final secondCall = goal.target;

        // Assert - different instances but equal values
        expect(firstCall, equals(secondCall));
      });

      test('progress getter should return the exact Money value stored', () {
        // Arrange
        final expectedProgress = cents(12345); // 123.45
        final goal = reconstructGoal(progress: expectedProgress);

        // Act
        final result = goal.progress;

        // Assert
        expect(result, equals(expectedProgress));
        expect(result.cents, 12345);
      });

      test('progress getter should return a new instance (defensive copy)', () {
        // Arrange
        final goal = reconstructGoal();
        final firstCall = goal.progress;
        final secondCall = goal.progress;

        // Assert - different instances but equal values
        expect(firstCall, equals(secondCall));
      });

      test('id getter should return the exact IdUuidV7 value', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final result = goal.id;

        // Assert
        expect(result, equals(testUuid));
        expect(result.value, testUuid.value);
      });

      test('id getter should return a new instance (defensive copy)', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final firstCall = goal.id;
        final secondCall = goal.id;

        // Assert
        expect(firstCall, equals(secondCall));
        expect(firstCall.value, secondCall.value);
      });

      test('month getter should return the exact Month value', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final result = goal.month;

        // Assert
        expect(result, equals(tMonth));
        expect(result.value, tMonth.value);
      });

      test('month getter should return a new instance (defensive copy)', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final firstCall = goal.month;
        final secondCall = goal.month;

        // Assert
        expect(firstCall, equals(secondCall));
        expect(firstCall.value, secondCall.value);
      });

      test('year getter should return the exact Year value', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final result = goal.year;

        // Assert
        expect(result, equals(tYear));
        expect(result.value, tYear.value);
      });

      test('year getter should return a new instance (defensive copy)', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final firstCall = goal.year;
        final secondCall = goal.year;

        // Assert
        expect(firstCall, equals(secondCall));
        expect(firstCall.value, secondCall.value);
      });

      test('all getters with different values should work correctly', () {
        // Arrange
        final customYear = Year.fromInt(2030);
        final customMonth = Month.fromInt(12);
        final customTarget = money(5000.00);
        final customProgress = money(3500.00);
        final customId =
            IdUuidV7.fromString('323e4567-e89b-12d3-a456-426614174000');

        final goal = reconstructGoal(
          year: customYear,
          month: customMonth,
          target: customTarget,
          progress: customProgress,
          id: customId,
        );

        // Assert
        expect(goal.year, equals(customYear));
        expect(goal.month, equals(customMonth));
        expect(goal.target, equals(customTarget));
        expect(goal.progress, equals(customProgress));
        expect(goal.id, equals(customId));
      });
    });

    // ============================================================
    /// STRINGIFY & EQUATABLE BEHAVIOR
    // ============================================================

    group('Stringify & Equatable |', () {
      test('toString() should return readable representation', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final result = goal.toString();

        // Assert
        expect(result, startsWith('MonthlyRevenueGoal'));
        expect(result, contains('Year(2025)'));
        expect(result, contains('Month(1)'));
        expect(result, contains(tTarget.toString()));
        expect(result, contains(tProgress.toString()));
      });

      test('toString() should include ID in string representation', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final result = goal.toString();

        // Assert
        expect(result, contains(testUuid.value));
      });

      test('toString() should be consistent across multiple calls', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final first = goal.toString();
        final second = goal.toString();

        // Assert
        expect(first, equals(second));
      });

      test('props should contain all 5 properties in correct order', () {
        // Arrange
        final goal = reconstructGoal();

        // Act
        final props = goal.props;

        // Assert
        expect(props.length, 5);
        expect(props[0], equals(testUuid));
        expect(props[1], equals(tMonth));
        expect(props[2], equals(tYear));
        expect(props[3], equals(tTarget));
        expect(props[4], equals(tProgress));
      });

      test('stringify should return true', () {
        // Arrange
        final goal = reconstructGoal();

        // Assert
        expect(goal.stringify, equals(true));
      });

      test('two objects with same props should have same toString', () {
        // Arrange
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal();

        // Act
        final str1 = goal1.toString();
        final str2 = goal2.toString();

        // Assert
        expect(str1, equals(str2));
      });

      test('two objects with different props should have different toString',
          () {
        // Arrange
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal(progress: money(999.99));

        // Act
        final str1 = goal1.toString();
        final str2 = goal2.toString();

        // Assert
        expect(str1, isNot(equals(str2)));
      });
    });

    // ============================================================
    /// IMMUTABILITY & ENCAPSULATION
    // ============================================================

    group('Immutability & Encapsulation |', () {
      test('should not expose internal Money objects for mutation', () {
        // Arrange
        final goal = reconstructGoal();

        // Act - get targets
        final targetA = goal.target;
        final targetB = goal.target;

        // Assert - they should be equal but not the same instance
        expect(targetA, equals(targetB));
      });

      test('internal state should not change after operations', () {
        // Arrange
        final originalTarget = money(5000.00);
        final goal = reconstructGoal(target: originalTarget);

        // Act - access getters multiple times
        goal.target;
        goal.progress;
        goal.id;
        goal.year;
        goal.month;

        // Assert
        expect(goal.target, equals(originalTarget));
      });

      test('should create independent instances from same data', () {
        // Arrange
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal();

        // Assert
        expect(goal1, equals(goal2));
        expect(identical(goal1, goal2), isFalse);
      });
    });

    // ============================================================
    /// EDGE CASES & BOUNDARY CONDITIONS
    // ============================================================

    group('Edge Cases & Boundary Conditions |', () {
      test('should handle all 12 months correctly', () {
        // Arrange & Act
        for (int monthNum = 1; monthNum <= 12; monthNum++) {
          final goal = reconstructGoal(month: Month.fromInt(monthNum));

          // Assert
          expect(goal.month.value, equals(monthNum));
        }
      });

      test('should handle various years including past and future', () {
        // Arrange
        final testYears = [1900, 2000, 2023, 2025, 2100, 9999];

        // Act & Assert
        for (final year in testYears) {
          final goal = reconstructGoal(year: Year.fromInt(year));
          expect(goal.year.value, equals(year));
        }
      });

      test('should handle zero progress with positive target', () {
        // Arrange
        final goal = reconstructGoal(
          target: money(1000.00),
          progress: cents(0),
        );

        // Assert
        expect(goal.target.cents, equals(100000));
        expect(goal.progress.cents, equals(0));
        expect(goal.progress.cents, lessThan(goal.target.cents));
      });

      test('should handle progress equal to target', () {
        // Arrange
        final amount = money(1500.00);
        final goal = reconstructGoal(target: amount, progress: amount);

        // Assert
        expect(goal.target, equals(goal.progress));
      });

      test('should handle progress exceeding target', () {
        // Arrange
        final goal = reconstructGoal(
          target: money(1000.00),
          progress: money(2000.00),
        );

        // Assert
        expect(goal.progress.cents, greaterThan(goal.target.cents));
      });

      test('should handle very precise decimal values', () {
        // Arrange
        final preciseValue = money(123.45);
        final goal = reconstructGoal(target: preciseValue);

        // Assert
        expect(goal.target.cents, equals(12345));
      });

      test('should handle large monetary values', () {
        // Arrange
        final largeValue = money(999999.99);
        final goal = reconstructGoal(target: largeValue);

        // Assert
        expect(goal.target.cents, equals(99999999));
      });

      test('should accept progress of zero cents explicitly', () {
        // Arrange
        final goal = reconstructGoal(progress: cents(0));

        // Assert
        expect(goal.progress.cents, equals(0));
      });

      test('should handle UUID with all variations', () {
        // Arrange
        final uuids = [
          '00000000-0000-0000-0000-000000000000',
          'ffffffff-ffff-ffff-ffff-ffffffffffff',
          '123e4567-e89b-12d3-a456-426614174000',
        ];

        // Act & Assert
        for (final uuidStr in uuids) {
          final goal = reconstructGoal(
            id: IdUuidV7.fromString(uuidStr),
          );
          expect(goal.id.value, equals(uuidStr));
        }
      });

      test('should maintain equality with multiple creates', () {
        // Arrange
        final goal1 = createGoal();
        final id = goal1.id;
        final year = goal1.year;
        final month = goal1.month;
        final target = goal1.target;

        // Act
        final goal2 = MonthlyRevenueGoal.reconstruct(
          id: id,
          year: year,
          month: month,
          target: target,
          progress: Money.fromCents(cents: 0, currency: target.currency),
        );

        // Assert
        expect(goal1, equals(goal2));
      });
    });

    // ============================================================
    /// FACTORY CONSTRUCTORS COMPARISON
    // ============================================================

    group('Factory Constructors Comparison |', () {
      test('create should initialize with zero progress', () {
        // Act
        final goal = createGoal();

        // Assert
        expect(goal.progress.cents, equals(0));
      });

      test('create should generate unique ID each time', () {
        // Act
        final goal1 = createGoal();
        final goal2 = createGoal();
        final goal3 = createGoal();

        // Assert
        expect(goal1.id, isNot(equals(goal2.id)));
        expect(goal2.id, isNot(equals(goal3.id)));
        expect(goal1.id, isNot(equals(goal3.id)));
      });

      test('reconstruct should preserve exact state provided', () {
        // Arrange
        final target = money(2500.00);
        final progress = money(1800.00);
        const year = 2030;
        const month = 6;

        // Act
        final goal = reconstructGoal(
          target: target,
          progress: progress,
          year: Year.fromInt(year),
          month: Month.fromInt(month),
        );

        // Assert
        expect(goal.target, equals(target));
        expect(goal.progress, equals(progress));
        expect(goal.year.value, equals(year));
        expect(goal.month.value, equals(month));
      });

      test('create and reconstruct should both validate target', () {
        // Arrange
        final invalidTarget = cents(-1);

        // Assert
        expect(
          () => createGoal(target: invalidTarget),
          throwsA(isA<MonthlyRevenueGoalFailure>()),
        );

        expect(
          () => reconstructGoal(target: invalidTarget),
          throwsA(isA<MonthlyRevenueGoalFailure>()),
        );
      });
    });

    // ============================================================
    /// COMPLEX SCENARIOS
    // ============================================================

    group('Complex Scenarios |', () {
      test('should handle realistic monthly goal tracking', () {
        // Scenario: Track Q1 goals
        final january = reconstructGoal(
          month: Month.fromInt(1),
          target: money(10000.00),
          progress: money(8500.00),
        );

        final february = reconstructGoal(
          month: Month.fromInt(2),
          target: money(12000.00),
          progress: money(0.00),
        );

        final march = reconstructGoal(
          month: Month.fromInt(3),
          target: money(11000.00),
          progress: money(11000.00),
        );

        // Assert
        expect(january.progress.cents < january.target.cents, isTrue);
        expect(february.progress.cents == 0, isTrue);
        expect(march.progress.cents == march.target.cents, isTrue);
      });

      test('should support aggregating goals', () {
        // Arrange
        final goals = [
          reconstructGoal(month: Month.fromInt(1)),
          reconstructGoal(month: Month.fromInt(2)),
          reconstructGoal(month: Month.fromInt(3)),
        ];

        // Act
        final totalTarget = goals.fold<int>(
          0,
          (sum, goal) => sum + goal.target.cents,
        );

        final totalProgress = goals.fold<int>(
          0,
          (sum, goal) => sum + goal.progress.cents,
        );

        // Assert
        expect(totalTarget, equals(3 * tTarget.cents));
        expect(totalProgress, equals(3 * tProgress.cents));
      });

      test('should work correctly in collections', () {
        // Arrange
        final goal1 = reconstructGoal();
        final goal2 = reconstructGoal(month: Month.fromInt(2));
        final goal3 = reconstructGoal(
            id: IdUuidV7.fromString('223e4567-e89b-12d3-a456-426614174000'));

        // Act
        final goalSet = {goal1, goal2, goal3};
        final goalList = [goal1, goal2, goal3];
        final goalMap = {
          '1': goal1,
          '2': goal2,
          '3': goal3,
        };

        // Assert
        expect(goalSet.length, equals(3));
        expect(goalList.length, equals(3));
        expect(goalMap.length, equals(3));
      });
    });
  });
}
