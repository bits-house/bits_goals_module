import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

/// Application port for network-related info.
abstract class NetworkInfo {
  Future<bool> get isConnected;

  Future<IpAddress> get ipAddress;
}
