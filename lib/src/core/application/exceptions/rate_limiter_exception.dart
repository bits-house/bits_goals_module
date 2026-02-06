class RateLimiterException implements Exception {
  final String functionId;
  final Duration remainingDuration;
  final String message;

  RateLimiterException({
    required this.functionId,
    required this.remainingDuration,
    this.message = 'Rate limit exceeded for this action',
  });

  @override
  String toString() =>
      'RateLimiterException(functionId: $functionId, wait: ${remainingDuration.inMilliseconds}ms)';
}
