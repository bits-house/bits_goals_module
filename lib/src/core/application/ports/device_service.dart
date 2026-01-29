import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';

/// Application port for device-related info.
abstract class DeviceService {
  DeviceInfo get info;
}
