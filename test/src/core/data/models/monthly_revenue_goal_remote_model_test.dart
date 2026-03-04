import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month.dart';
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
  const tCurrencyCode = 'BRL';
  const tSchemaVersion = 1;

  final brl = Currency.fromISO4217(tCurrencyCode);
  Money cents(int value) => Money.fromCents(cents: value, currency: brl);
  final tUuid = IdUuidV7.fromString(tUuidString);
  final tMonth = Month.fromInt(tMonthInt);
  final tYear = Year.fromInt(tYearInt);
  final tTarget = Money.fromCents(cents: tTargetCents, currency: brl);
  final tProgress = Money.fromCents(cents: tProgressCents, currency: brl);

  final tEntity = MonthlyRevenueGoal.reconstruct(
    id: tUuid,
    month: tMonth,
    year: tYear,
    target: tTarget,
    progress: tProgress,
  );

  /// Helper to create a perfectly valid map based on the current Schema V1
  Map<String, dynamic> createValidMap() {
    return {
      MonthlyRevenueGoalRemoteSchemaV1.uuidV7: tUuidString,
      MonthlyRevenueGoalRemoteSchemaV1.month: tMonthInt,
      MonthlyRevenueGoalRemoteSchemaV1.year: tYearInt,
      MonthlyRevenueGoalRemoteSchemaV1.targetCents: tTargetCents,
      MonthlyRevenueGoalRemoteSchemaV1.progressCents: tProgressCents,
      MonthlyRevenueGoalRemoteSchemaV1.currencyCode: tCurrencyCode,
      MonthlyRevenueGoalRemoteSchemaV1.schemaVersion: tSchemaVersion,
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
          map[MonthlyRevenueGoalRemoteSchemaV1.year] = '2026';
          map[MonthlyRevenueGoalRemoteSchemaV1.targetCents] = '500000';

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
          map[MonthlyRevenueGoalRemoteSchemaV1.targetCents] = 500000.0;
          map[MonthlyRevenueGoalRemoteSchemaV1.month] = 10.0;

          // Act
          final result = MonthlyRevenueGoalRemoteModel.fromMap(map);

          // Assert
          expect(result.target.cents, equals(500000));
          expect(result.month.value, equals(10));
        },
      );

      test(
          'should default schemaVersion to currentSchemaVersion when missing from the map',
          () {
        // Arrange
        final map = createValidMap();
        map.remove(MonthlyRevenueGoalRemoteSchemaV1.schemaVersion);

        // Act
        final result = MonthlyRevenueGoalRemoteModel.fromMap(map);

        // Assert
        expect(
            result.schemaVersion,
            equals(
              MonthlyRevenueGoalRemoteModel.currentSchemaVersion,
            ));
      });
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
          map.remove(MonthlyRevenueGoalRemoteSchemaV1.uuidV7);

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
          map.remove(MonthlyRevenueGoalRemoteSchemaV1.month);

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
          map[MonthlyRevenueGoalRemoteSchemaV1.year] = 'invalid_year';

          // Act & Assert
          expect(
            () => MonthlyRevenueGoalRemoteModel.fromMap(map),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test('should throw [FormatException] when currencyCode is missing', () {
        // Arrange
        final map = createValidMap();
        map.remove(MonthlyRevenueGoalRemoteSchemaV1.currencyCode);

        // Act & Assert
        expect(
          () => MonthlyRevenueGoalRemoteModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw [FormatException] when currencyCode is invalid', () {
        // Arrange
        final map = createValidMap();
        map[MonthlyRevenueGoalRemoteSchemaV1.currencyCode] = 'INVALID_COIN';

        // Act & Assert
        expect(
          () => MonthlyRevenueGoalRemoteModel.fromMap(map),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw [FormatException] when parsing an entirely empty map',
          () {
        // Act & Assert
        expect(
          () => MonthlyRevenueGoalRemoteModel.fromMap(const {}),
          throwsA(isA<FormatException>()),
        );
      });
    });

    test(
      'should throw [FormatException] when Target Money is missing/invalid text',
      () {
        // Arrange
        final map = createValidMap();
        map[MonthlyRevenueGoalRemoteSchemaV1.targetCents] = 'invalid';

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
        map[MonthlyRevenueGoalRemoteSchemaV1.progressCents] = 'not_a_number';

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

    // ============================================================
    // MAPPING / SERIALIZATION
    //
    // The domain entity does not serialize itself; remote models do.
    // ============================================================

    group('Mapping (MonthlyRevenueGoalRemoteModel.toMap) |', () {
      MonthlyRevenueGoal createEntityForMapping({
        String uuidV7 = '123e4567-e89b-12d3-a456-426614174000',
        int month = 5,
        int year = 2026,
        int targetCents = 100000,
        int progressCents = 50000,
      }) {
        return MonthlyRevenueGoal.reconstruct(
          id: IdUuidV7.fromString(uuidV7),
          month: Month.fromInt(month),
          year: Year.fromInt(year),
          target: cents(targetCents),
          progress: cents(progressCents),
        );
      }

      test('should return a Map with all correct keys and values', () {
        // Arrange
        final entity = createEntityForMapping(
          month: 12,
          year: 2025,
          targetCents: 5000,
          progressCents: 2500,
        );
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(entity);

        // Act
        final result = model.toMap();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.uuidV7],
            '123e4567-e89b-12d3-a456-426614174000');
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.month], 12);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.year], 2025);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents], 5000);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.progressCents], 2500);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.currencyCode], 'BRL');
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.schemaVersion], 1);
      });

      test('should have exactly 7 keys in the map', () {
        // Arrange
        final model =
            MonthlyRevenueGoalRemoteModel.fromEntity(createEntityForMapping());

        // Act
        final result = model.toMap();

        // Assert
        expect(result.length, 7);
        expect(
          result.keys,
          containsAll(
            [
              MonthlyRevenueGoalRemoteSchemaV1.uuidV7,
              MonthlyRevenueGoalRemoteSchemaV1.month,
              MonthlyRevenueGoalRemoteSchemaV1.year,
              MonthlyRevenueGoalRemoteSchemaV1.targetCents,
              MonthlyRevenueGoalRemoteSchemaV1.progressCents,
              MonthlyRevenueGoalRemoteSchemaV1.currencyCode,
              MonthlyRevenueGoalRemoteSchemaV1.schemaVersion,
            ],
          ),
        );
      });

      test('should ensure data types match infrastructure expectations', () {
        // Arrange
        final model =
            MonthlyRevenueGoalRemoteModel.fromEntity(createEntityForMapping());

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.uuidV7], isA<String>());
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.month], isA<int>());
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.year], isA<int>());
        expect(
            result[MonthlyRevenueGoalRemoteSchemaV1.targetCents], isA<int>());
        expect(
            result[MonthlyRevenueGoalRemoteSchemaV1.progressCents], isA<int>());
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.currencyCode],
            isA<String>());
        expect(
            result[MonthlyRevenueGoalRemoteSchemaV1.schemaVersion], isA<int>());
      });

      test(
          'should be a stable representation (calling twice returns same data)',
          () {
        // Arrange
        final model =
            MonthlyRevenueGoalRemoteModel.fromEntity(createEntityForMapping());

        // Act
        final firstMap = model.toMap();
        final secondMap = model.toMap();

        // Assert
        expect(firstMap, equals(secondMap));
      });

      test('should ensure returned Map is a new instance (immutability check)',
          () {
        // Arrange
        final entity = createEntityForMapping();
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(entity);

        // Act
        final map = model.toMap();
        map[MonthlyRevenueGoalRemoteSchemaV1.uuidV7] =
            '123e4567-e89b-12d3-a456-426614174001';

        // Assert
        expect(model.toMap()[MonthlyRevenueGoalRemoteSchemaV1.uuidV7],
            equals('123e4567-e89b-12d3-a456-426614174000'));
        expect(entity.id.value, equals('123e4567-e89b-12d3-a456-426614174000'));
      });

      test('should preserve exact cents values in toMap', () {
        // Arrange
        const targetCents = 123456;
        const progressCents = 987654;
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(
            targetCents: targetCents,
            progressCents: progressCents,
          ),
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents],
            equals(targetCents));
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.progressCents],
            equals(progressCents));
      });

      test('should handle minimum valid values in toMap', () {
        // Arrange
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(
            month: 1,
            year: 2000,
            targetCents: 1,
            progressCents: 0,
          ),
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.month], 1);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.year], 2000);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents], 1);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.progressCents], 0);
      });

      test('should handle maximum valid values in toMap', () {
        // Arrange
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(
            month: 12,
            year: 9999,
            targetCents: 999999999,
            progressCents: 999999999,
          ),
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.month], 12);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.year], 9999);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents], 999999999);
        expect(
            result[MonthlyRevenueGoalRemoteSchemaV1.progressCents], 999999999);
      });

      test('should correctly map when progress exceeds target', () {
        // Arrange
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(
            targetCents: 5000,
            progressCents: 10000,
          ),
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents], 5000);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.progressCents], 10000);
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.progressCents],
            greaterThan(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents]));
      });

      test('should correctly map when progress equals target', () {
        // Arrange
        const sameCents = 50000;
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(
            targetCents: sameCents,
            progressCents: sameCents,
          ),
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.targetCents],
            equals(result[MonthlyRevenueGoalRemoteSchemaV1.progressCents]));
      });

      test('should handle UUID string format preservation in toMap', () {
        // Arrange
        const testUuidString = 'aaaabbbb-cccc-dddd-eeee-ffffffffffff';
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(uuidV7: testUuidString),
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.uuidV7],
            equals(testUuidString));
        expect(result[MonthlyRevenueGoalRemoteSchemaV1.uuidV7], isA<String>());
      });

      test('should not mutate internal state when Map is modified', () {
        // Arrange
        final model = MonthlyRevenueGoalRemoteModel.fromEntity(
          createEntityForMapping(
            targetCents: 5000,
            progressCents: 2500,
          ),
        );

        // Act
        final firstMap = model.toMap();
        firstMap[MonthlyRevenueGoalRemoteSchemaV1.targetCents] = 99999;
        firstMap[MonthlyRevenueGoalRemoteSchemaV1.progressCents] = 88888;
        final secondMap = model.toMap();

        // Assert
        expect(secondMap[MonthlyRevenueGoalRemoteSchemaV1.targetCents],
            equals(5000));
        expect(secondMap[MonthlyRevenueGoalRemoteSchemaV1.progressCents],
            equals(2500));
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
        map2[MonthlyRevenueGoalRemoteSchemaV1.targetCents] = 999999;

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
