/// Defines the interface for a remote time data source.
/// Implementations interact with remote services to fetch realtime-related data.
abstract class RemoteTimeDataSource {
  /// Fetches the current year from the remote time data source.
  ///
  /// Throws:
  /// - [ServerException] for server errors
  ///
  /// Returns:
  /// - The current year as an integer.
  Future<int> getCurrentYear();
}
