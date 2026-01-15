import 'package:flutter_test/flutter_test.dart';
// Adjust the import to the actual location of your file
import 'package:bits_goals_module/src/core/data/extensions/map_parsing_extension.dart';

void main() {
  group('MapParsingExtension', () {
    // =========================================================================
    // TESTS: getInt
    // =========================================================================
    group('getInt', () {
      const currentKey = 'current_key_v3';
      const lastKey = 'legacy_key_v2';
      const veryOldKey = 'legacy_key_v1';
      const kDefault = -1;

      test(
          'should return the exact int value when the key exists and is an int',
          () {
        final map = {currentKey: 42};

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(42));
      });

      test(
          'should convert double to int (truncating) when the value is a double',
          () {
        // Firestore often returns doubles for integer numbers
        final map = {currentKey: 42.9};

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(42)); // .toInt() removes the decimal part
      });

      test('should parse a valid numeric double String', () {
        final map = {currentKey: '100.0'};

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(100));
      });

      test('should parse a valid numeric String', () {
        final map = {currentKey: '100'};

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(100));
      });

      test('should return defaultValue when the String is not numeric', () {
        final map = {currentKey: 'abc'}; // Not parseable

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(kDefault));
      });

      test('should return defaultValue when the value is null', () {
        final map = {currentKey: null};

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(kDefault));
      });

      test('should return defaultValue when the key does not exist', () {
        final map = {'something_else': 123};

        final result = map.getInt(key: currentKey, defaultValue: kDefault);

        expect(result, equals(kDefault));
      });

      // --- LEGACY KEYS AND PRIORITY TESTS ---

      test('should prioritize the main key over legacy keys', () {
        final map = {
          veryOldKey: 30,
          lastKey: 20,
          currentKey: 10, // Should win
          'some_other_key': 0,
        };

        final result = map.getInt(
            key: currentKey, legacyKeys: [lastKey], defaultValue: kDefault);

        expect(result, equals(10));
      });

      test('should use the first legacy key if the main key is missing', () {
        final map = {
          // currentKey is missing
          lastKey: 20, // Should win
          veryOldKey: 30,
        };

        final result = map.getInt(
            key: currentKey,
            legacyKeys: [lastKey, veryOldKey],
            defaultValue: kDefault);

        expect(result, equals(20));
      });

      test('should respect the order of the legacy keys list', () {
        final map = {
          // currentKey is missing
          veryOldKey: 30, // Present in map, but second in list
          lastKey: 20, // Present in map and first in list
        };

        // The array order defines the search priority
        final result = map.getInt(
            key: currentKey,
            legacyKeys: [lastKey, veryOldKey],
            defaultValue: kDefault);

        expect(result, equals(20));
      });

      test(
          'should skip legacy key if its value is invalid (and try the next one)',
          () {
        final map = {
          lastKey: 'invalid_text', // Exists, but parse fails
          veryOldKey: 30, // Valid
        };

        final result = map.getInt(
            key: currentKey,
            legacyKeys: [lastKey, veryOldKey],
            defaultValue: kDefault);

        expect(result, equals(30));
      });

      test('should return defaultValue if neither main nor legacy keys exist',
          () {
        final map = {'nothing_related': 0};

        final result = map.getInt(
            key: currentKey, legacyKeys: [lastKey], defaultValue: kDefault);

        expect(result, equals(kDefault));
      });
    });

    // =========================================================================
    // TESTS: getString
    // =========================================================================
    group('getString', () {
      const currentKey = 'name_v3';
      const lastKey = 'full_name_v2';
      const veryOldKey = 'username_v1';
      const kDefault = 'unknown';

      test('should return the exact string when the value is a string', () {
        final map = {currentKey: 'Matheus'};

        final result = map.getString(key: currentKey, defaultValue: kDefault);

        expect(result, equals('Matheus'));
      });

      test('should convert int to String', () {
        final map = {currentKey: 123};

        final result = map.getString(key: currentKey, defaultValue: kDefault);

        expect(result, equals('123'));
      });

      test('should convert double to String', () {
        final map = {currentKey: 10.5};

        final result = map.getString(key: currentKey, defaultValue: kDefault);

        expect(result, equals('10.5'));
      });

      test('should convert bool to String', () {
        final map = {currentKey: true};

        final result = map.getString(key: currentKey, defaultValue: kDefault);

        expect(result, equals('true'));
      });

      test('should return defaultValue if the value is null', () {
        final map = {currentKey: null};

        final result = map.getString(key: currentKey, defaultValue: kDefault);

        expect(result, equals(kDefault));
      });

      test('should return defaultValue if the key does not exist', () {
        final map = {'other': 'thing'};

        final result = map.getString(key: currentKey, defaultValue: kDefault);

        expect(result, equals(kDefault));
      });

      test(
          'should throw [FormatException] if the key does not exist and no defaultValue',
          () {
        final map = {'other': 'thing'};

        expect(() => map.getString(key: currentKey),
            throwsA(isA<FormatException>()));
      });

      // --- LEGACY KEYS ---

      test('should prioritize the main key', () {
        final map = {
          'some_other_key': 'Ignored',
          currentKey: 'New',
          lastKey: 'Old',
          veryOldKey: 'Very Old',
        };

        final result = map.getString(
            key: currentKey, legacyKeys: [lastKey], defaultValue: kDefault);

        expect(result, equals('New'));
      });

      test('should fallback to legacy key if the main key is missing', () {
        final map = {lastKey: 'Old'};

        final result = map.getString(
            key: currentKey, legacyKeys: [lastKey], defaultValue: kDefault);

        expect(result, equals('Old'));
      });

      test('should convert the legacy key value type to string as well', () {
        final map = {lastKey: 2026}; // Legacy is int

        final result = map.getString(
            key: currentKey, legacyKeys: [lastKey], defaultValue: kDefault);

        expect(result, equals('2026'));
      });

      test('should respect the order of the legacy keys list', () {
        final map = {
          veryOldKey: 'Very Old',
          lastKey: 'Old',
        };

        final result = map.getString(
            key: currentKey,
            legacyKeys: [lastKey, veryOldKey],
            defaultValue: kDefault);

        expect(result, equals('Old'));
      });
    });
  });
}
