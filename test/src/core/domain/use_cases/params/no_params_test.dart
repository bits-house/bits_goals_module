import 'package:bits_goals_module/src/core/domain/use_cases/params/no_params.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equatable/equatable.dart';

void main() {
  group('NoParams', () {
    test('should be a subclass of Equatable', () {
      expect(NoParams(), isA<Equatable>());
    });

    test('should support value equality (two instances should be equal)', () {
      // Arrange & Act
      final instance1 = NoParams();
      final instance2 = NoParams();

      // Assert
      expect(instance1, equals(instance2));
    });

    test('props should be empty', () {
      // Arrange
      final instance = NoParams();

      // Assert
      expect(instance.props, isEmpty);
    });
  });
}
