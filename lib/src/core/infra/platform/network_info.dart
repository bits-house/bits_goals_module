/// Defines the NetworkInfo interface for checking network connectivity.
abstract class NetworkInfo {
  /// CAUTION: DO NOT USE OUTSIDE OF DATA LAYER!
  Future<bool> get isConnected;
}
