import 'package:bits_goals_module/src/core/application/ports/infra/action_log_metadata_provider.dart';
import 'package:bits_goals_module/src/core/application/dtos/action_log_metadata_dto.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:bits_goals_module/src/infra/adapters/app_info_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/device_service_impl.dart';
import 'package:bits_goals_module/src/infra/adapters/network_service_impl.dart';

/// Concrete implementation of MetadataCollectorService for
/// gathering execution/request context for logging.
/// Each method must just call the already implemented methods from infra services
/// to retrieve the necessary metadata.
class ActionLogMetadataProviderImpl implements ActionLogMetadataProvider {
  final AppInfoServiceImpl appInfoService;
  final DeviceServiceImpl deviceService;
  final NetworkServiceImpl networkService;

  const ActionLogMetadataProviderImpl({
    required this.appInfoService,
    required this.deviceService,
    required this.networkService,
  });

  @override
  Future<ActionLogMetadataDto> get metadata async {
    final [
      appVersion as AppVersion,
      deviceInfo as DeviceInfo,
      ipAddress as IpAddress,
    ] = await Future.wait([
      appInfoService.version,
      deviceService.info,
      networkService.ipAddress,
    ]);

    return ActionLogMetadataDto(
      appVersion: appVersion,
      userDeviceInfo: deviceInfo,
      userIpAddress: ipAddress,
    );
  }
}
