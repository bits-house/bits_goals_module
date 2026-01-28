import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

abstract class InfraMetadataCollector {
  AppVersion get appVersion;
  DeviceInfo get userDeviceInfo;
  IpAddress get userIpAddress;
}
