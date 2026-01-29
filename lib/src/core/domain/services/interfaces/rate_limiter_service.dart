/// Interface for a mechanism that enforces a rate limit on actions.
///
/// **Pattern:** "Token Bucket / Rate Limiting".
/// Allows a burst of [maxAttempts] executions within a [windowDuration].
/// Once the quota is exhausted, subsequent calls are rejected until the
/// window resets.
abstract class RateLimiterService {
  /// Executes the [action] immediately if the [key] has quota remaining.
  ///
  /// If quota is exhausted (attempts >= maxAttempts):
  /// - Throws [RateLimitExceededException].
  /// - Does NOT execute [action].
  ///
  /// [key]: Unique identifier for the action scope (e.g. 'checkout_btn').
  /// [windowDuration]: The lifespan of the rate limit window (starts on first call).
  /// [maxAttempts]: How many times execution is allowed inside the window.
  Future<T> run<T>({
    required String key,
    required Future<T> Function() action,
    Duration windowDuration = const Duration(seconds: 2),
    int maxAttempts = 1,
  });

  /// Checks if the quota for a specific [key] is currently exhausted.
  ///
  /// Useful for UI states (e.g. disabling a button visually).
  bool isQuotaExhausted(String key);

  /// Manually resets the quota for a specific [key].
  ///
  /// Use this to allow immediate retry after a business logic failure.
  void reset(String key);

  /// Clears all active limiters and releases memory.
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
