import 'package:bits_goals_module/src/core/data/models/annual_revenue_goal_meta_remote_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnualRevenueGoalMetaRemoteModel |', () {
    group('fromYear factory', () {
      test('should create instance with year and schemaVersion=1', () {
        const testYear = 2024;

        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(testYear);

        expect(model.year, equals(testYear));
        expect(model.schemaVersion, equals(1));
      });

      test('should create instance with future year', () {
        const testYear = 2099;

        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(testYear);

        expect(model.year, equals(testYear));
        expect(model.schemaVersion, equals(1));
      });

      test('should create instance with past year', () {
        const testYear = 2000;

        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(testYear);

        expect(model.year, equals(testYear));
        expect(model.schemaVersion, equals(1));
      });

      test('should create instance with large year value', () {
        const testYear = 9999;

        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(testYear);

        expect(model.year, equals(testYear));
        expect(model.schemaVersion, equals(1));
      });
    });

    group('fromMap factory', () {
      test('should parse valid map with all fields', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: 2024,
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 1,
        };

        final model = AnnualRevenueGoalMetaRemoteModel.fromMap(map);

        expect(model.year, equals(2024));
        expect(model.schemaVersion, equals(1));
      });

      test('should parse map with different version values', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: 2025,
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 5,
        };

        final model = AnnualRevenueGoalMetaRemoteModel.fromMap(map);

        expect(model.schemaVersion, equals(5));
      });

      test('should throw FormatException when year key missing', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 1,
        };

        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(map),
          throwsFormatException,
        );
      });

      test('should throw FormatException when version key missing', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: 2024,
        };

        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(map),
          throwsFormatException,
        );
      });

      test('should throw FormatException when map is empty', () {
        final map = <String, dynamic>{};

        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(map),
          throwsFormatException,
        );
      });

      test('should throw FormatException when year is null', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: null,
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 1,
        };

        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(map),
          throwsFormatException,
        );
      });

      test('should throw FormatException when year is non-numeric string', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: 'not_a_number',
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 1,
        };

        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(map),
          throwsFormatException,
        );
      });
    });

    group('toMap method', () {
      test('should convert to map with correct keys', () {
        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);

        final map = model.toMap();

        expect(
            map.containsKey(AnnualRevenueGoalMetaCurrentSchema.year), isTrue);
        expect(
          map.containsKey(AnnualRevenueGoalMetaCurrentSchema.schemaVersion),
          isTrue,
        );
      });

      test('should serialize year and schemaVersion correctly', () {
        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);

        final map = model.toMap();

        expect(map[AnnualRevenueGoalMetaCurrentSchema.year], equals(2024));
        expect(
            map[AnnualRevenueGoalMetaCurrentSchema.schemaVersion], equals(1));
      });

      test('should preserve values in round-trip conversion', () {
        final original = AnnualRevenueGoalMetaRemoteModel.fromYear(2025);

        final map = original.toMap();
        final restored = AnnualRevenueGoalMetaRemoteModel.fromMap(map);

        expect(restored.year, equals(original.year));
        expect(restored.schemaVersion, equals(original.schemaVersion));
      });
    });

    group('Equatable', () {
      test('should be equal when same values', () {
        final model1 = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);
        final model2 = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);

        expect(model1, equals(model2));
      });

      test('should not be equal when year differs', () {
        final model1 = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);
        final model2 = AnnualRevenueGoalMetaRemoteModel.fromYear(2025);

        expect(model1, isNot(equals(model2)));
      });

      test('should include correct properties in props list', () {
        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);

        final props = model.props;

        expect(props.length, equals(2));
        expect(props[0], equals(2024));
        expect(props[1], equals(1));
      });

      test('should have stringify enabled', () {
        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);

        expect(model.stringify, isTrue);
      });

      test('should generate string representation', () {
        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(2024);

        final toString = model.toString();

        expect(toString.contains('AnnualRevenueGoalMetaRemoteModel'), isTrue);
        expect(toString.contains('2024'), isTrue);
        expect(toString.contains('1'), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle minimum year value', () {
        const minYear = 0;

        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(minYear);

        expect(model.year, equals(minYear));
      });

      test('should handle large year values', () {
        const largeYear = 9999;

        final model = AnnualRevenueGoalMetaRemoteModel.fromYear(largeYear);

        expect(model.year, equals(largeYear));
      });

      test('should preserve numeric string years from map', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: '2024',
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 1,
        };

        final model = AnnualRevenueGoalMetaRemoteModel.fromMap(map);

        expect(model.year, equals(2024));
      });

      test('should handle floating point years by truncating', () {
        final map = {
          AnnualRevenueGoalMetaCurrentSchema.year: 2024.9,
          AnnualRevenueGoalMetaCurrentSchema.schemaVersion: 1,
        };

        final model = AnnualRevenueGoalMetaRemoteModel.fromMap(map);

        expect(model.year, equals(2024));
      });
    });
  });
}
