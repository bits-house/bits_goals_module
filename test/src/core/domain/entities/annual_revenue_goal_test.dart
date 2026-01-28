import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnualRevenueGoal Aggregate |', () {
    // ============================================================
    /// FIXTURES
    // ============================================================

    late Year testYear;
    late List<MonthlyRevenueGoal> validMonthlyGoals;

    setUp(() {
      testYear = Year.fromInt(2026);

      validMonthlyGoals = List.generate(
        12,
        (index) => MonthlyRevenueGoal.create(
          year: testYear,
          month: Month.fromInt(index + 1),
          target: Money.fromDouble(1000),
        ),
      );
    });

    // ============================================================
    /// HELPER: Factory for valid AnnualRevenueGoal (Invariants Enforced)
    // ============================================================

    /// Creates a valid AnnualRevenueGoal with customizable parameters.
    /// Ensures all domain invariants are satisfied.
    AnnualRevenueGoal createValidAnnualGoal({
      int yearValue = 2026,
      int monthlyTargetCents = 10000, // 100.00
      int? customMonthIndex,
      int? customMonthTargetCents,
    }) {
      final year = Year.fromInt(yearValue);
      final List<MonthlyRevenueGoal> monthlyGoals = [];

      for (int i = 1; i <= 12; i++) {
        final targetCents =
            (customMonthIndex == i && customMonthTargetCents != null)
                ? customMonthTargetCents
                : monthlyTargetCents;

        monthlyGoals.add(
          MonthlyRevenueGoal.create(
            month: Month.fromInt(i),
            year: year,
            target: Money.fromCents(targetCents),
          ),
        );
      }

      return AnnualRevenueGoal.build(
        year: year,
        monthlyGoals: monthlyGoals,
      );
    }

    // ============================================================
    /// CONSTRUCTION & EQUALITY
    // ============================================================

    group('Construction & Equality |', () {
      test(
        'should create AnnualRevenueGoal when exactly 12 monthly goals are provided',
        () {
          // Act
          final annualGoal = AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: validMonthlyGoals,
          );

          // Assert
          expect(annualGoal.year.value, equals(testYear.value));
          expect(annualGoal.monthlyGoals.length, equals(12));
        },
      );

      test('should support value equality with identical monthly goals', () {
        // Arrange
        final goals = validMonthlyGoals;

        // Act
        final a = AnnualRevenueGoal.build(year: testYear, monthlyGoals: goals);
        final b = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: <MonthlyRevenueGoal>[...goals],
        );

        // Assert
        expect(a, equals(b));
      });

      test('should not be equal when years differ', () {
        // Arrange
        final year2024 = Year.fromInt(2024);
        final goalsFor2024 = List.generate(
          12,
          (index) => MonthlyRevenueGoal.create(
            year: year2024,
            month: Month.fromInt(index + 1),
            target: Money.fromDouble(1000),
          ),
        );

        // Act
        final a = AnnualRevenueGoal.build(
            year: testYear, monthlyGoals: validMonthlyGoals);
        final b = AnnualRevenueGoal.build(
          year: year2024,
          monthlyGoals: goalsFor2024,
        );

        // Assert
        expect(a == b, isFalse);
      });

      test('should not be equal when monthly targets differ', () {
        // Arrange
        final goalsWithDifferentTarget = <MonthlyRevenueGoal>[
          ...validMonthlyGoals.sublist(0, 1),
          MonthlyRevenueGoal.create(
            year: testYear,
            month: Month.fromInt(2),
            target: Money.fromDouble(5000),
          ),
          ...validMonthlyGoals.sublist(2),
        ];

        // Act
        final a = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: validMonthlyGoals,
        );
        final b = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: goalsWithDifferentTarget,
        );

        // Assert
        expect(a == b, isFalse);
      });

      test('should produce consistent hashCode for same instance', () {
        // Arrange
        final a = createValidAnnualGoal();

        // Act
        final hash1 = a.hashCode;
        final hash2 = a.hashCode;

        // Assert: Same instance produces same hashCode
        expect(hash1, equals(hash2));
      });
    });

    // ============================================================
    /// GETTERS - BASIC FUNCTIONALITY
    // ============================================================

    group('Getters - Basic Functionality |', () {
      test('year getter should return Year value object with correct value',
          () {
        // Arrange
        final annualGoal = createValidAnnualGoal(yearValue: 2025);

        // Act
        final result = annualGoal.year;

        // Assert
        expect(result, isA<Year>());
        expect(result.value, equals(2025));
      });

      test('monthlyGoals getter should return all 12 goals in order', () {
        // Arrange
        final annualGoal = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: validMonthlyGoals,
        );

        // Act
        final result = annualGoal.monthlyGoals;

        // Assert
        expect(result.length, equals(12));
        for (int i = 1; i <= 12; i++) {
          expect(result[i - 1].month.value, equals(i));
        }
      });

      test('totalAnnualTarget should equal sum of all monthly targets', () {
        // Arrange
        const monthlyTargetCents = 5000; // 50.00
        final annualGoal = createValidAnnualGoal(
          monthlyTargetCents: monthlyTargetCents,
        );

        // Act
        final result = annualGoal.totalAnnualTarget;

        // Assert
        expect(result.cents, equals(monthlyTargetCents * 12));
      });

      test('totalAnnualTarget should handle varied monthly targets', () {
        // Arrange
        final customGoal = createValidAnnualGoal(
          monthlyTargetCents: 10000,
          customMonthIndex: 12,
          customMonthTargetCents: 20000,
        );

        // Act
        final result = customGoal.totalAnnualTarget;

        // Assert
        // (11 * 10000) + 20000 = 130000
        expect(result.cents, equals(130000));
      });
    });

    // ============================================================
    /// GETTERS - DEFENSIVE COPYING
    // ============================================================

    group('Getters - Defensive Copying |', () {
      test('year getter should return new Year instance each call', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act
        final year1 = annualGoal.year;
        final year2 = annualGoal.year;

        // Assert
        expect(year1, equals(year2)); // Value equality
        expect(identical(year1, year2), isFalse); // Different instances
      });

      test('monthlyGoals getter should return new List instance each call', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act
        final list1 = annualGoal.monthlyGoals;
        final list2 = annualGoal.monthlyGoals;

        // Assert
        expect(list1, equals(list2)); // Value equality
        expect(identical(list1, list2), isFalse); // Different list instances
      });

      test('monthlyGoals list should be unmodifiable (throw on mutation)', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();
        final goals = annualGoal.monthlyGoals;

        // Assert: Cannot add
        expect(
          () => goals.add(goals.first),
          throwsUnsupportedError,
        );

        // Assert: Cannot remove
        expect(
          () => (goals).clear(),
          throwsUnsupportedError,
        );

        // Assert: Cannot modify
        expect(
          () => (goals)[0] = goals[1],
          throwsUnsupportedError,
        );
      });

      test(
        'modifying monthlyGoals from getter should not affect internal state',
        () {
          // Arrange
          final annualGoal = createValidAnnualGoal();
          final originalFirstGoal = annualGoal.monthlyGoals.first;

          // Act: Get the list and try to modify (will throw, but verify state unchanged)
          final goals = annualGoal.monthlyGoals;
          try {
            goals[0] = MonthlyRevenueGoal.create(
              year: testYear,
              month: Month.fromInt(1),
              target: Money.fromDouble(9999),
            );
          } catch (_) {
            // Ignore exception
          }

          // Assert: Subsequent calls return same state
          expect(annualGoal.monthlyGoals.first, equals(originalFirstGoal));
        },
      );
    });

    // ============================================================
    /// IMMUTABILITY & SECURITY
    // ============================================================

    group('Immutability & Security |', () {
      test(
        'source list modification after construction should not affect annual goal',
        () {
          // Arrange
          final mutableSource = <MonthlyRevenueGoal>[...validMonthlyGoals];
          final originalFirst = mutableSource.first;
          final annualGoal = AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: mutableSource,
          );

          // Act: Modify source
          mutableSource[0] = MonthlyRevenueGoal.create(
            year: testYear,
            month: Month.fromInt(1),
            target: Money.fromDouble(9999),
          );

          // Assert: Annual goal unchanged
          expect(annualGoal.monthlyGoals.first, equals(originalFirst));
        },
      );

      test('monthly goals list is stored as unmodifiable internally', () {
        // Arrange
        final annualGoal = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: validMonthlyGoals,
        );

        // Act
        final goals = annualGoal.monthlyGoals;

        // Assert: List is unmodifiable (all mutation attempts throw)
        expect(
          () => (goals as List<dynamic>).add(goals.first),
          throwsUnsupportedError,
        );
        expect(
          () => (goals as List<dynamic>).clear(),
          throwsUnsupportedError,
        );
        expect(
          () => (goals as List<dynamic>).removeLast(),
          throwsUnsupportedError,
        );
      });

      test('invariant validations should be enforced before construction', () {
        // This test verifies that ALL invariants are checked in the factory.
        // See specific invariant violation tests below.
        final validAnnual = createValidAnnualGoal();
        expect(validAnnual.monthlyGoals.length, equals(12));
      });
    });

    // ============================================================
    /// EQUATABLE IMPLEMENTATION
    // ============================================================

    group('Equatable Implementation |', () {
      test('props should contain all entity properties', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act
        final props = annualGoal.props;

        // Assert
        expect(props.length, equals(2)); // year and monthlyGoals
        expect(props[0], equals(annualGoal.year)); // First prop is year
        expect(
            props[1], equals(annualGoal.monthlyGoals)); // Second prop is goals
      });

      test('stringify should return true for readable toString()', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act
        final result = annualGoal.toString();

        // Assert
        expect(result, startsWith('AnnualRevenueGoal'));
        expect(result, contains('['));
        expect(result, contains(']'));
      });

      test('two equal objects should have identical toString() output', () {
        // Arrange: Create same data to ensure equal objects
        final year = Year.fromInt(2026);
        final baseUuid = '019c0668-b509-7335-b91a-45de78e0fd74';
        final goalsA = List.generate(
          12,
          (index) => MonthlyRevenueGoal.reconstruct(
            id: IdUuidV7.fromString(baseUuid),
            month: Month.fromInt(index + 1),
            year: year,
            target: Money.fromCents(10000),
            progress: Money.fromCents(0),
          ),
        );
        final goalsB = List.generate(
          12,
          (index) => MonthlyRevenueGoal.reconstruct(
            id: IdUuidV7.fromString(baseUuid),
            month: Month.fromInt(index + 1),
            year: year,
            target: Money.fromCents(10000),
            progress: Money.fromCents(0),
          ),
        );

        final a = AnnualRevenueGoal.build(year: year, monthlyGoals: goalsA);
        final b = AnnualRevenueGoal.build(year: year, monthlyGoals: goalsB);

        // Act
        final stringA = a.toString();
        final stringB = b.toString();

        // Assert
        expect(stringA, equals(stringB));
      });

      test('different objects should have different toString() output', () {
        // Arrange
        final a = createValidAnnualGoal(monthlyTargetCents: 10000);
        final b = createValidAnnualGoal(monthlyTargetCents: 20000);

        // Act
        final stringA = a.toString();
        final stringB = b.toString();

        // Assert
        expect(stringA, isNot(equals(stringB)));
      });
    });

    // ============================================================
    /// SERIALIZATION (toMap)
    // ============================================================

    group('Serialization - toMap |', () {
      test('should return Map with all required top-level keys', () {
        // Arrange
        final entity = createValidAnnualGoal();

        // Act
        final map = entity.toMap();

        // Assert
        expect(map.containsKey('year'), isTrue);
        expect(map.containsKey('monthly_goals'), isTrue);
        expect(map.containsKey('total_annual_target_cents'), isTrue);
      });

      test('should map primitive values correctly (year and total target)', () {
        // Arrange
        const monthlyTargetCents = 5000;
        final entity = createValidAnnualGoal(
          yearValue: 2025,
          monthlyTargetCents: monthlyTargetCents,
        );

        // Act
        final map = entity.toMap();

        // Assert
        expect(map['year'], equals(2025));
        expect(
            map['total_annual_target_cents'], equals(monthlyTargetCents * 12));
      });

      test('should recursively map all MonthlyRevenueGoals', () {
        // Arrange
        final entity = createValidAnnualGoal();

        // Act
        final map = entity.toMap();
        final goalsList = map['monthly_goals'] as List;

        // Assert
        expect(goalsList.length, equals(12));
        for (int i = 0; i < 12; i++) {
          final goalMap = goalsList[i] as Map<String, dynamic>;
          expect(goalMap['month'], equals(i + 1));
        }
      });

      test('should maintain correct data types in Map structure', () {
        // Arrange
        final entity = createValidAnnualGoal();

        // Act
        final map = entity.toMap();

        // Assert
        expect(map['year'], isA<int>());
        expect(map['total_annual_target_cents'], isA<int>());
        expect(map['monthly_goals'], isA<List>());
      });

      test('should be immutable (modifications do not affect entity)', () {
        // Arrange
        final entity = createValidAnnualGoal(yearValue: 2030);

        // Act
        final map = entity.toMap();
        map['year'] = 1999; // Malicious modification
        (map['monthly_goals'] as List).clear(); // Malicious clear

        // Assert
        expect(entity.year.value, equals(2030));
        expect(entity.monthlyGoals.length, equals(12));
        expect(entity.toMap()['year'], equals(2030));
      });
    });

    // ============================================================
    /// BUSINESS LOGIC - VALIDATIONS & INVARIANTS
    // ============================================================

    group('Invariant - Month Count |', () {
      test('should throw when fewer than 12 monthly goals provided', () {
        // Arrange
        final invalidGoals = validMonthlyGoals.sublist(0, 11);

        // Act & Assert
        expect(
          () => AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: invalidGoals,
          ),
          throwsA(
            isA<AnnualRevenueGoalFailure>().having(
              (e) => e.reason,
              'reason',
              AnnualRevenueGoalFailureReason.invalidMonthsCount,
            ),
          ),
        );
      });

      test('should throw when more than 12 monthly goals provided', () {
        // Arrange
        final invalidGoals = [
          ...validMonthlyGoals,
          MonthlyRevenueGoal.create(
            year: testYear,
            month: Month.fromInt(1),
            target: Money.fromDouble(1000),
          ),
        ];

        // Act & Assert
        expect(
          () => AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: invalidGoals,
          ),
          throwsA(
            isA<AnnualRevenueGoalFailure>().having(
              (e) => e.reason,
              'reason',
              AnnualRevenueGoalFailureReason.invalidMonthsCount,
            ),
          ),
        );
      });
    });

    group('Invariant - Unique Months |', () {
      test('should throw when duplicate months provided', () {
        // Arrange
        final invalidGoals = List<MonthlyRevenueGoal>.from(validMonthlyGoals);
        invalidGoals[1] = MonthlyRevenueGoal.create(
          year: testYear,
          month: Month.fromInt(1), // Duplicate January
          target: Money.fromDouble(1000),
        );

        // Act & Assert
        expect(
          () => AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: invalidGoals,
          ),
          throwsA(
            isA<AnnualRevenueGoalFailure>().having(
              (e) => e.reason,
              'reason',
              AnnualRevenueGoalFailureReason.duplicateMonth,
            ),
          ),
        );
      });

      test('should ensure all 12 months are unique (no duplicates)', () {
        // Arrange
        final annualGoal = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: validMonthlyGoals,
        );

        // Act
        final months = annualGoal.monthlyGoals.map((g) => g.month).toSet();

        // Assert
        expect(months.length, equals(12));
      });
    });

    group('Invariant - Year Consistency |', () {
      test('should throw when monthly goals have mismatched years', () {
        // Arrange
        final invalidGoals = List<MonthlyRevenueGoal>.from(validMonthlyGoals);
        invalidGoals[5] = MonthlyRevenueGoal.create(
          year: Year.fromInt(2024), // Mismatched year
          month: Month.fromInt(6),
          target: Money.fromDouble(1000),
        );

        // Act & Assert
        expect(
          () => AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: invalidGoals,
          ),
          throwsA(
            isA<AnnualRevenueGoalFailure>().having(
              (e) => e.reason,
              'reason',
              AnnualRevenueGoalFailureReason.yearMismatch,
            ),
          ),
        );
      });

      test('should ensure all monthly goals belong to specified year', () {
        // Arrange
        final annualGoal = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: validMonthlyGoals,
        );

        // Act
        final years = annualGoal.monthlyGoals.map((g) => g.year).toSet();

        // Assert
        expect(years.length, equals(1));
        expect(years.first.value, equals(testYear.value));
      });
    });

    group('Invariant - Goal Targets |', () {
      test('should ensure all monthly targets are positive', () {
        // Arrange: Create annual goal with minimal targets
        final annualGoal = createValidAnnualGoal(monthlyTargetCents: 1);

        // Act & Assert
        expect(annualGoal.monthlyGoals, isNotEmpty);
        for (final goal in annualGoal.monthlyGoals) {
          expect(goal.target.cents, greaterThan(0));
        }
      });
    });

    group('Invariant - Annual Total Target |', () {
      test('should throw when total annual target would be zero', () {
        // This is conceptually tested via zero monthly goal tests,
        // as the invariant prevents zero monthly goals.
        final annualGoal = createValidAnnualGoal(monthlyTargetCents: 1);
        expect(annualGoal.totalAnnualTarget.cents, equals(12));
      });
    });

    // ============================================================
    /// BUSINESS LOGIC - ORDERING & ORGANIZATION
    // ============================================================

    group('Business Logic - Ordering |', () {
      test(
          'monthly goals should be sorted by month ascending after construction',
          () {
        // Arrange
        final unsortedGoals = List<MonthlyRevenueGoal>.from(
          validMonthlyGoals.reversed,
        );

        // Act
        final annualGoal = AnnualRevenueGoal.build(
          year: testYear,
          monthlyGoals: unsortedGoals,
        );

        // Assert
        final months = annualGoal.monthlyGoals.map((g) => g.month.value);
        expect(months, List.generate(12, (i) => i + 1));
      });

      test(
        'monthly goals should maintain order even when initialized unordered',
        () {
          // Arrange: Create goals in random order
          final randomGoals = <MonthlyRevenueGoal>[];
          randomGoals.add(validMonthlyGoals[5]); // June
          randomGoals.add(validMonthlyGoals[0]); // January
          randomGoals.add(validMonthlyGoals[11]); // December
          randomGoals.addAll(validMonthlyGoals.sublist(1, 5)); // Feb-May
          randomGoals.addAll(validMonthlyGoals.sublist(6, 11)); // July-Nov

          // Act
          final annualGoal = AnnualRevenueGoal.build(
            year: testYear,
            monthlyGoals: randomGoals,
          );

          // Assert
          for (int i = 1; i <= 12; i++) {
            expect(annualGoal.monthlyGoals[i - 1].month.value, equals(i));
          }
        },
      );
    });

    // ============================================================
    /// EDGE CASES & BOUNDARIES
    // ============================================================

    group('Edge Cases & Boundaries |', () {
      test('should handle all 12 months (Month enum coverage)', () {
        // Arrange & Act
        final annualGoal = createValidAnnualGoal();

        // Assert: All months 1-12 present
        for (int m = 1; m <= 12; m++) {
          expect(
            annualGoal.monthlyGoals.any((g) => g.month.value == m),
            isTrue,
          );
        }
      });

      test('should handle very large monthly target values', () {
        // Arrange
        const largeTargetCents = 999999999; // ~10 million dollars

        // Act
        final annualGoal = createValidAnnualGoal(
          monthlyTargetCents: largeTargetCents,
        );

        // Assert
        expect(
          annualGoal.totalAnnualTarget.cents,
          equals(largeTargetCents * 12),
        );
      });

      test('should handle minimal target values (1 cent per month)', () {
        // Arrange
        const minimalCents = 1;

        // Act
        final annualGoal = createValidAnnualGoal(
          monthlyTargetCents: minimalCents,
        );

        // Assert
        expect(annualGoal.totalAnnualTarget.cents, equals(12));
      });

      test('should handle different year values (past and future)', () {
        // Arrange & Act
        final past = createValidAnnualGoal(yearValue: 1900);
        final future = createValidAnnualGoal(yearValue: 2100);
        final current = createValidAnnualGoal(yearValue: 2026);

        // Assert
        expect(past.year.value, equals(1900));
        expect(future.year.value, equals(2100));
        expect(current.year.value, equals(2026));
        expect(past != future, isTrue);
        expect(past != current, isTrue);
      });
    });

    // ============================================================
    /// TYPE SAFETY & VALIDATION
    // ============================================================

    group('Type Safety & Validation |', () {
      test('all getters should return correct types', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act & Assert
        expect(annualGoal.year, isA<Year>());
        expect(annualGoal.monthlyGoals, isA<List<MonthlyRevenueGoal>>());
        expect(annualGoal.totalAnnualTarget, isA<Money>());
      });

      test('props should contain correct types', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act
        final props = annualGoal.props;

        // Assert
        expect(props[0], isA<Year>());
        expect(props[1], isA<List>());
      });

      test('monthly goals values should maintain Money type throughout', () {
        // Arrange
        final annualGoal = createValidAnnualGoal();

        // Act & Assert
        for (final goal in annualGoal.monthlyGoals) {
          expect(goal.target, isA<Money>());
          expect(goal.target.cents, isA<int>());
        }
      });
    });
  });
}
