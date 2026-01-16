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

    group('isValidEmail', () {
      test('should return true for robust valid email formats', () {
        final validEmails = [
          'user@example.com',
          'firstname.lastname@domain.com',
          'email@subdomain.example.com',
          '1234567890@example.com',
          '_______@example.com',
          'email@example.co.jp',
          'firstname+lastname@example.com',
          'customer.support@bank.com.br',
        ];

        for (final email in validEmails) {
          expect(StringUtils.isValidEmail(email), isTrue,
              reason: 'Failed for: $email');
        }
      });

      test('should return false for structural failures', () {
        final structuralFailures = [
          'plainAddress', // without @
          'missingAtSign.com', // missing @
          '@missingUser.com', // without local-part
          'user@.com', // domain starting with dot
          'user@domain..com', // consecutive dots in domain
          'user@domain.c', // TLD too short (depending on your business rule)
          'user@domain.123', // numeric TLD
        ];

        for (final email in structuralFailures) {
          expect(StringUtils.isValidEmail(email), isFalse,
              reason: 'Should fail structural: $email');
        }
      });

      test('should return false for invalid special characters positioning',
          () {
        final dotFailures = [
          '.user@example.com', // dot at start of local-part
          'user.@example.com', // dot at end of local-part
          'us..er@example.com', // consecutive dots in local-part
          'user@example.com.', // dot at end of domain
        ];

        for (final email in dotFailures) {
          expect(StringUtils.isValidEmail(email), isFalse,
              reason: 'Should fail dots: $email');
        }
      });

      test('should return false for malicious/security-risk inputs', () {
        final malicious = [
          '<script>alert("xss")</script>@test.com', // XSS
          'user@domain.com; DROP TABLE users', // SQL Injection
          'user@domain.com\nSubject: Fake', // Header Injection
          '   user@example.com   ', // Leading/trailing spaces (should be normalized first)
        ];

        for (final input in malicious) {
          expect(StringUtils.isValidEmail(input), isFalse,
              reason: 'Should fail security: $input');
        }
      });

      test('should return false for email exceeding RFC length (254 chars)',
          () {
        final longEmail = "${'a' * 245}@example.com";
        expect(StringUtils.isValidEmail(longEmail), isFalse);
      });
    });
  });
}
