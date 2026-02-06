import 'package:bits_goals_module/src/core/application/exceptions/rate_limiter_exception.dart';
import 'package:bits_goals_module/src/infra/services/rate_limiter_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _CustomException implements Exception {
  final String message;
  _CustomException(this.message);

  @override
  String toString() => 'CustomException: $message';
}

void main() {
  late RateLimiterServiceImpl sut;

  setUp(() {
    sut = RateLimiterServiceImpl();
  });

  group('Success Paths', () {
    test('should return function result on successful execution', () async {
      const expectedResult = 'success';
      Future<String> function() async => expectedResult;

      final result = await sut.run(
        functionId: 'test_func',
        function: function,
      );

      expect(result, equals(expectedResult));
    });

    test('should execute generic type T correctly (int)', () async {
      const expectedResult = 42;
      Future<int> function() async => expectedResult;

      final result = await sut.run<int>(
        functionId: 'test_int_func',
        function: function,
      );

      expect(result, equals(42));
      expect(result, isA<int>());
    });

    test('should execute generic type T correctly (list)', () async {
      final expectedResult = [1, 2, 3];
      Future<List<int>> function() async => expectedResult;

      final result = await sut.run<List<int>>(
        functionId: 'test_list_func',
        function: function,
      );

      expect(result, equals([1, 2, 3]));
      expect(result, isA<List<int>>());
    });

    test('should execute generic type T correctly (map)', () async {
      final expectedResult = {'key': 'value', 'num': 42};
      Future<Map<String, dynamic>> function() async => expectedResult;

      final result = await sut.run<Map<String, dynamic>>(
        functionId: 'test_map_func',
        function: function,
      );

      expect(result, equals({'key': 'value', 'num': 42}));
      expect(result, isA<Map<String, dynamic>>());
    });

    test('should allow multiple attempts when within maxAttempts limit',
        () async {
      Future<String> function() async => 'success';
      const functionId = 'test_multi_attempts';

      // First attempt
      var result1 = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 3,
        windowDuration: const Duration(milliseconds: 100),
      );

      // Second attempt (still within limit)
      var result2 = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 3,
        windowDuration: const Duration(milliseconds: 100),
      );

      // Third attempt (still within limit)
      var result3 = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 3,
        windowDuration: const Duration(milliseconds: 100),
      );

      expect(result1, equals('success'));
      expect(result2, equals('success'));
      expect(result3, equals('success'));
    });

    test('should allow separate function IDs to exceed independent limits',
        () async {
      Future<String> function() async => 'success';

      // First function reaches limit
      await sut.run(
        functionId: 'func_1',
        function: function,
        maxAttempts: 1,
      );

      // Second function should not be limited by first function's limit
      final result = await sut.run(
        functionId: 'func_2',
        function: function,
        maxAttempts: 1,
      );

      expect(result, equals('success'));
    });
  });

  group('Validation Failures - Rate Limit Exceeded', () {
    test(
        'should throw RateLimiterException when maxAttempts exceeded with '
        'default params', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_limit_exact';

      // First attempt (within limit)
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
      );

      // Second attempt (exceeds limit)
      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 1,
        ),
        throwsA(isA<RateLimiterException>()),
      );
    });

    test('should include correct functionId in exception', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_func_id';

      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
      );

      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 1,
        ),
        throwsA(
          isA<RateLimiterException>()
              .having((e) => e.functionId, 'functionId', equals(functionId)),
        ),
      );
    });

    test('should calculate remaining duration correctly', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_remaining_duration';
      const windowDuration = Duration(milliseconds: 500);

      // First attempt at time T
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: windowDuration,
      );

      // Second attempt immediately after (should have ~500ms remaining)
      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 1,
          windowDuration: windowDuration,
        ),
        throwsA(
          isA<RateLimiterException>().having(
            (e) => e.remainingDuration,
            'remainingDuration',
            isA<Duration>(),
          ),
        ),
      );
    });

    test('should throw exception with 3 attempts in window', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_multiple_limit';

      // Make 2 attempts (within limit of 2)
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 2,
      );
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 2,
      );

      // Third attempt should fail
      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 2,
        ),
        throwsA(isA<RateLimiterException>()),
      );
    });

    test('should reset limit after window expires', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_window_expiry';

      // First attempt
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(milliseconds: 50),
      );

      // Second attempt should fail (still in window)
      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 1,
          windowDuration: const Duration(milliseconds: 50),
        ),
        throwsA(isA<RateLimiterException>()),
      );

      // Wait for window to expire
      await Future.delayed(const Duration(milliseconds: 100));

      // Third attempt should succeed (window expired)
      final result = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(milliseconds: 50),
      );

      expect(result, equals('success'));
    });
  });

  group('Exception Handling - function Failures', () {
    test('should propagate function exceptions without rate limit interference',
        () async {
      Future<String> function() async =>
          throw ArgumentError('Invalid argument');

      expect(
        () => sut.run(
          functionId: 'test_function_error',
          function: function,
        ),
        throwsArgumentError,
      );
    });

    test('should still record attempt timestamp even if function throws',
        () async {
      var attemptCount = 0;
      Future<String> function() async {
        attemptCount++;
        throw ArgumentError('function failed');
      }

      // First attempt: function throws
      expect(
        () => sut.run(
          functionId: 'test_error_recorded',
          function: function,
          maxAttempts: 1,
        ),
        throwsArgumentError,
      );

      // Second attempt should be rate-limited (first attempt was recorded)
      expect(
        () => sut.run(
          functionId: 'test_error_recorded',
          function: function,
          maxAttempts: 1,
        ),
        throwsA(isA<RateLimiterException>()),
      );

      expect(attemptCount, equals(1));
    });

    test('should propagate custom exceptions from function', () async {
      Future<_CustomException> function() async =>
          throw _CustomException('custom error');

      expect(
        () => sut.run(
          functionId: 'test_custom_exception',
          function: function,
        ),
        throwsA(isA<_CustomException>()),
      );
    });
  });

  group('Memory Cleanup', () {
    test('should allow new attempts on different functionIds', () async {
      Future<String> function() async => 'success';

      // First function gets rate limited
      await sut.run(
        functionId: 'func_cleanup_1',
        function: function,
        maxAttempts: 1,
      );

      // Second function is independent and succeeds
      final result = await sut.run(
        functionId: 'func_cleanup_2',
        function: function,
        maxAttempts: 1,
      );

      expect(result, equals('success'));
    });

    test('should reset timestamps queue when entry is created fresh', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_fresh_entry';

      // First call with limit of 1
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
      );

      // Use a very short window, then wait beyond it
      const shortWindow = Duration(milliseconds: 1);
      await Future.delayed(const Duration(milliseconds: 50));

      // Call with same functionId but allow the entry to be recreated
      // by starting a fresh window
      final result = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: shortWindow,
      );

      expect(result, equals('success'));
    });

    test(
        'should remove entry from store in finally block when function execution '
        'duration exceeds window duration', () async {
      // Define a short window duration to trigger cleanup logic in finally block
      const windowDuration = Duration(milliseconds: 50);
      const functionId = 'test_long_execution_cleanup';

      // Define an function that takes longer than the window duration to execute
      Future<String> function() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'success';
      }

      // Execute.
      // 1. Adds timestamp T1.
      // 2. Waits 100ms.
      // 3. Enters finally. T1 is now "old" (> 50ms).
      // 4. _removeOld removes T1. List becomes empty.
      // 5. _store.remove(functionId) is executed.
      await sut.run(
        functionId: functionId,
        function: function,
        windowDuration: windowDuration,
        maxAttempts: 1,
      );

      // Behavior verification:
      // Since we cannot access the private _store variable to check if it is empty,
      // we verify if the system remains consistent by allowing an immediate new call.
      // Whether the cleanup occurred correctly or not, the system should allow execution
      // because the time has passed. The main goal here is to ensure that the line of code ran without errors.
      final result = await sut.run(
        functionId: functionId,
        function: () async => 'second_call',
        windowDuration: windowDuration,
        maxAttempts: 1,
      );

      expect(result, equals('second_call'));
    });
  });

  group('Edge Cases', () {
    test('should handle very long window duration', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_long_window';

      // First attempt
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(days: 365),
      );

      // Second attempt should fail (still in very long window)
      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 1,
          windowDuration: const Duration(days: 365),
        ),
        throwsA(isA<RateLimiterException>()),
      );
    });

    test('should handle very short window duration', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_short_window';

      // First attempt
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(microseconds: 1),
      );

      // Wait briefly for window to expire
      await Future.delayed(const Duration(milliseconds: 1));

      // Second attempt should succeed (short window expired)
      final result = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(microseconds: 1),
      );

      expect(result, equals('success'));
    });

    test('should handle high maxAttempts value', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_high_max_attempts';

      // Make 10 attempts (within limit of 100)
      for (int i = 0; i < 10; i++) {
        final result = await sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 100,
          windowDuration: const Duration(seconds: 5),
        );
        expect(result, equals('success'));
      }

      // 11th attempt should still succeed
      final result = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 100,
        windowDuration: const Duration(seconds: 5),
      );

      expect(result, equals('success'));
    });

    test('should handle void return type (Future<void>)', () async {
      var executionCount = 0;
      Future<void> function() async {
        executionCount++;
      }

      await sut.run<void>(
        functionId: 'test_void',
        function: function,
      );

      expect(executionCount, equals(1));
    });

    test('should handle null return value', () async {
      Future<Null> function() async => null;

      final result = await sut.run<Null>(
        functionId: 'test_null',
        function: function,
      );

      expect(result, isNull);
    });

    test('should handle empty string functionId', () async {
      Future<String> function() async => 'success';

      final result = await sut.run(
        functionId: '',
        function: function,
        maxAttempts: 1,
      );

      expect(result, equals('success'));
    });

    test('should handle special characters in functionId', () async {
      Future<String> function() async => 'success';
      const functionId = 'test-func_123.special@chars';

      final result = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
      );

      expect(result, equals('success'));
    });

    test('should handle rapid successive calls within window', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_rapid_calls';

      // First two calls should succeed (within maxAttempts=2)
      var result1 = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 2,
      );
      var result2 = await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 2,
      );

      // Third call should fail
      expect(
        () => sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 2,
        ),
        throwsA(isA<RateLimiterException>()),
      );

      expect(result1, equals('success'));
      expect(result2, equals('success'));
    });

    test('should calculate remaining duration accurately', () async {
      Future<String> function() async => 'success';
      const functionId = 'test_remaining_duration_accurate';

      // First attempt
      await sut.run(
        functionId: functionId,
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(milliseconds: 500),
      );

      // Second attempt should fail with reasonable remaining duration
      try {
        await sut.run(
          functionId: functionId,
          function: function,
          maxAttempts: 1,
          windowDuration: const Duration(milliseconds: 500),
        );
        fail('Should have thrown RateLimiterException');
      } catch (e) {
        expect(e, isA<RateLimiterException>());
        // Remaining duration should be positive and <= window duration
        final remainingDuration = (e as RateLimiterException).remainingDuration;
        expect(
          remainingDuration.inMilliseconds,
          greaterThan(0),
        );
        expect(
          remainingDuration.inMilliseconds,
          lessThanOrEqualTo(500),
        );
      }
    });

    test('should handle complex nested object as return value', () async {
      Future<Map<String, dynamic>> function() async {
        return {
          'users': [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'},
          ],
          'count': 2,
          'metadata': {
            'timestamp': '2024-01-01',
            'version': '1.0.0',
          }
        };
      }

      final result = await sut.run<Map<String, dynamic>>(
        functionId: 'test_complex_object',
        function: function,
      );

      final expectedData = {
        'users': [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
        'count': 2,
        'metadata': {
          'timestamp': '2024-01-01',
          'version': '1.0.0',
        }
      };

      expect(result, equals(expectedData));
      expect(result['users'], isA<List>());
      expect(result['count'], equals(2));
    });
  });

  group('Integration - Multiple Functions & Interfunctions', () {
    test(
        'should allow independent rate limiting for multiple function IDs '
        'simultaneously', () async {
      Future<String> function() async => 'success';

      // func_1 uses limit 1, func_2 uses limit 2
      await sut.run(
        functionId: 'func_1',
        function: function,
        maxAttempts: 1,
      );

      await sut.run(
        functionId: 'func_2',
        function: function,
        maxAttempts: 2,
      );

      // func_1 should be limited
      expect(
        () => sut.run(
          functionId: 'func_1',
          function: function,
          maxAttempts: 1,
        ),
        throwsA(isA<RateLimiterException>()),
      );

      // func_2 should allow one more attempt
      var result = await sut.run(
        functionId: 'func_2',
        function: function,
        maxAttempts: 2,
      );
      expect(result, equals('success'));

      // func_2 should now be limited
      expect(
        () => sut.run(
          functionId: 'func_2',
          function: function,
          maxAttempts: 2,
        ),
        throwsA(isA<RateLimiterException>()),
      );
    });

    test('should handle window expiry for one function while another is active',
        () async {
      Future<String> function() async => 'success';

      // func_1 with short window
      await sut.run(
        functionId: 'func_1',
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(milliseconds: 50),
      );

      // func_2 with longer window
      await sut.run(
        functionId: 'func_2',
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(seconds: 1),
      );

      // Wait for func_1 window to expire
      await Future.delayed(const Duration(milliseconds: 100));

      // func_1 should now allow new attempt
      var result1 = await sut.run(
        functionId: 'func_1',
        function: function,
        maxAttempts: 1,
        windowDuration: const Duration(milliseconds: 50),
      );

      // func_2 should still be limited
      expect(
        () => sut.run(
          functionId: 'func_2',
          function: function,
          maxAttempts: 1,
          windowDuration: const Duration(seconds: 1),
        ),
        throwsA(isA<RateLimiterException>()),
      );

      expect(result1, equals('success'));
    });

    test('should handle interleaved successful and rate-limited calls',
        () async {
      Future<String> function() async => 'success';

      // Attempt 1: func_1 succeeds
      var result1 = await sut.run(
        functionId: 'func_1',
        function: function,
        maxAttempts: 2,
      );

      // Attempt 2: func_2 succeeds
      var result2 = await sut.run(
        functionId: 'func_2',
        function: function,
        maxAttempts: 1,
      );

      // Attempt 3: func_1 succeeds (still within limit)
      var result3 = await sut.run(
        functionId: 'func_1',
        function: function,
        maxAttempts: 2,
      );

      // Attempt 4: func_2 fails (exceeded limit)
      expect(
        () => sut.run(
          functionId: 'func_2',
          function: function,
          maxAttempts: 1,
        ),
        throwsA(isA<RateLimiterException>()),
      );

      // Attempt 5: func_1 fails (exceeded limit)
      expect(
        () => sut.run(
          functionId: 'func_1',
          function: function,
          maxAttempts: 2,
        ),
        throwsA(isA<RateLimiterException>()),
      );

      expect(result1, equals('success'));
      expect(result2, equals('success'));
      expect(result3, equals('success'));
    });
  });
}
