import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/application/exceptions/network_service_exception.dart';

void main() {
  test('should store attributes correctly', () {
    const customMessage = 'Custom error message';

    const exception = NetworkServiceException(
      customMessage,
    );

    expect(exception.message, equals(customMessage));
  });

  test('toString should return correct string format', () {
    const exception = NetworkServiceException('Socket error');

    expect(
      exception.toString(),
      equals('NetworkServiceException: Socket error'),
    );
  });
}
