import 'package:bits_goals_module/src/infra/utils/platform_checker.dart';
import 'package:bits_goals_module/src/core/application/ports/infra/device_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/application/exceptions/device_service_exception.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Implementation of [DeviceService] using device_info_plus.
/// Must be singleton to cache the device info after the first retrieval.
class DeviceServiceImpl implements DeviceService {
  final DeviceInfoPlugin _deviceInfoPlugin;
  final PlatformChecker _platformChecker;

  DeviceServiceImpl({
    DeviceInfoPlugin? deviceInfoPlugin,
    PlatformChecker? platformChecker,
  })  : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
        _platformChecker = platformChecker ?? PlatformChecker();

  DeviceInfo? _cachedInfo;

  Future<void> _setInfo() async {
    try {
      var infoString = 'Unknown';
      if (_platformChecker.isWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        infoString =
            '${webInfo.browserName} on ${webInfo.platform} (${webInfo.userAgent}). Languages: ${webInfo.languages.toString()}.';
      } else if (_platformChecker.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        infoString =
            '${androidInfo.manufacturer} ${androidInfo.model} on Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}). ${androidInfo.isPhysicalDevice ? "Physical" : "Emulator"}: ${androidInfo.id}. supportedAbis: ${androidInfo.supportedAbis.join(", ")}';
      } else if (_platformChecker.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        infoString =
            '${iosInfo.name} (${iosInfo.model}) on iOS ${iosInfo.systemVersion}. ${iosInfo.isPhysicalDevice ? "Physical" : "Simulator"}: ${iosInfo.identifierForVendor}';
      } else {
        infoString =
            'Unsupported platform: ${_platformChecker.operatingSystem}';
      }
      _cachedInfo = DeviceInfo(infoString);
    } catch (e) {
      throw DeviceServiceException('Failed to parse platform info: $e');
    }
  }

  @override
  Future<DeviceInfo> get info async {
    if (_cachedInfo != null) {
      return _cachedInfo!;
    } else {
      await _setInfo();
      return _cachedInfo!;
    }
  }
}
