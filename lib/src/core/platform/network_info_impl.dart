import 'package:bits_goals_module/src/core/platform/network_info.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection _connectionChecker;

  NetworkInfoImpl(this._connectionChecker);

  @override
  Future<bool> get isConnected => _connectionChecker.hasInternetAccess;
}
