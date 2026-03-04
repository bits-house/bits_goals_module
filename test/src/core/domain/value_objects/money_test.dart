import 'package:bits_goals_module/src/core/domain/failures/value_objects/money/invalid_money_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/value_objects/money/invalid_money_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/currency.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final brl = Currency.fromISO4217('BRL');
  final usd = Currency.fromISO4217('USD');

  group(
    'Money Value Object (cents-based)',
    () {
      // ============================================================
      /// CONSTRUCTION
      // ============================================================

      test('should create Money when value is zero', () {
        final money = Money.fromDouble(value: 0, currency: brl);
        expect(money.cents, 0);
      });

      test('should create Money when value is a whole number', () {
        final money = Money.fromDouble(value: 10, currency: brl);
        expect(money.cents, 1000);
      });

      test('should create Money when value has one decimal place', () {
        final money = Money.fromDouble(value: 10.5, currency: brl);
        expect(money.cents, 1050);
      });

      test('should create Money when value has two decimal places', () {
        final money = Money.fromDouble(value: 10.75, currency: brl);
        expect(money.cents, 1075);
      });

      test(
          'should round value correctly when more than two decimals are provided',
          () {
        final money = Money.fromDouble(value: 10.555, currency: brl);
        expect(money.cents, 1056); // Rounded to nearest cent
      });

      test(
          'should round down correctly when decimal is just below rounding threshold',
          () {
        final money = Money.fromDouble(value: 10.554, currency: brl);
        expect(money.cents, 1055);
      });

      test(
          'should create Money from negative double values correctly (negative amounts)',
          () {
        final money = Money.fromDouble(value: -5.25, currency: brl);
        expect(money.cents, -525);
      });

      test('should create Money from negative cents', () {
        final money = Money.fromCents(cents: -750, currency: brl);
        expect(money.cents, -750);
      });

      test('should store currency provided at construction time', () {
        final money = Money.fromDouble(value: 10, currency: usd);

        expect(money.currency, usd);
        expect(money.currency.code, 'USD');
      });

      // ============================================================
      /// ADDITION
      // ============================================================

      test('should add two Money values correctly', () {
        final a = Money.fromDouble(value: 100, currency: brl);
        final b = Money.fromDouble(value: 50.25, currency: brl);

        final result = a + b;

        expect(result.cents, 15025);
      });

      test('should add zero to a Money value without changing it', () {
        final a = Money.fromDouble(value: 42.80, currency: brl);
        final zero = Money.fromDouble(value: 0, currency: brl);

        final result = a + zero;

        expect(result.cents, a.cents);
      });

      test('should allow chaining multiple additions', () {
        final a = Money.fromDouble(value: 10, currency: brl);
        final b = Money.fromDouble(value: 20, currency: brl);
        final c = Money.fromDouble(value: 30, currency: brl);

        final result = a + b + c;

        expect(result.cents, 6000);
      });

      test('addition should not mutate original Money objects', () {
        final a = Money.fromDouble(value: 10, currency: brl);
        final b = Money.fromDouble(value: 5, currency: brl);

        final _ = a + b;

        expect(a.cents, 1000);
        expect(b.cents, 500);
      });

      test('should add two negative Money values correctly', () {
        // -R$ 10.00 + -R$ 5.50 = -R$ 15.50
        final a = Money.fromDouble(value: -10.00, currency: brl);
        final b = Money.fromDouble(value: -5.50, currency: brl);

        final result = a + b;

        expect(result.cents, -1550);
      });

      test(
          'should handle addition of positive and negative values (behave like subtraction)',
          () {
        // R$ 100.00 + (-R$ 30.00) = R$ 70.00
        final positive = Money.fromDouble(value: 100, currency: brl);
        final negative = Money.fromDouble(value: -30, currency: brl);

        final result = positive + negative;

        expect(result.cents, 7000);
      });

      test(
          'should return negative result when adding a large negative to a small positive',
          () {
        // R$ 10.00 + (-R$ 50.00) = -R$ 40.00
        final smallPositive = Money.fromDouble(value: 10, currency: brl);
        final largeNegative = Money.fromDouble(value: -50, currency: brl);

        final result = smallPositive + largeNegative;

        expect(result.cents, -4000);
      });

      test('should throw when adding Money with different currencies', () {
        final a = Money.fromCents(cents: 1000, currency: brl);
        final b = Money.fromCents(cents: 1000, currency: usd);

        expect(
          () => a + b,
          throwsA(
            predicate(
              (e) =>
                  e is InvalidMoneyFailure &&
                  e.reason == InvalidMoneyReason.currencyMismatch,
            ),
          ),
        );
      });

      test('addition should preserve currency in the result', () {
        final a = Money.fromCents(cents: 1000, currency: brl);
        final b = Money.fromCents(cents: 250, currency: brl);

        final result = a + b;

        expect(result.currency, brl);
      });

      // ============================================================
      /// SUBTRACTION
      // ============================================================

      test('should subtract two Money values correctly when result is positive',
          () {
        final a = Money.fromDouble(value: 200, currency: brl);
        final b = Money.fromDouble(value: 75.80, currency: brl);

        final result = a - b;

        expect(result.cents, 12420);
      });

      test('should subtract a zero value without changing the original value',
          () {
        final a = Money.fromDouble(value: 99.99, currency: brl);
        final zero = Money.fromDouble(value: 0, currency: brl);

        final result = a - zero;

        expect(result.cents, a.cents);
      });

      test('should allow subtraction resulting in exactly zero', () {
        final a = Money.fromDouble(value: 50, currency: brl);
        final b = Money.fromDouble(value: 50, currency: brl);

        final result = a - b;

        expect(result.cents, 0);
      });

      test(
        'should subtract two Money values resulting in negative value',
        () {
          final a = Money.fromDouble(value: 20, currency: brl);
          final b = Money.fromDouble(value: 30, currency: brl);

          final result = a - b;

          expect(result.cents, -1000);
        },
      );

      test(
        'should increase value when subtracting a negative amount (double negative)',
        () {
          // R$ 100.00 - (-R$ 50.00) = R$ 150.00
          // Subtracting a negative is equivalent to adding the positive
          final start = Money.fromDouble(value: 100, currency: brl);
          final negative = Money.fromDouble(value: -50, currency: brl);

          final result = start - negative;

          expect(result.cents, 15000);
        },
      );

      test(
        'should become more negative when subtracting a positive amount from a negative amount',
        () {
          // -R$ 50.00 - R$ 20.00 = -R$ 70.00
          final debt = Money.fromDouble(value: -50, currency: brl);
          final cost = Money.fromDouble(value: 20, currency: brl);

          final result = debt - cost;

          expect(result.cents, -7000);
        },
      );

      test('should allow chaining multiple subtractions', () {
        // 100 - 20 - 30 = 50
        final start = Money.fromDouble(value: 100, currency: brl);
        final a = Money.fromDouble(value: 20, currency: brl);
        final b = Money.fromDouble(value: 30, currency: brl);

        final result = start - a - b;

        expect(result.cents, 5000);
      });

      test('subtraction should not mutate original Money objects', () {
        final a = Money.fromDouble(value: 100, currency: brl);
        final b = Money.fromDouble(value: 40, currency: brl);

        final _ = a - b;

        // Ensure originals are unchanged
        expect(a.cents, 10000);
        expect(b.cents, 4000);
      });

      test('should throw when subtracting Money with different currencies', () {
        final a = Money.fromCents(cents: 1000, currency: brl);
        final b = Money.fromCents(cents: 1, currency: usd);

        expect(
          () => a - b,
          throwsA(
            predicate(
              (e) =>
                  e is InvalidMoneyFailure &&
                  e.reason == InvalidMoneyReason.currencyMismatch,
            ),
          ),
        );
      });

      test('subtraction should preserve currency in the result', () {
        final a = Money.fromCents(cents: 1000, currency: brl);
        final b = Money.fromCents(cents: 250, currency: brl);

        final result = a - b;

        expect(result.currency, brl);
      });

      // ============================================================
      /// PRECISION & SAFETY
      // ============================================================

      test('should not lose precision when adding decimal values', () {
        final a = Money.fromDouble(value: 0.1, currency: brl);
        final b = Money.fromDouble(value: 0.2, currency: brl);

        final result = a + b;

        expect(result.cents, 30); // Exactly 0.30
      });

      test('should preserve precision across multiple operations', () {
        final result = Money.fromDouble(value: 0.1, currency: brl) +
            Money.fromDouble(value: 0.2, currency: brl) +
            Money.fromDouble(value: 0.3, currency: brl);

        expect(result.cents, 60); // Exactly 0.60
      });

      // ============================================================
      /// CONVERSION
      // ============================================================

      test('should convert cents back to double correctly', () {
        final money = Money.fromDouble(value: 12.34, currency: brl);

        expect(money.toDouble(), 12.34);
      });

      test('toDouble should return zero when Money is zero', () {
        final money = Money.fromDouble(value: 0, currency: brl);

        expect(money.toDouble(), 0.0);
      });

      // ============================================================
      /// EQUALITY (VALUE OBJECT BEHAVIOR)
      // ============================================================

      test('two Money objects with same cents should be equal', () {
        final a = Money.fromDouble(value: 100, currency: brl);
        final b = Money.fromDouble(value: 100, currency: brl);

        expect(a, equals(b));
      });

      test('two Money objects with different cents should not be equal', () {
        final a = Money.fromDouble(value: 100, currency: brl);
        final b = Money.fromDouble(value: 120, currency: brl);

        expect(a == b, false);
      });

      test('Money equality should work correctly inside collections', () {
        final set = {
          Money.fromDouble(value: 10, currency: brl),
          Money.fromDouble(value: 10, currency: brl),
          Money.fromDouble(value: 20, currency: brl),
        };

        expect(set.length, 2);
      });

      test(
        'should be equal regardless of constructor used (fromCents vs fromDouble)',
        () {
          // R$ 10.50 represented as 1050 cents
          final fromCents = Money.fromCents(cents: 1050, currency: brl);
          final fromDouble = Money.fromDouble(value: 10.50, currency: brl);

          expect(fromCents, equals(fromDouble));
        },
      );

      test('hashCode should be the same for equal objects', () {
        final a = Money.fromDouble(value: 123.45, currency: brl);
        final b = Money.fromDouble(value: 123.45, currency: brl);

        // Required contract: If a == b, then a.hashCode == b.hashCode
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should work correctly as Map keys', () {
        final map = <Money, String>{};

        final keyA = Money.fromDouble(value: 50, currency: brl);
        final keyB =
            Money.fromDouble(value: 50, currency: brl); // Different instance

        map[keyA] = 'Found Me';

        // Should retrieve the value using keyB because they are equal by value
        expect(map[keyB], 'Found Me');
        expect(map.containsKey(keyB), true);
      });

      test('should handle equality for negative values correctly', () {
        final a = Money.fromDouble(value: -10, currency: brl);
        final b = Money.fromCents(cents: -1000, currency: brl);

        expect(a, equals(b));
      });

      test('should NOT be equal when cents are equal but currency differs', () {
        final brl1000 = Money.fromCents(cents: 1000, currency: brl);
        final usd1000 = Money.fromCents(cents: 1000, currency: usd);

        expect(brl1000 == usd1000, false);
      });

      test(
          'should support currency value equality (same code, different instance)',
          () {
        final brlA = Currency.fromISO4217('BRL');
        final brlB = Currency.fromISO4217('BRL');

        final a = Money.fromCents(cents: 1000, currency: brlA);
        final b = Money.fromCents(cents: 1000, currency: brlB);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should treat different currencies as different Set entries', () {
        final set = {
          Money.fromCents(cents: 1000, currency: brl),
          Money.fromCents(cents: 1000, currency: usd),
        };

        expect(set.length, 2);
      });

      test('should treat different currencies as different Map keys', () {
        final map = <Money, String>{
          Money.fromCents(cents: 1000, currency: brl): 'BRL',
          Money.fromCents(cents: 1000, currency: usd): 'USD',
        };

        expect(map[Money.fromCents(cents: 1000, currency: brl)], 'BRL');
        expect(map[Money.fromCents(cents: 1000, currency: usd)], 'USD');
      });

      // ============================================================
      // SPLIT
      // ============================================================

      test(
          'should throw InvalidMoneyFailure when trying to split a negative amount',
          () {
        final negativeMoney = Money.fromDouble(value: -100.00, currency: brl);

        expect(
          () => negativeMoney.split(2),
          throwsA(isA<InvalidMoneyFailure>()),
        );
      });

      test('should throw InvalidMoneyFailure if partsCount is zero', () {
        final money = Money.fromCents(cents: 100, currency: brl);

        expect(
          () => money.split(0),
          throwsA(isA<InvalidMoneyFailure>()),
        );
      });

      test('should throw InvalidMoneyFailure if partsCount is one', () {
        final money = Money.fromCents(cents: 100, currency: brl);

        expect(
          () => money.split(1),
          throwsA(isA<InvalidMoneyFailure>()),
        );
      });

      test('should throw InvalidMoneyFailure if partsCount is negative', () {
        final money = Money.fromCents(cents: 100, currency: brl);

        expect(
          () => money.split(-3),
          throwsA(isA<InvalidMoneyFailure>()),
        );
      });

      test('should split evenly when cents is divisible by parts', () {
        final money = Money.fromCents(cents: 120, currency: brl);

        final splits = money.split(3);

        expect(
          splits.map((m) => m.cents),
          [40, 40, 40],
        );
      });

      test('should distribute remainder to first chunks', () {
        final money = Money.fromCents(cents: 100, currency: brl);

        final splits = money.split(3);

        expect(
          splits.map((m) => m.cents),
          [34, 33, 33],
        );
      });

      test('should work with very small values', () {
        final money = Money.fromCents(cents: 1, currency: brl);

        final splits = money.split(3);

        expect(
          splits.map((m) => m.cents),
          [1, 0, 0],
        );
      });

      test('should handle when money value is zero', () {
        final money = Money.fromCents(cents: 0, currency: brl);

        final splits = money.split(4);

        expect(
          splits.map((m) => m.cents),
          [0, 0, 0, 0],
        );
      });

      test('should handle when partsCount equals cents', () {
        final money = Money.fromCents(cents: 5, currency: brl);

        final splits = money.split(5);

        expect(
          splits.map((m) => m.cents),
          [1, 1, 1, 1, 1],
        );
      });

      test('should handle when partsCount is greater than cents', () {
        final money = Money.fromCents(cents: 3, currency: brl);

        final splits = money.split(5);

        expect(
          splits.map((m) => m.cents),
          [1, 1, 1, 0, 0],
        );
      });

      test('should work with large monetary values', () {
        int cents = 1200000001349; // R$ 10,000,000,013.49

        final money = Money.fromCents(cents: cents, currency: brl);

        final splits = money.split(12);

        expect(
          splits.map((m) => m.cents),
          [
            100000000113,
            100000000113,
            100000000113,
            100000000113,
            100000000113,
            100000000112,
            100000000112,
            100000000112,
            100000000112,
            100000000112,
            100000000112,
            100000000112
          ],
        );

        final sum = splits.fold<int>(
          0,
          (acc, m) => acc + m.cents,
        );

        expect(sum, cents);
      });

      test('sum of splits should always equal original amount', () {
        final money = Money.fromCents(cents: 98765, currency: brl);

        final splits = money.split(17);

        final sum = splits.fold<int>(
          0,
          (acc, m) => acc + m.cents,
        );

        expect(sum, money.cents);

        // Define a list of challenging scenarios: (cents, parts)
        final scenarios = [
          // --- Basic Scenarios ---
          (cents: 100, parts: 3), // 100/3 = 33.33... (Simple remainder)
          (cents: 100, parts: 2), // 100/2 = 50 (No remainder)

          // --- Starvation Scenarios (Amount < Parts) ---
          // Cases where there isn't enough money to give 1 cent to everyone.
          (cents: 1, parts: 3), // 1 cent for 3 parts -> [1, 0, 0]
          (cents: 2, parts: 5), // 2 cents for 5 parts -> [1, 1, 0, 0, 0]
          (cents: 10, parts: 100), // 10 cents for 100 parts

          // --- Identity and Equality Scenarios ---
          (cents: 50, parts: 50), // Amount equals parts (1 cent each)
          (cents: 992, parts: 2), // Division by 2 to check even split integrity

          // --- Zero Amount Scenarios ---
          (cents: 0, parts: 5), // 0 divided by 5 is 0
          (cents: 0, parts: 2), // 0 divided by 2 is 0

          // --- Complex Remainders (Prime Divisors) ---
          // Prime numbers often cause repeating decimals, stressing the remainder logic.
          (cents: 100, parts: 7), // 100/7
          (cents: 100, parts: 11), // 100/11
          (cents: 100, parts: 13), // 100/13
          (cents: 100, parts: 17), // 100/17
          (cents: 1000, parts: 97), // Large prime divisor

          // --- Large Amounts (Stress Test) ---
          // Ensure logic holds for larger integer values.
          (cents: 1000000, parts: 3), // 1 million / 3
          (cents: 9999999, parts: 10), // Nearly 10 million / 10
        ];

        for (final scenario in scenarios) {
          // Arrange
          final money = Money.fromCents(cents: scenario.cents, currency: brl);

          // Act
          final splits = money.split(scenario.parts);

          // Calculate Sum
          final sum = splits.fold<int>(
            0,
            (acc, m) => acc + m.cents,
          );

          // Assert
          expect(
            sum,
            money.cents,
            reason:
                'Failed integrity check for scenario: ${scenario.cents} cents split into ${scenario.parts} parts',
          );

          // Extra Validation: The list length must strictly match the requested parts
          expect(splits.length, scenario.parts);
        }
      });

      test(
        'splits should never differ by more than 1 cent for many values',
        () {
          for (var cents = 0; cents <= 500; cents++) {
            for (var parts = 2; parts <= 12; parts++) {
              final money = Money.fromCents(cents: cents, currency: brl);
              final splits = money.split(parts);

              final values = splits.map((m) => m.cents).toList();
              final max = values.reduce((a, b) => a > b ? a : b);
              final min = values.reduce((a, b) => a < b ? a : b);

              expect(
                max - min <= 1,
                true,
                reason: 'Failed for cents=$cents parts=$parts values=$values',
              );
            }
          }
        },
      );

      test('should return a list with length strictly equal to parts', () {
        // Define scenarios with varying amounts and part counts
        final scenarios = [
          // --- Standard Scenarios ---
          (cents: 100, parts: 8), // Original case
          (cents: 50, parts: 2), // Simple even split

          // --- Zero Amount Scenarios ---
          // Even if the amount is zero, we must return the requested number of (zero) objects.
          (cents: 0, parts: 5),
          (cents: 0, parts: 100),

          // --- Starvation Scenarios (Amount < Parts) ---
          // Even if we don't have enough cents to fill every bucket,
          // the list length must still match the requested parts (filling the rest with zeros).
          (cents: 1, parts: 10), // 1 cent split into 10 parts
          (cents: 5, parts: 20), // 5 cents split into 20 parts

          // --- High Volume Scenarios ---
          // Testing larger list generation.
          (cents: 10000, parts: 1000),
        ];

        for (final scenario in scenarios) {
          // Arrange
          final money = Money.fromCents(cents: scenario.cents, currency: brl);

          // Act
          final splits = money.split(scenario.parts);

          // Assert
          expect(
            splits.length,
            scenario.parts,
            reason:
                'Failed length check for splitting ${scenario.cents} cents into ${scenario.parts} parts',
          );
        }
      });

      test('split should preserve currency across all generated parts', () {
        final money = Money.fromCents(cents: 100, currency: usd);

        final splits = money.split(3);

        expect(splits.map((m) => m.currency), [usd, usd, usd]);
      });
    },
  );
}
