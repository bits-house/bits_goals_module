import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

class ActionLogMetadataDto {
  final AppVersion appVersion;
  final DeviceInfo userDeviceInfo;
  final IpAddress userIpAddress;

  ActionLogMetadataDto({
    required this.appVersion,
    required this.userDeviceInfo,
    required this.userIpAddress,
  });
}
