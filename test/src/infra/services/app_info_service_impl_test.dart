import 'package:bits_goals_module/src/core/application/exceptions/app_info_service_exception.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/infra/adapters/app_info_service_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppInfoServiceImpl service;
  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    service = AppInfoServiceImpl();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AppInfoServiceImpl', () {
    // Tests are ordered to handle PackageInfo static caching.
    // Platform Error must run BEFORE success tests to avoid caching an object.

    test('should throw AppInfoServiceException when platform call fails',
        () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          throw PlatformException(code: 'ERROR', message: 'Failed');
        },
      );

      // Act & Assert
      expect(
        () => service.version,
        throwsA(isA<AppInfoServiceException>()),
      );
    });

    // Once this runs, PackageInfo will be permanently cached for the isolate.
    test('should return valid AppVersion when platform call succeeds',
        () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{
              'appName': 'Bits Goals',
              'packageName': 'com.example.goals',
              'version': '1.0.0',
              'buildNumber': '1',
              'buildSignature': '',
            };
          }
          return null;
        },
      );

      // Act
      final result = await service.version;

      // Assert
      expect(result, equals(AppVersion('1.0.0')));
      expect(result.major, equals(1));
    });

    test('should return cached version on second call', () async {
      // Arrange
      // Note: PackageInfo is already cached by previous test, so MethodChannel isn't called.
      // But we verify AppInfoServiceImpl logic handles the retrieved value correctly.

      // Act
      await service.version; // First call
      final result = await service.version; // Second call

      // Assert
      expect(result, equals(AppVersion('1.0.0')));
    });
  });
}
