import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMonthlyRevenueGoal extends Mock implements MonthlyRevenueGoal {}

void main() {
  group(
    'AnnualRevenueGoal Aggregate',
    () {
      // ============================================================
      /// FIXTURES
      // ============================================================

      final year2025 = Year.fromInt(2025);

      List<MonthlyRevenueGoal> validMonthlyGoals({
        double targetAmountPerMonth = 1000,
      }) {
        return List.generate(
          12,
          (index) => MonthlyRevenueGoal.create(
            year: year2025,
            month: Month.fromInt(index + 1),
            target: Money.fromDouble(targetAmountPerMonth),
            id: IdUuidV7.fromString('123e4567-e89b-12d3-a456-426614174000'),
          ),
        );
      }

      // ============================================================
      /// CONSTRUCTION — HAPPY PATH
      // ============================================================

      test(
        'should create AnnualRevenueGoal when exactly 12 monthly goals are provided',
        () {
          final monthlyGoals = validMonthlyGoals();

          final annualGoal = AnnualRevenueGoal.build(
            year: year2025,
            monthlyGoals: monthlyGoals,
          );

          expect(annualGoal.year, year2025);
          expect(annualGoal.monthlyGoals.length, 12);
        },
      );

      test('should ensure all months are unique within the annual goal', () {
        final monthlyGoals = validMonthlyGoals();

        final annualGoal = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: monthlyGoals,
        );

        final months = annualGoal.monthlyGoals.map((g) => g.month).toSet();

        expect(months.length, 12);
      });

      test(
        'should ensure all monthly goals belong to the same year as the annual goal',
        () {
          final monthlyGoals = validMonthlyGoals();

          final annualGoal = AnnualRevenueGoal.build(
            year: year2025,
            monthlyGoals: monthlyGoals,
          );

          final years = annualGoal.monthlyGoals.map((g) => g.year).toSet();

          expect(years.length, 1);
          expect(years.first, year2025);
        },
      );

      // ============================================================
      /// BUSINESS BEHAVIOR
      // ============================================================

      test('should calculate total annual target as the sum of all months', () {
        final monthlyGoals = validMonthlyGoals(
          targetAmountPerMonth: 983.973,
        );

        final annualGoal = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: monthlyGoals,
        );

        final expectedTotal =
            monthlyGoals.map((g) => g.target).reduce((a, b) => a + b);

        expect(annualGoal.totalAnnualTarget, expectedTotal);
      });

      test('should expose monthly goals ordered by month ascending', () {
        final monthlyGoals = validMonthlyGoals().reversed.toList();

        final annualGoal = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: monthlyGoals,
        );

        final months =
            annualGoal.monthlyGoals.map((g) => g.month.value).toList();

        expect(months, List.generate(12, (i) => i + 1));
      });

      // ============================================================
      /// VALUE OBJECT / AGGREGATE CONSISTENCY
      // ============================================================

      test('should behave as a value-based aggregate for equality', () {
        final a = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: validMonthlyGoals(),
        );

        final b = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: validMonthlyGoals(),
        );

        expect(a, equals(b));
      });

      test('should not be equal when monthly targets differ', () {
        final goalsA = validMonthlyGoals();
        final goalsB = validMonthlyGoals();

        goalsB[0] = MonthlyRevenueGoal.create(
          year: year2025,
          month: Month.fromInt(1),
          target: Money.fromDouble(2000),
        );

        final a = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: goalsA,
        );

        final b = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: goalsB,
        );

        expect(a == b, false);
      });

      // ============================================================
      /// INVARIANT PROTECTION (IMPLICIT)
      // ============================================================

      test('annual goal should always contain exactly one goal per month', () {
        final annualGoal = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: validMonthlyGoals(),
        );

        for (var month = 1; month <= 12; month++) {
          expect(
            annualGoal.monthlyGoals.where((g) => g.month.value == month).length,
            1,
          );
        }
      });

      // ============================================================
      /// INVARIANT VIOLATIONS — EXCEPTIONS
      // ============================================================

      test(
        'should throw AnnualRevenueGoalFailure when less than 12 monthly goals are provided',
        () {
          final monthlyGoals = validMonthlyGoals().sublist(0, 11);

          expect(
            () => AnnualRevenueGoal.build(
              year: year2025,
              monthlyGoals: monthlyGoals,
            ),
            throwsA(
              predicate(
                (e) =>
                    e is AnnualRevenueGoalFailure &&
                    e.reason ==
                        AnnualRevenueGoalFailureReason.invalidMonthsCount,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalFailure when more than 12 monthly goals are provided',
        () {
          final monthlyGoals = [
            ...validMonthlyGoals(),
            MonthlyRevenueGoal.create(
              year: year2025,
              month: Month.fromInt(1),
              target: Money.fromDouble(1000),
            ),
          ];

          expect(
            () => AnnualRevenueGoal.build(
              year: year2025,
              monthlyGoals: monthlyGoals,
            ),
            throwsA(
              predicate(
                (e) =>
                    e is AnnualRevenueGoalFailure &&
                    e.reason ==
                        AnnualRevenueGoalFailureReason.invalidMonthsCount,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalFailure when duplicate months are provided',
        () {
          final monthlyGoals = validMonthlyGoals();

          // Force duplicate month (January twice)
          monthlyGoals[1] = MonthlyRevenueGoal.create(
            year: year2025,
            month: Month.fromInt(1),
            target: Money.fromDouble(1000),
          );

          expect(
            () => AnnualRevenueGoal.build(
              year: year2025,
              monthlyGoals: monthlyGoals,
            ),
            throwsA(
              predicate(
                (e) =>
                    e is AnnualRevenueGoalFailure &&
                    e.reason == AnnualRevenueGoalFailureReason.duplicateMonth,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalFailure when monthly goals belong to different years',
        () {
          final monthlyGoals = validMonthlyGoals();

          monthlyGoals[5] = MonthlyRevenueGoal.create(
            year: Year.fromInt(2024), // mismatched year
            month: Month.fromInt(6),
            target: Money.fromDouble(1000),
          );

          expect(
            () => AnnualRevenueGoal.build(
              year: year2025,
              monthlyGoals: monthlyGoals,
            ),
            throwsA(
              predicate(
                (e) =>
                    e is AnnualRevenueGoalFailure &&
                    e.reason == AnnualRevenueGoalFailureReason.yearMismatch,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalFailure when any monthly goal target is zero',
        () {
          // Arrange
          final invalidGoal = MockMonthlyRevenueGoal();
          when(() => invalidGoal.target).thenReturn(Money.fromCents(0));
          when(() => invalidGoal.month).thenReturn(Month.fromInt(1));
          when(() => invalidGoal.year).thenReturn(year2025);

          final goals = List<MonthlyRevenueGoal>.generate(11, (index) {
            return MonthlyRevenueGoal.create(
              year: year2025,
              month: Month.fromInt(index + 2),
              target: Money.fromCents(100),
            );
          });
          goals.add(invalidGoal);

          // Act & Assert
          expect(
            () => AnnualRevenueGoal.build(
              year: year2025,
              monthlyGoals: goals,
            ),
            throwsA(
              isA<AnnualRevenueGoalFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalFailureReason.invalidMonthlyRevenueGoal,
              ),
            ),
          );
        },
      );

      test(
        'should throw AnnualRevenueGoalFailure when any monthly goal target is negative',
        () {
          // Arrange
          final invalidGoal = MockMonthlyRevenueGoal();

          when(() => invalidGoal.target).thenReturn(Money.fromCents(-100));
          when(() => invalidGoal.month).thenReturn(Month.fromInt(1));
          when(() => invalidGoal.year).thenReturn(year2025);

          final goals = List<MonthlyRevenueGoal>.generate(11, (index) {
            return MonthlyRevenueGoal.create(
              year: year2025,
              month: Month.fromInt(index + 2),
              target: Money.fromCents(100),
            );
          });
          goals.add(invalidGoal);

          // Act & Assert
          expect(
            () => AnnualRevenueGoal.build(
              year: year2025,
              monthlyGoals: goals,
            ),
            throwsA(
              isA<AnnualRevenueGoalFailure>().having(
                (f) => f.reason,
                'reason',
                AnnualRevenueGoalFailureReason.invalidMonthlyRevenueGoal,
              ),
            ),
          );
        },
      );

      // ============================================================
      /// IMMUTABILITY & DEFENSIVE COPIES
      // ============================================================

      test(
          'should not be affected by modifications to the source list after creation',
          () {
        // Arrange
        final mutableSourceList = validMonthlyGoals();
        final originalFirstGoal = mutableSourceList.first;

        final annualGoal = AnnualRevenueGoal.build(
          year: year2025,
          monthlyGoals: mutableSourceList,
        );

        // Act: Modify the source list
        mutableSourceList[0] = MonthlyRevenueGoal.create(
          year: year2025,
          month: Month.fromInt(1),
          target: Money.fromDouble(9999999),
        );

        // Assert: The annual goal should remain unchanged
        expect(annualGoal.monthlyGoals.first, equals(originalFirstGoal));
        expect(annualGoal.monthlyGoals.first.target,
            isNot(Money.fromDouble(9999999)));
      });

      test(
        'should throw UnsupportedError when trying to modify the exposed list',
        () {
          // Arrange
          final annualGoal = AnnualRevenueGoal.build(
            year: year2025,
            monthlyGoals: validMonthlyGoals(),
          );

          // Assert: Try to add an item
          expect(
            () => annualGoal.monthlyGoals.add(
              MonthlyRevenueGoal.create(
                year: year2025,
                month: Month.fromInt(1),
                target: Money.fromDouble(100),
              ),
            ),
            throwsUnsupportedError,
          );

          // Assert: Try to remove item
          expect(
            () => (annualGoal.monthlyGoals as List).clear(),
            throwsUnsupportedError,
          );

          // Assert: Try to remove an item
          expect(
            () => (annualGoal.monthlyGoals as List)[0] =
                annualGoal.monthlyGoals[1],
            throwsUnsupportedError,
          );

          // Assert: Try to sort the list
          expect(
            () => (annualGoal.monthlyGoals as List).sort((a, b) => 0),
            throwsUnsupportedError,
          );
        },
      );

      // ============================================================
      // MAPPING
      // ============================================================

      group('AnnualRevenueGoal.toMap |', () {
        // HELPER: Factory to create valid AnnualRevenueGoal (Strict Invariants)
        AnnualRevenueGoal createValidAnnualGoal({
          int yearInt = 2026,
          int monthlyTargetCents = 10000, // 100.00
        }) {
          final year = Year.fromInt(yearInt);
          final List<MonthlyRevenueGoal> monthlyGoals = [];

          for (int i = 1; i <= 12; i++) {
            monthlyGoals.add(
              MonthlyRevenueGoal.create(
                id: IdUuidV7.generate(),
                month: Month.fromInt(i),
                year: year,
                target: Money.fromCents(monthlyTargetCents),
                progress: Money.fromCents(0),
              ),
            );
          }

          return AnnualRevenueGoal.build(
            year: year,
            monthlyGoals: monthlyGoals,
          );
        }

        // TESTS
        test('Should return a Map containing all required top-level keys', () {
          // Arrange
          final entity = createValidAnnualGoal();

          // Act
          final map = entity.toMap();

          // Assert
          expect(map.containsKey('year'), isTrue);
          expect(map.containsKey('monthly_goals'), isTrue);
          expect(map.containsKey('total_annual_target_cents'), isTrue);
        });

        test('Should correctly map primitive values (Year and Total Target)',
            () {
          // Arrange
          const targetPerMonth = 5000; // 50.00
          final entity = createValidAnnualGoal(
            yearInt: 2025,
            monthlyTargetCents: targetPerMonth,
          );

          // Act
          final map = entity.toMap();

          // Assert
          expect(map['year'], equals(2025));
          // Total = 5000 * 12 = 60000
          expect(map['total_annual_target_cents'], equals(60000));
        });

        test(
            'Should correctly map the List of MonthlyRevenueGoals (Recursive Mapping)',
            () {
          // Arrange
          final entity = createValidAnnualGoal(yearInt: 2024);

          // Act
          final map = entity.toMap();
          final monthlyGoalsList = map['monthly_goals'];

          // Assert
          expect(monthlyGoalsList, isA<List>());
          expect(monthlyGoalsList, hasLength(12));

          // Verify the structure of the first child item
          final firstMonthMap = monthlyGoalsList.first as Map<String, dynamic>;

          // These keys come from MonthlyRevenueGoal.toMap()
          expect(firstMonthMap['month'], equals(1));
          expect(firstMonthMap['year'], equals(2024));
          expect(firstMonthMap.containsKey('target_cents'), isTrue);
          expect(firstMonthMap.containsKey('progress_cents'), isTrue);
          expect(firstMonthMap.containsKey('id'), isTrue);
        });

        test('Should ensure correct data types in the resulting Map structure',
            () {
          // Arrange
          final entity = createValidAnnualGoal();

          // Act
          final map = entity.toMap();

          // Assert
          expect(map['year'], isA<int>());
          expect(map['total_annual_target_cents'], isA<int>());
          expect(map['monthly_goals'], isA<List<Map<String, dynamic>>>());
        });

        test(
            'Should reflect changes in specific monthly targets in the total calculation',
            () {
          // Arrange
          // We create the list manually here to have varied values
          final year = Year.fromInt(2026);
          final List<MonthlyRevenueGoal> variedGoals = [];

          // 11 months with 1000 cents
          for (int i = 1; i <= 11; i++) {
            variedGoals.add(MonthlyRevenueGoal.create(
                month: Month.fromInt(i),
                year: year,
                target: Money.fromCents(1000)));
          }
          // December with 2000 cents
          variedGoals.add(MonthlyRevenueGoal.create(
              month: Month.fromInt(12),
              year: year,
              target: Money.fromCents(2000)));

          final entity =
              AnnualRevenueGoal.build(year: year, monthlyGoals: variedGoals);

          // Act
          final map = entity.toMap();

          // Assert
          // Expected: (11 * 1000) + 2000 = 13000
          expect(map['total_annual_target_cents'], equals(13000));

          // Verify December specifically in the list
          final goalsList = map['monthly_goals'] as List;
          final decemberMap = goalsList.firstWhere((m) => m['month'] == 12);
          expect(decemberMap['target_cents'], equals(2000));
        });

        test(
            'Should maintain Immutability (Modifying the returned map does not affect Entity)',
            () {
          // Arrange
          final entity = createValidAnnualGoal(yearInt: 2030);

          // Act
          final map = entity.toMap();
          map['year'] = 1999; // Malicious modification of the map
          (map['monthly_goals'] as List).clear(); // Malicious clearing of list

          // Assert
          // The entity should remain pristine
          expect(entity.year.value, equals(2030));
          expect(entity.monthlyGoals.length, equals(12));

          // Verify a new toMap call produces the correct original data
          expect(entity.toMap()['year'], equals(2030));
        });
      });

      // ============================================================
      /// STRINGIFY
      // ============================================================

      test(
          'toString() should return readable representation (Default Equatable)',
          () {
        // Arrange
        final tYear = Year.fromInt(2026);

        final tMonthlyGoals = List.generate(
          12,
          (index) => MonthlyRevenueGoal.create(
            year: tYear,
            month: Month.fromInt(index + 1),
            target: Money.fromCents(1000),
          ),
        );

        final annualGoal = AnnualRevenueGoal.build(
          year: tYear,
          monthlyGoals: tMonthlyGoals,
        );

        // Act
        final result = annualGoal.toString();

        // Assert
        // 1. Should contain the class name
        expect(result, startsWith('AnnualRevenueGoal'));

        // 2. Should contain the year representation (year property)
        expect(result, contains(tYear.toString()));

        // 3. Should contain the list delimiters for monthly goals
        expect(result, contains('['));
        expect(result, contains(']'));

        // 4. Should contain representations of the monthly goals
        // (at least the first one)
        expect(result, contains(tMonthlyGoals.first.toString()));
      });
    },
  );
}
