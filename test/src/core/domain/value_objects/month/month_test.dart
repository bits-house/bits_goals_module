import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month_name.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_reason.dart';

void main() {
  group('Month Value Object', () {
    // ============================================================
    /// CONSTRUCTION & VALIDATION
    // ============================================================

    test('should create Month for all valid values (1 to 12)', () {
      for (var i = 1; i <= 12; i++) {
        final month = Month.fromInt(i);
        expect(month.value, i);
      }
    });

    test('should throw InvalidMonthFailure when value is zero', () {
      expect(
        () => Month.fromInt(0),
        throwsA(
          predicate(
            (e) =>
                e is InvalidMonthFailure &&
                e.reason == InvalidMonthReason.belowRange,
          ),
        ),
      );
    });

    test('should throw InvalidMonthFailure when value is negative', () {
      expect(
        () => Month.fromInt(-5),
        throwsA(
          predicate(
            (e) =>
                e is InvalidMonthFailure &&
                e.reason == InvalidMonthReason.belowRange,
          ),
        ),
      );
    });

    test('should throw InvalidMonthFailure when value is greater than 12', () {
      expect(
        () => Month.fromInt(13),
        throwsA(
          predicate(
            (e) =>
                e is InvalidMonthFailure &&
                e.reason == InvalidMonthReason.aboveRange,
          ),
        ),
      );
    });

    test('should always throw same failure type for any invalid value', () {
      final invalidValues = [-100, -1, 0, 13, 99];

      for (final value in invalidValues) {
        expect(
          () => Month.fromInt(value),
          throwsA(isA<InvalidMonthFailure>()),
        );
      }
    });

    // ============================================================
    /// MONTH NAME MAPPING
    // ============================================================

    test('should map all month values to correct MonthName', () {
      final mapping = {
        1: MonthName.january,
        2: MonthName.february,
        3: MonthName.march,
        4: MonthName.april,
        5: MonthName.may,
        6: MonthName.june,
        7: MonthName.july,
        8: MonthName.august,
        9: MonthName.september,
        10: MonthName.october,
        11: MonthName.november,
        12: MonthName.december,
      };

      mapping.forEach((value, expectedName) {
        final month = Month.fromInt(value);
        expect(month.name, expectedName);
      });
    });

    // ============================================================
    /// COMPARISON HELPERS
    // ============================================================

    test('isBefore should behave correctly for all combinations', () {
      final jan = Month.fromInt(1);
      final jun = Month.fromInt(6);
      final dec = Month.fromInt(12);

      expect(jan.isBefore(jun), true);
      expect(jan.isBefore(dec), true);
      expect(jun.isBefore(dec), true);

      expect(jun.isBefore(jan), false);
      expect(dec.isBefore(jun), false);
      expect(jan.isBefore(jan), false);
    });

    test('isAfter should behave correctly for all combinations', () {
      final jan = Month.fromInt(1);
      final jun = Month.fromInt(6);
      final dec = Month.fromInt(12);

      expect(dec.isAfter(jun), true);
      expect(dec.isAfter(jan), true);
      expect(jun.isAfter(jan), true);

      expect(jan.isAfter(jun), false);
      expect(jun.isAfter(dec), false);
      expect(jan.isAfter(jan), false);
    });

    test('isSame should only return true for equal values', () {
      for (var i = 1; i <= 12; i++) {
        final a = Month.fromInt(i);
        final b = Month.fromInt(i);
        final c = Month.fromInt(i == 12 ? 1 : i + 1);

        expect(a.isSame(b), true);
        expect(a.isSame(c), false);
      }
    });

    // ============================================================
    /// DOMAIN SEMANTIC FLAGS
    // ============================================================

    test('isFirstMonth should only be true for January', () {
      for (var i = 1; i <= 12; i++) {
        final month = Month.fromInt(i);

        if (i == 1) {
          expect(month.isFirstMonth, true);
        } else {
          expect(month.isFirstMonth, false);
        }
      }
    });

    test('isLastMonth should only be true for December', () {
      for (var i = 1; i <= 12; i++) {
        final month = Month.fromInt(i);

        if (i == 12) {
          expect(month.isLastMonth, true);
        } else {
          expect(month.isLastMonth, false);
        }
      }
    });

    // ============================================================
    /// VALUE OBJECT BEHAVIOR
    // ============================================================

    test('months with same value should be equal', () {
      for (var i = 1; i <= 12; i++) {
        final a = Month.fromInt(i);
        final b = Month.fromInt(i);

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      }
    });

    test('months with different values should not be equal', () {
      final jan = Month.fromInt(1);
      final feb = Month.fromInt(2);

      expect(jan == feb, false);
    });

    test('Month should behave correctly in collections (Set)', () {
      final months = <Month>{
        Month.fromInt(1),
        Month.fromInt(1),
        Month.fromInt(5),
        Month.fromInt(12),
        Month.fromInt(12),
      };

      expect(months.length, 3);
    });

    test('Month should be safe to use as Map key', () {
      final map = {
        Month.fromInt(1): isNotNull,
        Month.fromInt(12): isNotNull,
      };

      expect(map[Month.fromInt(1)], isNotNull);
      expect(map[Month.fromInt(12)], isNotNull);
    });
  });
}
