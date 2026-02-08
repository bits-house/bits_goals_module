import 'dart:async';
import 'dart:collection';

import 'package:bits_goals_module/src/core/application/exceptions/rate_limiter_exception.dart';

import '../../core/application/ports/infra_services/rate_limiter_service.dart';

/// Simple in-memory sliding-window rate limiter.
///
/// - Threading/concurrency: Dart async is single-threaded; attempts are
///   recorded immediately before awaiting the function to avoid races.
///
/// Must be singleton to maintain state across calls.
class RateLimiterServiceImpl implements RateLimiterService {
  final Map<String, _RateLimitEntry> _store = {};

  @override
  Future<T> run<T>({
    required String functionId,
    required Future<T> Function() function,
    Duration windowDuration = const Duration(seconds: 2),
    int maxAttempts = 1,
  }) async {
    final now = DateTime.now();
    // Get or create the rate limit entry for the functionId
    final entry = _store.putIfAbsent(functionId, () => _RateLimitEntry());

    // Purge old attempts outside the window
    entry._removeOld(now, windowDuration);

    if (entry.timestamps.length >= maxAttempts) {
      // Rate limit exceeded; calculate wait time
      final oldest = entry.timestamps.first;
      final waitUntil = oldest.add(windowDuration);
      final remaining = waitUntil.difference(now);
      throw RateLimiterException(
        functionId: functionId,
        remainingDuration: remaining.isNegative ? Duration.zero : remaining,
      );
    }

    // Record attempt immediately (prevents races between concurrent calls)
    entry.timestamps.addLast(now);

    try {
      final result = await function();
      return result;
    } finally {
      // Clean up expired timestamps and remove empty entries to free memory
      entry._removeOld(DateTime.now(), windowDuration);
      if (entry.timestamps.isEmpty) {
        _store.remove(functionId);
      }
    }
  }
}

class _RateLimitEntry {
  // Timestamps of recent attempts within the window
  final Queue<DateTime> timestamps = Queue<DateTime>();

  // Remove timestamps older than the sliding window
  void _removeOld(DateTime now, Duration window) {
    while (
        timestamps.isNotEmpty && now.difference(timestamps.first) >= window) {
      timestamps.removeFirst();
    }
  }
}
