import 'package:bits_goals_module/src/core/domain/services/split_annual_revenue_goal.dart'; // Ajuste o caminho se necessário
import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitAnnualRevenueGoal Service', () {
    const splitService = SplitAnnualRevenueGoal();
    final tYear = Year.fromInt(2026);
    final brl = Currency.fromISO4217('BRL');

    test(
      'should generate exactly 12 monthly goals for the correct year',
      () {
        // Arrange
        final annualTarget =
            Money.fromCents(cents: 1200, currency: brl); // 12.00

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        expect(result.length, 12, reason: 'A year must have 12 months');

        // Check if all goals belong to the requested year
        expect(result.every((goal) => goal.year == tYear), isTrue);
      },
    );

    test(
      'should initialize all monthly goals with zero progress',
      () {
        // Arrange
        final annualTarget = Money.fromCents(cents: 100, currency: brl);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        final zeroMoney = Money.fromCents(
          cents: 0,
          currency: annualTarget.currency,
        );
        expect(
          result.every((goal) => goal.progress == zeroMoney),
          isTrue,
          reason: 'New goals must start with 0 progress',
        );
      },
    );

    test(
      'should map months sequentially from January (1) to December (12)',
      () {
        // Arrange
        final annualTarget = Money.fromCents(cents: 1200, currency: brl);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        for (var i = 0; i < 12; i++) {
          final expectedMonthValue = i + 1;
          expect(result[i].month.value, expectedMonthValue);
        }
      },
    );

    test(
      'should correctly map the split targets to the monthly goals (Integration with Money logic)',
      () {
        // Arrange
        // 100 cents / 12 = 8 cents with remainder 4.
        // Expectation: Jan-Apr = 9 cents, May-Dec = 8 cents.
        final annualTarget = Money.fromCents(cents: 100, currency: brl);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        final firstFour = result.take(4);
        final lastEight = result.skip(4);

        expect(firstFour.every((g) => g.target.cents == 9), isTrue);
        expect(lastEight.every((g) => g.target.cents == 8), isTrue);

        // Sum integrity check
        final totalGenerated =
            result.map((g) => g.target.cents).reduce((a, b) => a + b);

        expect(totalGenerated, 100);
      },
    );

    test(
      'should ensure the sum of all monthly targets equals the original annual target (Integrity Check)',
      () {
        // Arrange
        final annualTarget = Money.fromCents(cents: 98765, currency: brl);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        final totalSum = result
            .map((g) => g.target)
            .reduce((total, current) => total + current);

        expect(totalSum, equals(annualTarget));
      },
    );

    test(
      'should preserve currency for all monthly targets',
      () {
        // Arrange
        final usd = Currency.fromISO4217('USD');
        final annualTarget = Money.fromCents(cents: 1200, currency: usd);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        expect(
          result.every((g) => g.target.currency == usd),
          isTrue,
        );
      },
    );

    test(
      'should initialize progress with the same currency as target',
      () {
        // Arrange
        final annualTarget = Money.fromCents(cents: 1200, currency: brl);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        expect(
          result.every((g) => g.progress.currency == g.target.currency),
          isTrue,
        );
        expect(
          result.every((g) => g.progress.cents == 0),
          isTrue,
        );
      },
    );
  });
}
