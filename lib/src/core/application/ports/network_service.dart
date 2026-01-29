import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

/// Application port for network-related data needed by the module.
///
/// Kept as-is for backwards compatibility; consider renaming to
/// `IpAddressProvider` / `NetworkStatusProvider` in a follow-up.
abstract class NetworkService {
  Future<IpAddress> get ipAddress;
}
