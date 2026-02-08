class AppInfoServiceException implements Exception {
  final String message;

  const AppInfoServiceException(this.message);

  @override
  String toString() => 'AppInfoServiceException: $message';
}
