/// Application port for rate limiting execution.
///
/// This is a technical mechanism (not domain). Implementations live in Infra.
abstract class RateLimiterService {
  // TODO: Create implementation

  Future<T> run<T>({
    required String key,
    required Future<T> Function() action,
    Duration windowDuration = const Duration(seconds: 2),
    int maxAttempts = 1,
  });

  bool isQuotaExhausted(String key);

  void reset(String key);

  void dispose();
}

/// Represents an error occurring when the rate limit for a specific key
/// has been exceeded.
class RateLimitExceededException implements Exception {
  final String key;
  final Duration remainingDuration;
  final String message;

  RateLimitExceededException({
    required this.key,
    required this.remainingDuration,
    this.message = 'Rate limit exceeded for this action',
  });

  @override
  String toString() =>
      'RateLimitExceededException(key: $key, wait: ${remainingDuration.inMilliseconds}ms)';
}
