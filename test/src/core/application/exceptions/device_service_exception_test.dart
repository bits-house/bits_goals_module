import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/application/exceptions/device_service_exception.dart';

void main() {
  test('should store attributes correctly', () {
    const customMessage = 'Custom error message';

    const exception = DeviceServiceException(
      customMessage,
    );

    expect(exception.message, equals(customMessage));
  });

  test('toString should return correct string format', () {
    const exception = DeviceServiceException('Device info error');

    expect(
      exception.toString(),
      equals('DeviceServiceException: Device info error'),
    );
  });
}
