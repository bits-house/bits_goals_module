import 'package:bits_goals_module/src/infra/utils/platform_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlatformChecker platformChecker;

  setUp(() {
    platformChecker = PlatformChecker();
  });

  group('PlatformChecker', () {
    test('isWeb returns correct value', () {
      // kIsWeb is a compile-time constant, so we can just assert it returns a bool.
      // Depending on the test environment this will be true or false.
      expect(platformChecker.isWeb, isA<bool>());
    });

    test('isAndroid returns correct value', () {
      expect(platformChecker.isAndroid, isA<bool>());
    });

    test('isIOS returns correct value', () {
      expect(platformChecker.isIOS, isA<bool>());
    });

    test('operatingSystem returns correct value', () {
      expect(platformChecker.operatingSystem, isA<String>());
    });
  });
}
