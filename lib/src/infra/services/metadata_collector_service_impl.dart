import 'package:bits_goals_module/src/core/application/ports/infra_services/metadata_collector_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/infra/services/app_info_service_impl.dart';
import 'package:bits_goals_module/src/infra/services/device_service_impl.dart';
import 'package:bits_goals_module/src/infra/services/network_service_impl.dart';

/// Concrete implementation of MetadataCollectorService for
/// gathering execution/request context for logging.
/// Each method must just call the already implemented methods from infra services
/// to retrieve the necessary metadata.
class MetadataCollectorServiceImpl implements MetadataCollectorService {
  final AppInfoServiceImpl appInfoService;
  final DeviceServiceImpl deviceService;
  final NetworkServiceImpl networkService;

  const MetadataCollectorServiceImpl({
    required this.appInfoService,
    required this.deviceService,
    required this.networkService,
  });

  @override
  Future<AppVersion> get appVersion async {
    return await appInfoService.version;
  }

  @override
  Future<DeviceInfo> get userDeviceInfo async {
    return await deviceService.info;
  }

  @override
  Future<IpAddress> get userIpAddress async {
    return await networkService.ipAddress;
  }
}
