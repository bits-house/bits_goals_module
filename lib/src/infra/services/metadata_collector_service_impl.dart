import 'package:bits_goals_module/src/core/application/ports/infra_services/metadata_collector_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

class MetadataCollectorServiceImpl implements MetadataCollectorService {
  @override
  // TODO: implement appVersion
  AppVersion get appVersion => throw UnimplementedError();

  @override
  // TODO: implement userDeviceInfo
  DeviceInfo get userDeviceInfo => throw UnimplementedError();

  @override
  // TODO: implement userIpAddress
  IpAddress get userIpAddress => throw UnimplementedError();
}
