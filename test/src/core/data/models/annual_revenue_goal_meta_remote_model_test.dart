import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/data/models/annual_revenue_goal_meta_remote_model.dart';

void main() {
  const tYear = 2026;
  const tAnnualRevenueGoalMetaRemoteModel =
      AnnualRevenueGoalMetaRemoteModel(year: tYear);

  group('AnnualRevenueGoalMetaRemoteModel', () {
    // =========================================================================
    // INSTANTIATION & EQUALITY
    // =========================================================================
    test('should be a subclass of Equatable', () {
      expect(tAnnualRevenueGoalMetaRemoteModel, isA<Equatable>());
    });

    test('should compare equality based on props (year)', () {
      const model1 = AnnualRevenueGoalMetaRemoteModel(year: 2025);
      const model2 = AnnualRevenueGoalMetaRemoteModel(year: 2025);
      const model3 = AnnualRevenueGoalMetaRemoteModel(year: 2026);

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });

    test('stringify should be enabled', () {
      expect(tAnnualRevenueGoalMetaRemoteModel.stringify, isTrue);
      expect(
        tAnnualRevenueGoalMetaRemoteModel.toString(),
        contains('AnnualRevenueGoalMetaRemoteModel'),
      );
      expect(tAnnualRevenueGoalMetaRemoteModel.toString(), contains('2026'));
    });

    // =========================================================================
    // FROM MAP
    // =========================================================================
    group('fromMap', () {
      test('should return a valid model when the Map contains correct data',
          () {
        // Arrange
        final Map<String, dynamic> jsonMap = {
          'year': 2026,
        };

        // Act
        final result = AnnualRevenueGoalMetaRemoteModel.fromMap(jsonMap);

        // Assert
        expect(result, equals(tAnnualRevenueGoalMetaRemoteModel));
      });

      test('should throw [FormatException] when the "year" key is missing', () {
        // Arrange
        final Map<String, dynamic> jsonMap = {
          'other_key': 123,
        };

        // Act
        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(jsonMap),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid AnnualRevenueGoalMetaRemoteModel',
            ),
          ),
        );
      });

      test('should throw [FormatException] when "year" is of invalid type', () {
        // Arrange
        final Map<String, dynamic> jsonMap = {
          'year': 'not_an_integer',
        };

        // Act
        expect(
          () => AnnualRevenueGoalMetaRemoteModel.fromMap(jsonMap),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid AnnualRevenueGoalMetaRemoteModel',
            ),
          ),
        );
      });
    });

    // =========================================================================
    // TO MAP
    // =========================================================================
    group('toMap', () {
      test('should return a Map containing the proper data', () {
        // Act
        final result = tAnnualRevenueGoalMetaRemoteModel.toMap();

        // Assert
        final expectedMap = {
          'year': 2026,
        };
        expect(result, equals(expectedMap));
      });
    });
  });
}
