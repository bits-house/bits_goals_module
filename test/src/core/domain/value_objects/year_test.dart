import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Year Value Object', () {
    // ============================================================
    /// CONSTRUCTION
    // ============================================================

    test('should create Year when value is valid', () {
      final year = Year.fromInt(2025);

      expect(year.value, 2025);
    });

    test('should allow current year', () {
      final currentYear = DateTime.now().year;

      final year = Year.fromInt(currentYear);

      expect(year.value, currentYear);
    });

    test('should allow far future years', () {
      final year = Year.fromInt(9999);

      expect(year.value, 9999);
    });

    test('should throw InvalidYearFailure when year is zero', () {
      expect(
        () => Year.fromInt(0),
        throwsA(
          predicate((e) =>
              e is InvalidYearFailure && e.reason == InvalidYearReason.zero),
        ),
      );
    });

    test('should throw InvalidYearFailure when year is negative', () {
      expect(
        () => Year.fromInt(-2025),
        throwsA(
          predicate((e) =>
              e is InvalidYearFailure &&
              e.reason == InvalidYearReason.negative),
        ),
      );
    });

    // ============================================================
    /// COMPARISON
    // ============================================================

    test('should correctly compare years', () {
      final earlier = Year.fromInt(2024);
      final later = Year.fromInt(2025);

      expect(earlier.isBefore(later), true);
      expect(later.isAfter(earlier), true);
    });

    test('isBefore should return false for same year', () {
      final a = Year.fromInt(2025);
      final b = Year.fromInt(2025);

      expect(a.isBefore(b), false);
    });

    test('isAfter should return false for same year', () {
      final a = Year.fromInt(2025);
      final b = Year.fromInt(2025);

      expect(a.isAfter(b), false);
    });

    // ============================================================
    /// VALUE OBJECT CONTRACT
    // ============================================================

    test('two Year objects with same value should be equal', () {
      final a = Year.fromInt(2030);
      final b = Year.fromInt(2030);

      expect(a, equals(b));
    });

    test('Year should behave correctly in a Set', () {
      final years = <Year>{
        Year.fromInt(2024),
        Year.fromInt(2024),
        Year.fromInt(2025),
      };

      expect(years.length, 2);
    });

    test('Year should be safe to use as Map key', () {
      final map = {
        Year.fromInt(2024): 'past',
        Year.fromInt(2025): 'current',
      };

      expect(map[Year.fromInt(2024)], 'past');
      expect(map[Year.fromInt(2025)], 'current');
    });
  });
}
