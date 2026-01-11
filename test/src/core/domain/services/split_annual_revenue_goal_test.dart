import 'package:bits_goals_module/src/core/domain/services/split_annual_revenue_goal.dart'; // Ajuste o caminho se necessário
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitAnnualRevenueGoal Service', () {
    const splitService = SplitAnnualRevenueGoal();
    final tYear = Year.fromInt(2026);

    test(
      'should generate exactly 12 monthly goals for the correct year',
      () {
        // Arrange
        final annualTarget = Money.fromCents(1200); // 12.00

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
        final annualTarget = Money.fromCents(100);

        // Act
        final result = splitService(
          year: tYear,
          annualGoalTarget: annualTarget,
        );

        // Assert
        final zeroMoney = Money.fromCents(0);
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
        final annualTarget = Money.fromCents(1200);

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
        final annualTarget = Money.fromCents(100);

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
        final annualTarget = Money.fromCents(98765);

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
  });
}
