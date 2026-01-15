import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===========================================================================
  // DATA SETUP
  // ===========================================================================
  const tUuidString = '018b1f3c-8c08-7e3f-9b0d-7b2f4c6e8a1d';
  const tMonthInt = 10;
  const tYearInt = 2026;
  const tTargetCents = 500000;
  const tProgressCents = 150000;
  const tSchemaVersion = 1;

  final tUuid = IdUuidV7.fromString(tUuidString);
  final tMonth = Month.fromInt(tMonthInt);
  final tYear = Year.fromInt(tYearInt);
  final tTarget = Money.fromCents(tTargetCents);
  final tProgress = Money.fromCents(tProgressCents);

  final tEntity = MonthlyRevenueGoal.create(
    id: tUuid,
    month: tMonth,
    year: tYear,
    target: tTarget,
    progress: tProgress,
  );

  /// Helper to create a perfectly valid map based on the current Schema V1
  Map<String, dynamic> createValidMap() {
    return {
      MonthlyRevenueGoalRemoteModelSchemaV1.uuidV7: tUuidString,
      MonthlyRevenueGoalRemoteModelSchemaV1.month: tMonthInt,
      MonthlyRevenueGoalRemoteModelSchemaV1.year: tYearInt,
      MonthlyRevenueGoalRemoteModelSchemaV1.targetCents: tTargetCents,
      MonthlyRevenueGoalRemoteModelSchemaV1.progressCents: tProgressCents,
      MonthlyRevenueGoalRemoteModelSchemaV1.schemaVersion: tSchemaVersion,
    };
  }

  group('MonthlyRevenueGoalRemoteModel', () {
    // =========================================================================
    // 1. FROM ENTITY TESTS (Domain -> Data)
    // =========================================================================
    group('fromEntity', () {
      test(
        'should return a valid model with correct values and schema version 1',
        () {
          // Act
          final result = MonthlyRevenueGoalRemoteModel.fromEntity(tEntity);

          // Assert
          expect(result.uuidV7, equals(tUuid));
          expect(result.month, equals(tMonth));
          expect(result.year, equals(tYear));
          expect(result.target, equals(tTarget));
          expect(result.progress, equals(tProgress));
          expect(result.schemaVersion, equals(1));
        },
      );
    });

    // =========================================================================
    // 2. FROM MAP TESTS (Data -> Domain/Model)
    // =========================================================================
    group('fromMap', () {
      test('should return a valid model when the map contains correct data',
          () {
        // Arrange
        final map = createValidMap();

        // Act
        final result = MonthlyRevenueGoalRemoteModel.fromMap(map);

        // Assert
        expect(result.uuidV7.value, equals(tUuidString));
        expect(result.month.value, equals(tMonthInt));
        expect(result.year.value, equals(tYearInt));
        expect(result.target.cents, equals(tTargetCents));
        expect(result.progress.cents, equals(tProgressCents));
        expect(result.schemaVersion, equals(tSchemaVersion));
      });

      // --- Robustness Tests (Checking MapParsingExtension integration) ---

      test(
        'should parse correctly when numeric fields are Strings in the Map',
        () {
          // Arrange
          final map = createValidMap();
          map[MonthlyRevenueGoalRemoteModelSchemaV1.year] = '2026';
          map[MonthlyRevenueGoalRemoteModelSchemaV1.targetCents] = '500000';

          // Act
          final result = MonthlyRevenueGoalRemoteModel.fromMap(map);

          // Assert
          expect(result.year.value, equals(2026));
          expect(result.target.cents, equals(500000));
        },
      );

      test(
        'should parse correctly when numeric fields are Doubles in the Map',
        () {
          // Arrange
          final map = createValidMap();
          // Firestore often returns doubles for integers
          map[MonthlyRevenueGoalRemoteModelSchemaV1.targetCents] = 500000.0;
          map[MonthlyRevenueGoalRemoteModelSchemaV1.month] = 10.0;

          // Act
          final result = MonthlyRevenueGoalRemoteModel.fromMap(map);

          // Assert
          expect(result.target.cents, equals(500000));
          expect(result.month.value, equals(10));
        },
      );
    });

    // =========================================================================
    // 3. ERROR HANDLING TESTS
    // =========================================================================
    group('fromMap (Error Handling)', () {
      // Logic: The parsing extension returns a default value (e.g., 'error', 0)
      // if the key is missing. The Value Objects (IdUuidV7, Month, etc.) are
      // expected to throw an exception when receiving invalid defaults.
      // The Model catches that exception and rethrows it as FormatException.

      test(
        'should throw [FormatException] when UUID is missing/invalid',
        () {
          // Arrange
          final map = createValidMap();
          // Removing the key causes extension to return default 'error'
          // IdUuidV7.fromString('error') should throw.
          map.remove(MonthlyRevenueGoalRemoteModelSchemaV1.uuidV7);

          // Act & Assert
          expect(
            () => MonthlyRevenueGoalRemoteModel.fromMap(map),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test(
        'should throw [FormatException] when Month is missing (defaults to 0)',
        () {
          // Arrange
          final map = createValidMap();
          // Removing key causes extension to return 0.
          // Month.fromInt(0) should throw (valid months are 1-12).
          map.remove(MonthlyRevenueGoalRemoteModelSchemaV1.month);

          // Act & Assert
          expect(
            () => MonthlyRevenueGoalRemoteModel.fromMap(map),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test(
        'should throw [FormatException] when Year is invalid text',
        () {
          // Arrange
          final map = createValidMap();
          // Extension tries to parse 'invalid', fails, returns default 0.
          // Year.fromInt(0) should likely throw validation error.
          map[MonthlyRevenueGoalRemoteModelSchemaV1.year] = 'invalid_year';

          // Act & Assert
          expect(
            () => MonthlyRevenueGoalRemoteModel.fromMap(map),
            throwsA(isA<FormatException>()),
          );
        },
      );
    });

    test(
      'should throw [FormatException] when Target Money is missing/invalid text',
      () {
        // Arrange
        final map = createValidMap();
        map[MonthlyRevenueGoalRemoteModelSchemaV1.targetCents] = 'invalid';

        // Act & Assert
        expect(
          () => MonthlyRevenueGoalRemoteModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'should throw [FormatException] when Progress Money is invalid text',
      () {
        // Arrange
        final map = createValidMap();
        map[MonthlyRevenueGoalRemoteModelSchemaV1.progressCents] =
            'not_a_number';

        // Act & Assert
        expect(
          () => MonthlyRevenueGoalRemoteModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      },
    );

    // =========================================================================
    // 4. TO MAP TESTS (Serialization)
    // =========================================================================
    group('toMap', () {
      test('should return a Map containing the correct JSON structure', () {
        // Arrange
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(tEntity);

        // Act
        final result = model.toMap();

        // Assert
        final expectedMap = createValidMap();
        expect(result, equals(expectedMap));
      });
    });

    // =========================================================================
    // 5. EQUATABLE TESTS
    // =========================================================================
    group('Equatable', () {
      test('should be equal when two models have the same values', () {
        final model1 = MonthlyRevenueGoalRemoteModel.fromMap(createValidMap());
        final model2 = MonthlyRevenueGoalRemoteModel.fromMap(createValidMap());

        expect(model1, equals(model2));
      });

      test('should not be equal when values differ', () {
        final map1 = createValidMap();
        final map2 = createValidMap();
        // Change one value
        map2[MonthlyRevenueGoalRemoteModelSchemaV1.targetCents] = 999999;

        final model1 = MonthlyRevenueGoalRemoteModel.fromMap(map1);
        final model2 = MonthlyRevenueGoalRemoteModel.fromMap(map2);

        expect(model1, isNot(equals(model2)));
      });
      test(
          'should return a readable string containing class name and prop values',
          () {
        // Arrange
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(tEntity);

        // Act
        final result = model.toString();

        // Assert
        expect(result, startsWith('MonthlyRevenueGoalRemoteModel('));

        expect(result, contains(tUuidString));
        expect(result, contains(tYearInt.toString()));
        expect(result, contains(tMonthInt.toString()));
        expect(result, contains(tTargetCents.toString()));
        expect(result, contains(tProgressCents.toString()));
        expect(result, contains('1'));

        expect(result, endsWith(')'));
      });
    });
  });
}
