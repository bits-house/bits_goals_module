class NetworkServiceException implements Exception {
  final String message;

  const NetworkServiceException(this.message);

  @override
  String toString() => 'NetworkServiceException: $message';
}
