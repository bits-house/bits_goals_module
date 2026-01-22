import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/annual_revenue_goal/annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/app_version/app_version_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/app_version/app_version_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/email/email_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/email/email_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/rep/repository_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Domain Failures', () {
    // =========================================================================
    // AnnualRevenueGoalFailure
    // =========================================================================
    test('AnnualRevenueGoalFailure', () {
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
    test('InvalidMoneyFailure', () {
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
    test('InvalidMonthFailure', () {
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
    test('MonthlyRevenueGoalFailure', () {
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
    test('RepositoryFailure', () {
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
    test('YearFailure', () {
      const failure1 = InvalidYearFailure(InvalidYearReason.negative);
      const failure2 = InvalidYearFailure(InvalidYearReason.negative);
      const failureDiff = InvalidYearFailure(InvalidYearReason.zero);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
      expect(failure1.toString(), contains('InvalidYearFailure'));
    });

    // =========================================================================
    // IdUuidV7Failure
    // =========================================================================
    test('IdUuidV7Failure', () {
      const failure1 = IdUuidV7Failure(IdUuidV7FailureReason.invalidIdFormat);
      const failure2 = IdUuidV7Failure(IdUuidV7FailureReason.invalidIdFormat);

      expect(failure1, equals(failure2));
      expect(failure1.toString(), contains('IdUuidV7Failure'));
    });

    // =========================================================================
    // LoggedInUserFailure
    // =========================================================================
    test('LoggedInUserFailure', () {
      const failure1 = LoggedInUserFailure(LoggedInUserFailureReason.emptyUid);
      const failure2 = LoggedInUserFailure(LoggedInUserFailureReason.emptyUid);
      const failureDiff =
          LoggedInUserFailure(LoggedInUserFailureReason.invalidEmail);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failureDiff)));
      expect(failure1.toString(), contains('LoggedInUserFailure'));
    });

    // =========================================================================
    // EmailFailure
    // =========================================================================
    test('EmailFailure', () {
      const failure1 = EmailFailure(EmailFailureReason.invalid);
      const failure2 = EmailFailure(EmailFailureReason.invalid);

      expect(failure1, equals(failure2));
      expect(failure1.toString(), contains('EmailFailure'));
    });

    // =========================================================================
    // AppVersionFailure
    // =========================================================================
    test('AppVersionFailure', () {
      const failure1 = AppVersionFailure(AppVersionFailureReason.invalidFormat);
      const failure2 = AppVersionFailure(AppVersionFailureReason.invalidFormat);

      expect(failure1, equals(failure2));
      expect(failure1.toString(), contains('AppVersionFailure'));
    });
  });
}
