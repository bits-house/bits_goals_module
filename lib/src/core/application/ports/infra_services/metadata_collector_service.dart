import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

/// Application port for gathering execution/request context for logging.
abstract class MetadataCollectorService {
  Future<AppVersion> get appVersion;
  Future<DeviceInfo> get userDeviceInfo;
  Future<IpAddress> get userIpAddress;
}
