import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';

abstract class NetworkService {
  Future<IpAddress> get ipAddress;
}
