import 'package:bits_goals_module/bits_goals_module_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class PlatformInterfaceExtender extends BitsGoalsModulePlatform {}

void main() {
  group('BitsGoalsModulePlatform Interface', () {
    test('getPlatformVersion throws UnimplementedError when not overridden',
        () async {
      // Arrange
      final platform = PlatformInterfaceExtender();

      // Act & Assert
      expect(
        () async => await platform.getPlatformVersion(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('Can register instance', () {
      BitsGoalsModulePlatform.instance = PlatformInterfaceExtender();
      expect(
          BitsGoalsModulePlatform.instance, isA<PlatformInterfaceExtender>());
    });
  });
}
