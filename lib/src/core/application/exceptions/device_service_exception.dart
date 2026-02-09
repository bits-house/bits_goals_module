class DeviceServiceException implements Exception {
  final String message;

  const DeviceServiceException(this.message);

  @override
  String toString() => 'DeviceServiceException: $message';
}
