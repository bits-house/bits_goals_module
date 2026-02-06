/// Application port for rate limiting execution.
///
/// This is a technical mechanism (not domain). Implementations live in Infra.
abstract class RateLimiterService {
  Future<T> run<T>({
    required String functionId,
    required Future<T> Function() function,
    Duration windowDuration = const Duration(seconds: 2),
    int maxAttempts = 1,
  });
}
