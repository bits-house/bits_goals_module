import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/data/exceptions/rate_limit_exceeded_exception.dart';

void main() {
  test('should store attributes correctly', () {
    const duration = Duration(seconds: 2);
    const customMessage = 'Custom error message';

    const exception = RateLimitExceededException(
      remainingDuration: duration,
      message: customMessage,
    );

    expect(exception.remainingDuration, equals(duration));
    expect(exception.message, equals(customMessage));
  });

  test('toString should return correct string format', () {
    const exception = RateLimitExceededException(
      remainingDuration: Duration(milliseconds: 1500),
    );

    expect(
      exception.toString(),
      equals('RateLimitExceededException(wait: 1500ms)'),
    );
  });
}
