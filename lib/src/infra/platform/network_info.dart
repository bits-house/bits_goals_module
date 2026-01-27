/// Defines the NetworkInfo interface for checking network connectivity.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}
