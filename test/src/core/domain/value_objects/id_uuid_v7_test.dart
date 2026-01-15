import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure_reason.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';

void main() {
  group('IdUuidV7', () {
    // UUID V7 (8-4-4-4-12 caracteres hex)
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    test('should support value equality comparison (Equatable)', () {
      const uuidString = '018c2d80-5e3a-7d4d-9c21-1234567890ab';

      final id1 = IdUuidV7.fromString(uuidString);
      final id2 = IdUuidV7.fromString(uuidString);
      final id3 = IdUuidV7.fromString('018c2d80-5e3a-7d4d-9c21-abcdefabcdef');

      // Assert
      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));
      expect(id1, isNot(equals(id3)));
    });

    test('factory .generate() should create a valid UUID v7', () {
      // Act
      final id = IdUuidV7.generate();

      // Assert
      expect(id.value, isNotEmpty);
      expect(uuidRegex.hasMatch(id.value), isTrue,
          reason: "The generated value should follow the standard UUID format");
    });

    test('factory .generate() should generate unique and sortable values (v7)',
        () async {
      // Act
      final id1 = IdUuidV7.generate();
      await Future.delayed(const Duration(milliseconds: 2));
      final id2 = IdUuidV7.generate();

      // Assert
      expect(id1, isNot(equals(id2)));

      // UUID v7 is lexicographically (alphabetically) sortable based on time.
      // id2 (created later) should be "greater" than id1.
      expect(id2.value.compareTo(id1.value), greaterThan(0),
          reason: "UUID v7 should be sequential/sortable by time");
    });

    test('factory .fromString() should store the value correctly', () {
      // Arrange
      const rawValue = '018b1f3c-8c08-7e3f-9b0d-7b2f4c6e8a1d';

      // Act
      final id = IdUuidV7.fromString(rawValue);

      // Assert
      expect(id.value, equals(rawValue));
    });

    test('props should contain the value for Equatable to work', () {
      // Arrange
      const value = 'test-props';
      const id = IdUuidV7(value);

      // Assert
      expect(id.props, contains(value));
    });

    test(
        'should throw [IdUuidV7Failure] with [invalidIdFormat] when given an invalid UUID string',
        () {
      // Arrange
      const invalidUuidString = 'invalid-uuid-format';
      // Act & Assert
      expect(
        () => IdUuidV7.fromString(invalidUuidString),
        throwsA(isA<IdUuidV7Failure>().having(
          (f) => f.reason,
          'reason',
          IdUuidV7FailureReason.invalidIdFormat,
        )),
      );
    });
  });
}
