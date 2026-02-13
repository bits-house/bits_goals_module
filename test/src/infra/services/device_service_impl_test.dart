import 'package:bits_goals_module/src/infra/adapters/device_service_impl.dart';
import 'package:bits_goals_module/src/infra/utils/platform_checker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

class MockPlatformChecker extends Mock implements PlatformChecker {}

// Mocking return objects
class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}

class MockIosDeviceInfo extends Mock implements IosDeviceInfo {}

class MockWebBrowserInfo extends Mock implements WebBrowserInfo {}

class MockAndroidBuildVersion extends Mock implements AndroidBuildVersion {}

void main() {
  late DeviceServiceImpl deviceService;
  late MockDeviceInfoPlugin mockDeviceInfoPlugin;
  late MockPlatformChecker mockPlatformChecker;

  setUp(() {
    mockDeviceInfoPlugin = MockDeviceInfoPlugin();
    mockPlatformChecker = MockPlatformChecker();

    deviceService = DeviceServiceImpl(
      deviceInfoPlugin: mockDeviceInfoPlugin,
      platformChecker: mockPlatformChecker,
    );
  });

  group('DeviceServiceImpl', () {
    test('should return formatted DeviceInfo for Android', () async {
      // Arrange
      when(() => mockPlatformChecker.isWeb).thenReturn(false);
      when(() => mockPlatformChecker.isAndroid).thenReturn(true);
      when(() => mockPlatformChecker.isIOS).thenReturn(false);

      final mockAndroidInfo = MockAndroidDeviceInfo();
      final mockVersion = MockAndroidBuildVersion();

      when(() => mockVersion.release).thenReturn('12');
      when(() => mockVersion.sdkInt).thenReturn(31);

      when(() => mockAndroidInfo.manufacturer).thenReturn('Google');
      when(() => mockAndroidInfo.model).thenReturn('Pixel 6');
      when(() => mockAndroidInfo.version).thenReturn(mockVersion);
      when(() => mockAndroidInfo.isPhysicalDevice).thenReturn(true);
      when(() => mockAndroidInfo.id).thenReturn('device_id_123');
      when(() => mockAndroidInfo.supportedAbis).thenReturn(['arm64-v8a']);

      when(() => mockDeviceInfoPlugin.androidInfo)
          .thenAnswer((_) async => mockAndroidInfo);

      // Act
      final result = await deviceService.info;

      // Assert
      expect(result.value, contains('Google Pixel 6 on Android 12'));
      expect(result.value, contains('Physical: device_id_123'));
      verify(() => mockDeviceInfoPlugin.androidInfo).called(1);
    });

    test('should return formatted DeviceInfo for iOS', () async {
      // Arrange
      when(() => mockPlatformChecker.isWeb).thenReturn(false);
      when(() => mockPlatformChecker.isAndroid).thenReturn(false);
      when(() => mockPlatformChecker.isIOS).thenReturn(true);

      final mockIosInfo = MockIosDeviceInfo();
      when(() => mockIosInfo.name).thenReturn('iPhone');
      when(() => mockIosInfo.model).thenReturn('iPhone 13');
      when(() => mockIosInfo.systemVersion).thenReturn('15.4');
      when(() => mockIosInfo.isPhysicalDevice).thenReturn(false);
      when(() => mockIosInfo.identifierForVendor).thenReturn('uuid-1234');

      when(() => mockDeviceInfoPlugin.iosInfo)
          .thenAnswer((_) async => mockIosInfo);

      // Act
      final result = await deviceService.info;

      // Assert
      expect(result.value, contains('iPhone (iPhone 13) on iOS 15.4'));
      expect(result.value, contains('Simulator: uuid-1234'));
      verify(() => mockDeviceInfoPlugin.iosInfo).called(1);
    });

    test('should return formatted DeviceInfo for Web', () async {
      // Arrange
      when(() => mockPlatformChecker.isWeb).thenReturn(true);
      // isAndroid/isIOS shouldn't be called if isWeb is true, but just in case
      // when(() => mockPlatformChecker.isAndroid).thenReturn(false);
      // when(() => mockPlatformChecker.isIOS).thenReturn(false);

      final mockWebInfo = MockWebBrowserInfo();
      when(() => mockWebInfo.browserName).thenReturn(BrowserName.chrome);
      when(() => mockWebInfo.platform).thenReturn('MacIntel');
      when(() => mockWebInfo.userAgent).thenReturn('Mozilla/5.0 ...');
      when(() => mockWebInfo.languages).thenReturn(['en-US']);

      when(() => mockDeviceInfoPlugin.webBrowserInfo)
          .thenAnswer((_) async => mockWebInfo);

      // Act
      final result = await deviceService.info;

      // Assert
      expect(result.value, contains('chrome on MacIntel'));
      expect(result.value, contains('en-US'));
      verify(() => mockDeviceInfoPlugin.webBrowserInfo).called(1);
    });

    test('should return unsupported platform message for other platforms',
        () async {
      // Arrange
      when(() => mockPlatformChecker.isWeb).thenReturn(false);
      when(() => mockPlatformChecker.isAndroid).thenReturn(false);
      when(() => mockPlatformChecker.isIOS).thenReturn(false);
      when(() => mockPlatformChecker.operatingSystem).thenReturn('fuchsia');

      // Act
      final result = await deviceService.info;

      // Assert
      expect(result.value, contains('Unsupported platform'));
      expect(result.value, contains('fuchsia'));
    });

    test('should cache the device info result on subsequent calls', () async {
      // Arrange
      when(() => mockPlatformChecker.isWeb).thenReturn(true);
      final mockWebInfo = MockWebBrowserInfo();
      when(() => mockWebInfo.browserName).thenReturn(BrowserName.safari);
      when(() => mockWebInfo.platform).thenReturn('MacIntel');
      when(() => mockWebInfo.userAgent).thenReturn('Safari ...');
      when(() => mockWebInfo.languages).thenReturn(['en']);

      when(() => mockDeviceInfoPlugin.webBrowserInfo)
          .thenAnswer((_) async => mockWebInfo);

      // Act
      final result1 = await deviceService.info;
      final result2 = await deviceService.info;

      // Assert
      expect(result1, equals(result2));
      verify(() => mockDeviceInfoPlugin.webBrowserInfo)
          .called(1); // Only called once
    });

    test('should rethrow Exception when platform info retrieval fails',
        () async {
      // Arrange
      when(() => mockPlatformChecker.isWeb)
          .thenThrow(Exception('Platform check failed'));

      // Act & Assert
      expect(
        () => deviceService.info,
        throwsA(isA<Exception>()),
      );
    });

    test('should use default dependencies when instantiated without arguments',
        () {
      final service = DeviceServiceImpl();
      expect(service, isA<DeviceServiceImpl>());
    });
  });
}
