import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

/// Application port for network-related operations.
abstract class NetworkService {
  Future<bool> get isConnected;

  Future<IpAddress> get ipAddress;
}
