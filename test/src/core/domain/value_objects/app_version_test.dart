import 'package:bits_goals_module/src/core/domain/value_objects/app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/domain/failures/app_version/app_version_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/app_version/app_version_failure_reason.dart';

void main() {
  group('AppVersion Value Object Tests', () {
    group('Instantiation & Validation', () {
      test('should create a valid AppVersion when format is major.minor.patch',
          () {
        const versionStr = '1.0.0';
        final appVersion = AppVersion(versionStr);
        expect(appVersion.value, versionStr);
      });

      test(
          'should create a valid AppVersion when format includes build metadata',
          () {
        const versionStr = '2.1.4+12';
        final appVersion = AppVersion(versionStr);
        expect(appVersion.value, versionStr);
      });

      test('should create a valid AppVersion with alphanumeric build metadata',
          () {
        const versionStr = '1.0.0+beta.1';
        final appVersion = AppVersion(versionStr);
        expect(appVersion.value, versionStr);
      });

      test('should throw AppVersionFailure when format is missing patch', () {
        expect(
            () => AppVersion('1.0'),
            throwsA(isA<AppVersionFailure>().having((f) => f.reason, 'reason',
                AppVersionFailureReason.invalidFormat)));
      });

      test('should throw AppVersionFailure for empty string', () {
        expect(() => AppVersion(''), throwsA(isA<AppVersionFailure>()));
      });

      test('should throw AppVersionFailure for non-numeric versions', () {
        expect(() => AppVersion('a.b.c'), throwsA(isA<AppVersionFailure>()));
      });

      test(
          'should throw AppVersionFailure if it contains letters in major/minor/patch',
          () {
        expect(() => AppVersion('1.0.0a'), throwsA(isA<AppVersionFailure>()));
      });
    });

    group('Getters & Logic', () {
      test('should correctly extract major, minor, and patch numbers', () {
        final appVersion = AppVersion('1.2.3');
        expect(appVersion.major, 1);
        expect(appVersion.minor, 2);
        expect(appVersion.patch, 3);
      });

      test('should correctly extract patch when build metadata exists', () {
        final appVersion = AppVersion('1.2.3+45');
        expect(appVersion.patch, 3);
      });

      test('should return null for build when no metadata is present', () {
        final appVersion = AppVersion('1.0.0');
        expect(appVersion.build, isNull);
        expect(appVersion.hasBuildMetadata, isFalse);
      });

      test('should return build string when metadata is present', () {
        final appVersion = AppVersion('1.0.0+v10');
        expect(appVersion.build, 'v10');
        expect(appVersion.hasBuildMetadata, isTrue);
      });
    });

    group('Equality & Value Comparison', () {
      test('two instances with same value should be equal (Equatable)', () {
        final v1 = AppVersion('1.1.1');
        final v2 = AppVersion('1.1.1');
        expect(v1, equals(v2));
      });

      test('two instances with different build numbers should not be equal',
          () {
        final v1 = AppVersion('1.1.1+1');
        final v2 = AppVersion('1.1.1+2');
        expect(v1, isNot(equals(v2)));
      });
    });

    group('String Representation', () {
      test('should return formatted string including class name and value', () {
        const versionStr = '1.2.3+45';
        final appVersion = AppVersion(versionStr);

        expect(appVersion.toString(), 'AppVersion($versionStr)');
      });

      test('should reflect the exact version value in toString', () {
        const versionStr = '2.0.0';
        final appVersion = AppVersion(versionStr);

        expect(appVersion.toString(), contains(versionStr));
      });
    });
  });
}
