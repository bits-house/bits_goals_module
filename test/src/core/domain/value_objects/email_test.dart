import 'package:bits_goals_module/src/core/domain/failures/value_objects/email/email_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/value_objects/email/email_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidEmail', () {
    test('should create Email for robust valid email formats', () {
      final validEmails = [
        'user@example.com',
        'firstname.lastname@domain.com',
        'email@subdomain.example.com',
        '1234567890@example.com',
        '_______@example.com',
        'email@example.co.jp',
        'firstname+lastname@example.com',
        'customer.support@bank.com.br',
        '   usEr@exAmple.com   ',
      ];

      for (final email in validEmails) {
        expect(
          Email(email),
          isA<Email>(),
        );
      }
    });

    test('should throw EmailFailure for structural failures', () {
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
        expect(
          () => Email(email),
          throwsA(isA<EmailFailure>().having(
            (e) => e.reason,
            'reason',
            EmailFailureReason.invalid,
          )),
          reason: 'Should fail structural: $email',
        );
      }
    });

    test('should throw EmailFailure for invalid special characters positioning',
        () {
      final dotFailures = [
        '.user@example.com', // dot at start of local-part
        'user.@example.com', // dot at end of local-part
        'us..er@example.com', // consecutive dots in local-part
        'user@example.com.', // dot at end of domain
      ];

      for (final email in dotFailures) {
        expect(
          () => Email(email),
          throwsA(isA<EmailFailure>().having(
            (e) => e.reason,
            'reason',
            EmailFailureReason.invalid,
          )),
          reason: 'Should fail dot positioning: $email',
        );
      }
    });

    test('should throw EmailFailure for malicious/security-risk inputs', () {
      final malicious = [
        '<script>alert("xss")</script>@test.com', // XSS
        'user@domain.com; DROP TABLE users', // SQL Injection
        'user@domain.com\nSubject: Fake', // Header Injection
      ];

      for (final input in malicious) {
        expect(
          () => Email(input),
          throwsA(isA<EmailFailure>().having(
            (e) => e.reason,
            'reason',
            EmailFailureReason.invalid,
          )),
          reason: 'Should fail security: $input',
        );
      }
    });

    test('should throw EmailFailure for email exceeding RFC length (254 chars)',
        () {
      final longEmail = "${'a' * 245}@example.com";
      expect(
        () => Email(longEmail),
        throwsA(isA<EmailFailure>().having(
          (e) => e.reason,
          'reason',
          EmailFailureReason.invalid,
        )),
      );
    });
  });
}
