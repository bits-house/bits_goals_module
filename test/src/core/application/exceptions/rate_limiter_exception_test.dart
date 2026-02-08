import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/application/exceptions/rate_limiter_exception.dart';

void main() {
  test('should store attributes correctly', () {
    const functionId = 'test_func_id';
    const duration = Duration(seconds: 2);
    const customMessage = 'Custom error message';

    const exception = RateLimiterException(
      functionId: functionId,
      remainingDuration: duration,
      message: customMessage,
    );

    expect(exception.functionId, equals(functionId));
    expect(exception.remainingDuration, equals(duration));
    expect(exception.message, equals(customMessage));
  });

  test('toString should return correct string format', () {
    const exception = RateLimiterException(
      functionId: 'my_function',
      remainingDuration: Duration(milliseconds: 1500),
    );

    expect(
      exception.toString(),
      equals('RateLimiterException(functionId: my_function, wait: 1500ms)'),
    );
  });
}
