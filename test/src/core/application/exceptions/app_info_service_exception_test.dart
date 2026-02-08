import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/application/exceptions/app_info_service_exception.dart';

void main() {
  test('should store attributes correctly', () {
    const customMessage = 'Custom error message';

    const exception = AppInfoServiceException(
      customMessage,
    );

    expect(exception.message, equals(customMessage));
  });

  test('toString should return correct string format', () {
    const exception = AppInfoServiceException('Version retrieval failed');

    expect(
      exception.toString(),
      equals('AppInfoServiceException: Version retrieval failed'),
    );
  });
}
