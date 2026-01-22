import 'package:bits_goals_module/src/core/domain/value_objects/device_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/domain/failures/device_info/device_info_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/device_info/device_info_failure_reason.dart';

void main() {
  group('DeviceInfo Value Object Tests', () {
    group('Instantiation & Validation', () {
      test('should create a valid DeviceInfo when string is provided', () {
        const rawInfo = 'Google Pixel 6 - Android 13';
        final deviceInfo = DeviceInfo(rawInfo);

        expect(deviceInfo.value, rawInfo);
      });

      test('should trim leading and trailing whitespaces', () {
        const rawInfo = '   iPhone 15 Pro   ';
        final deviceInfo = DeviceInfo(rawInfo);

        expect(deviceInfo.value, 'iPhone 15 Pro');
      });

      test('should throw DeviceInfoFailure when string is empty', () {
        expect(
          () => DeviceInfo(''),
          throwsA(
            isA<DeviceInfoFailure>().having(
              (f) => f.reason,
              'reason',
              DeviceInfoFailureReason.emptyOrInvalid,
            ),
          ),
        );
      });

      test(
          'should throw DeviceInfoFailure when string contains only whitespaces',
          () {
        expect(
          () => DeviceInfo('     '),
          throwsA(isA<DeviceInfoFailure>()),
        );
      });

      test(
          'should throw DeviceInfoFailure when string contains only tabs or newlines',
          () {
        expect(
          () => DeviceInfo('\n\t'),
          throwsA(isA<DeviceInfoFailure>()),
        );
      });
    });

    group('Equality & Value Comparison', () {
      test('two instances with same value should be equal (Equatable)', () {
        final info1 = DeviceInfo('MacBook Pro M2');
        final info2 = DeviceInfo('MacBook Pro M2');

        expect(info1, equals(info2));
      });

      test('two instances with different values should not be equal', () {
        final info1 = DeviceInfo('Device A');
        final info2 = DeviceInfo('Device B');

        expect(info1, isNot(equals(info2)));
      });

      test(
          'equality should be true for same content even if original inputs had different spacing',
          () {
        final info1 = DeviceInfo('iPad Air');
        final info2 = DeviceInfo('  iPad Air  ');

        expect(info1, equals(info2));
      });
    });

    group('String Representation', () {
      test('should return formatted string via Equatable stringify', () {
        const infoStr = 'Windows 11 Desktop';
        final deviceInfo = DeviceInfo(infoStr);

        expect(deviceInfo.toString(), 'DeviceInfo($infoStr)');
      });
    });
  });
}
