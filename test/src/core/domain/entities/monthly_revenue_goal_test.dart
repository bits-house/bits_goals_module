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
    // MAPPING
    // ============================================================

    group('MonthlyRevenueGoal.toMap |', () {
      // Helper to create a valid entity for testing
      MonthlyRevenueGoal createEntity({
        String uuidV7 = '123e4567-e89b-12d3-a456-426614174000',
        int month = 5,
        int year = 2026,
        int targetCents = 100000,
        int progressCents = 50000,
      }) {
        return MonthlyRevenueGoal.create(
          id: IdUuidV7.fromString(uuidV7),
          month: Month.fromInt(month),
          year: Year.fromInt(year),
          target: Money.fromCents(targetCents),
          progress: Money.fromCents(progressCents),
        );
      }

      test('Should return a Map with all correct keys and values', () {
        // Arrange
        final entity = createEntity(
          month: 12,
          year: 2025,
          targetCents: 5000,
          progressCents: 2500,
        );

        // Act
        final result = entity.toMap();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], '123e4567-e89b-12d3-a456-426614174000');
        expect(result['month'], 12);
        expect(result['year'], 2025);
        expect(result['target_cents'], 5000);
        expect(result['progress_cents'], 2500);
      });

      test(
          'Should ensure data types match database/infrastructure expectations',
          () {
        // Arrange
        final entity = createEntity();

        // Act
        final result = entity.toMap();

        // Assert
        expect(result['id'], isA<String>());
        expect(result['month'], isA<int>());
        expect(result['year'], isA<int>());
        expect(result['target_cents'], isA<int>());
        expect(result['progress_cents'], isA<int>());
      });

      test(
          'Should be a stable representation (calling it twice returns identical data)',
          () {
        // Arrange
        final entity = createEntity();

        // Act
        final firstMap = entity.toMap();
        final secondMap = entity.toMap();

        // Assert
        expect(firstMap, equals(secondMap));
      });

      test(
          'Should ensure the returned Map is a new instance (Immutability check)',
          () {
        // Arrange
        final entity = createEntity();

        // Act
        final map = entity.toMap();
        map['id'] =
            '123e4567-e89b-12d3-a456-426614174001'; // Attempt to modify the map

        // Assert
        // The internal state of the entity should NOT change
        expect(entity.toMap()['id'], isNot('modified-id'));
      });
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
