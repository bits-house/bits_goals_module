import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';

/// Application port for app-related info.
abstract class AppInfoService {
  Future<AppVersion> get version;
}
