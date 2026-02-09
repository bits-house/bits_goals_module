class RateLimitExceededException implements Exception {
  final Duration remainingDuration;
  final String message;

  const RateLimitExceededException({
    required this.remainingDuration,
    this.message = 'Rate limit exceeded',
  });

  @override
  String toString() =>
      'RateLimitExceededException(wait: ${remainingDuration.inMilliseconds}ms)';
}
