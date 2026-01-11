import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/repositories/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Domain Failures - Equatable & Stringify Coverage', () {
    // =========================================================================
    // AnnualRevenueGoalFailure
    // =========================================================================
    test('AnnualRevenueGoalFailure props and stringify', () {
      const failure1 =
          AnnualRevenueGoalFailure(AnnualRevenueGoalFailureReason.yearMismatch);
      const failure2 =
          AnnualRevenueGoalFailure(AnnualRevenueGoalFailureReason.yearMismatch);
      const failureDiff = AnnualRevenueGoalFailure(
          AnnualRevenueGoalFailureReason.invalidMonthsCount);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));

      expect(failure1.toString(), contains('AnnualRevenueGoalFailure'));
      expect(failure1.toString(), contains('yearMismatch'));
    });

    // =========================================================================
    // InvalidMoneyFailure
    // =========================================================================
    test('InvalidMoneyFailure props and stringify', () {
      const failure1 =
          InvalidMoneyFailure(InvalidMoneyReason.invalidSplitCount);
      const failure2 =
          InvalidMoneyFailure(InvalidMoneyReason.invalidSplitCount);
      const failureDiff =
          InvalidMoneyFailure(InvalidMoneyReason.splitNegativeCents);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));

      expect(failure1.toString(), contains('InvalidMoneyFailure'));
      expect(failure1.toString(), contains('invalidSplitCount'));
    });

    // =========================================================================
    // MonthFailure
    // =========================================================================
    test('InvalidMonthFailure props and stringify', () {
      const failure1 = InvalidMonthFailure(InvalidMonthReason.aboveRange);
      const failure2 = InvalidMonthFailure(InvalidMonthReason.aboveRange);
      const failureDiff = InvalidMonthFailure(InvalidMonthReason.belowRange);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
      expect(failure1.toString(), contains('InvalidMonthFailure'));
    });

    // =========================================================================
    // MonthlyRevenueGoalFailure
    // =========================================================================
    test('MonthlyRevenueGoalFailure props and stringify', () {
      const failure1 = MonthlyRevenueGoalFailure(
          MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget);
      const failure2 = MonthlyRevenueGoalFailure(
          MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget);

      expect(failure1, equals(failure2));
      expect(failure1.toString(), contains('MonthlyRevenueGoalFailure'));
    });

    // =========================================================================
    // RepositoryFailure
    // =========================================================================
    test('RepositoryFailure props and stringify', () {
      const failure1 =
          RepositoryFailure(reason: RepositoryFailureReason.permissionDenied);
      const failure2 =
          RepositoryFailure(reason: RepositoryFailureReason.permissionDenied);
      const failureDiff =
          RepositoryFailure(reason: RepositoryFailureReason.connectionError);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
      expect(failure1.toString(), contains('RepositoryFailure'));
    });

    // =========================================================================
    // YearFailure
    // =========================================================================
    test('YearFailure props and stringify', () {
      const failure1 = InvalidYearFailure(InvalidYearReason.negative);
      const failure2 = InvalidYearFailure(InvalidYearReason.negative);
      const failureDiff = InvalidYearFailure(InvalidYearReason.zero);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
      expect(failure1.toString(), contains('InvalidYearFailure'));
    });
  });
}
