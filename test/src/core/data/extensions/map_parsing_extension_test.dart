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

      test(
          'should throw [FormatException] if the key does not exist and no defaultValue',
          () {
        final map = {'nothing_related': 0};

        expect(
          () => map.getInt(key: currentKey, legacyKeys: [lastKey]),
          throwsA(isA<FormatException>()),
        );
      });

      test(
          'should throw [FormatException] when no main key, legacy keys, or defaultValue',
          () {
        final map = {'unrelated': 123};

        expect(
          () => map.getInt(key: currentKey),
          throwsA(isA<FormatException>()),
        );
      });

      test(
          'should throw [FormatException] when all legacy keys are invalid and no defaultValue',
          () {
        final map = {
          lastKey: 'not_parseable',
          veryOldKey: 'also_not_parseable',
        };

        expect(
          () => map.getInt(
            key: currentKey,
            legacyKeys: [lastKey, veryOldKey],
          ),
          throwsA(isA<FormatException>()),
        );
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

      test(
          'should throw [FormatException] when no main key, legacy keys, or defaultValue',
          () {
        final map = {'unrelated': 'something'};

        expect(
          () => map.getString(key: currentKey),
          throwsA(isA<FormatException>()),
        );
      });

      test(
          'should throw [FormatException] when all legacy keys missing and no defaultValue',
          () {
        final map = {'unrelated': 'something'};

        expect(
          () => map.getString(
            key: currentKey,
            legacyKeys: [lastKey, veryOldKey],
          ),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // =========================================================================
    // TESTS: getFirestoreTimestamp
    // =========================================================================
    group('getFirestoreTimestamp', () {
      const currentKey = 'occurred_at';
      const lastKey = 'created_at';
      const veryOldKey = 'timestamp_v1';
      const kDefaultTimestamp = null;

      test('should return exact int value when key exists and is int', () {
        final map = {currentKey: 1234567890};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890));
      });

      test('should convert double to int (truncating) when value is double',
          () {
        // Firestore may return doubles for numbers
        final map = {currentKey: 1234567890.9};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890)); // .toInt() removes decimal
      });

      test('should parse numeric double String', () {
        final map = {currentKey: '1234567890.5'};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890));
      });

      test('should parse numeric int String', () {
        final map = {currentKey: '1234567890'};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890));
      });

      test('should return null when String is not numeric', () {
        final map = {currentKey: 'not_a_number'};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, isNull);
      });

      test('should return null when value is null', () {
        final map = {currentKey: null};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, isNull);
      });

      test('should return defaultValue when key does not exist', () {
        final map = {'unrelated_key': 1234567890};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: 999,
        );

        expect(result, equals(999));
      });

      test(
          'should convert Firestore Timestamp {_seconds, _nanoseconds} to milliseconds',
          () {
        // Firestore Timestamp format: seconds + nanoseconds
        // 1234567890 seconds = 1234567890000 milliseconds
        final map = {
          currentKey: {
            '_seconds': 1234567890,
            '_nanoseconds': 123456789,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        // 1234567890 seconds * 1000 = 1234567890000 ms
        expect(result, equals(1234567890000));
      });

      test(
          'should convert Firestore Timestamp with double seconds to milliseconds',
          () {
        final map = {
          currentKey: {
            '_seconds': 1234567890.5,
            '_nanoseconds': 123456789,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        // 1234567890.5.toInt() = 1234567890, then * 1000 = 1234567890000 ms
        expect(result, equals(1234567890000));
      });

      test('should handle Firestore Timestamp with zero nanoseconds', () {
        final map = {
          currentKey: {
            '_seconds': 1234567890,
            '_nanoseconds': 0,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890000));
      });

      test(
          'should return null for invalid Firestore Timestamp (missing _seconds)',
          () {
        final map = {
          currentKey: {
            // '_seconds' is missing
            '_nanoseconds': 123456789,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, isNull);
      });

      test(
          'should return null for invalid Firestore Timestamp (missing _nanoseconds)',
          () {
        final map = {
          currentKey: {
            '_seconds': 1234567890,
            // '_nanoseconds' is missing
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, isNull);
      });

      test(
          'should extract millisecondsSinceEpoch property from Map-like object',
          () {
        final map = {
          currentKey: {
            'millisecondsSinceEpoch': 1234567890,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890));
      });

      test('should convert millisecondsSinceEpoch double property to int', () {
        final map = {
          currentKey: {
            'millisecondsSinceEpoch': 1234567890.9,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890));
      });

      test(
          'should prioritize _seconds/_nanoseconds over millisecondsSinceEpoch',
          () {
        // When both formats exist, Firestore format should win
        final map = {
          currentKey: {
            '_seconds': 1000000,
            '_nanoseconds': 0,
            'millisecondsSinceEpoch': 999999999,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1000000000)); // From _seconds format
      });

      // --- LEGACY KEYS ---

      test('should prioritize main key over legacy keys', () {
        final map = {
          veryOldKey: 111111,
          lastKey: 222222,
          currentKey: 333333, // Should win
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey, veryOldKey],
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(333333));
      });

      test('should use first legacy key if main key is missing', () {
        final map = {
          // currentKey is missing
          lastKey: 222222, // Should win
          veryOldKey: 111111,
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey, veryOldKey],
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(222222));
      });

      test('should respect order of legacy keys list', () {
        final map = {
          veryOldKey: 111111, // Present but second in list
          lastKey: 222222, // Present and first in list
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey, veryOldKey],
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(222222));
      });

      test(
          'should skip invalid legacy key and try next (with Firestore format)',
          () {
        final map = {
          lastKey: {'_seconds': 'invalid'}, // Invalid Firestore format
          veryOldKey: 111111, // Valid direct int
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey, veryOldKey],
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(111111));
      });

      test('should skip non-numeric legacy key and try next', () {
        final map = {
          lastKey: 'not_a_number',
          veryOldKey: 333333,
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey, veryOldKey],
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(333333));
      });

      test('should return defaultValue when neither main nor legacy exist', () {
        final map = {'unrelated': 999};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey, veryOldKey],
          defaultValue: 777,
        );

        expect(result, equals(777));
      });

      test('should return null when no defaultValue provided and key missing',
          () {
        final map = {'unrelated': 999};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [],
          // No defaultValue
        );

        expect(result, isNull);
      });

      // --- EDGE CASES ---

      test('should handle very large timestamp (far future)', () {
        const largeTimestamp = 9999999999999;
        final map = {currentKey: largeTimestamp};

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(largeTimestamp));
      });

      test('should handle Firestore Timestamp with large seconds', () {
        const largeSeconds = 9999999999;
        final map = {
          currentKey: {
            '_seconds': largeSeconds,
            '_nanoseconds': 999999999,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(largeSeconds * 1000));
      });

      test('should handle millisecondsSinceEpoch at epoch (zero)', () {
        final map = {
          currentKey: {
            'millisecondsSinceEpoch': 0,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(0));
      });

      test('should handle _seconds at zero (epoch)', () {
        final map = {
          currentKey: {
            '_seconds': 0,
            '_nanoseconds': 0,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(0));
      });

      test('should handle empty Map for Firestore Timestamp format', () {
        final map = {
          currentKey: {}, // Empty, no _seconds or nanoseconds
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: 999,
        );

        expect(result, equals(999));
      });

      test('should handle Map with null values for Firestore Timestamp', () {
        final map = {
          currentKey: {
            '_seconds': null,
            '_nanoseconds': null,
          }
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          defaultValue: 777,
        );

        expect(result, equals(777));
      });

      test('should handle numeric string from Firestore Timestamp legacy key',
          () {
        final map = {
          lastKey: '1234567890',
          currentKey: null,
        };

        final result = map.getFirestoreTimestamp(
          key: currentKey,
          legacyKeys: [lastKey],
          defaultValue: kDefaultTimestamp,
        );

        expect(result, equals(1234567890));
      });
    });
  });
}
