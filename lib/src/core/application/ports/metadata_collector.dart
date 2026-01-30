import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

/// Application port for gathering execution/request context for logging.
abstract class MetadataCollector {
  // TODO: Create implementation
  AppVersion get appVersion;
  DeviceInfo get userDeviceInfo;
  IpAddress get userIpAddress;
}
