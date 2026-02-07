class RealTimeServiceException implements Exception {
  final String message;

  RealTimeServiceException(this.message);

  @override
  String toString() => 'RealTimeServiceException: $message';
}
