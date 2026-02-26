import 'package:bits_goals_module/src/core/application/ports/app_info_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Implementation of [AppInfoService] using package_info_plus.
/// Must be singleton to cache the version info after the first retrieval.
class AppInfoServiceImpl implements AppInfoService {
  AppVersion? _cachedVersion;

  Future<void> _setVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _cachedVersion = AppVersion(packageInfo.version);
  }

  @override
  Future<AppVersion> get version async {
    try {
      if (_cachedVersion != null) {
        return _cachedVersion!;
      } else {
        await _setVersion();
        return _cachedVersion!;
      }
    } catch (e) {
      throw Exception('Error retrieving app version: $e');
    }
  }
}
