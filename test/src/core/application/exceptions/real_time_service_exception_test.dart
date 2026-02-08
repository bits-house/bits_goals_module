import 'package:flutter_test/flutter_test.dart';
// Ajuste o import conforme o caminho real do arquivo
import 'package:bits_goals_module/src/core/application/exceptions/real_time_service_exception.dart';

void main() {
  test('should store message correctly', () {
    const message = 'Connection lost';
    const exception = RealTimeServiceException(message);

    expect(exception.message, equals(message));
  });

  test('toString should return correct string format', () {
    const exception = RealTimeServiceException('Socket error');

    expect(
      exception.toString(),
      equals('RealTimeServiceException: Socket error'),
    );
  });
}
