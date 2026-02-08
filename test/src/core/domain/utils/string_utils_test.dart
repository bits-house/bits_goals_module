import 'package:bits_goals_module/src/core/domain/utils/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringUtils', () {
    group('isEmpty', () {
      test('should return true for null or blank-only strings', () {
        expect(StringUtils.isEmpty(null), isTrue);
        expect(StringUtils.isEmpty(''), isTrue);
        expect(StringUtils.isEmpty('    '), isTrue);
        expect(StringUtils.isEmpty('\n\r\t'), isTrue);
      });

      test('should return false for any visible content', () {
        expect(StringUtils.isEmpty('a'), isFalse);
        expect(StringUtils.isEmpty(' 0 '), isFalse);
        expect(StringUtils.isEmpty('.'), isFalse);
      });

      test('should handle zero-width characters (common in copy-paste errors)',
          () {
        // Zero-width space (\u200B)
        expect(StringUtils.isEmpty('\u200B'), isFalse);
      });
    });

    group('normalize', () {
      test('should trim whitespace and convert to lowercase', () {
        const input = '  User@Example.COM  ';
        final normalized = StringUtils.normalize(input);
        expect(normalized, equals('user@example.com'));
      });
    });
  });
}
