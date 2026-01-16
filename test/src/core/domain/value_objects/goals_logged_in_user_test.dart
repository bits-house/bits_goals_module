import 'package:bits_goals_module/src/core/domain/failures/goals_logged_in_user/goals_logged_in_user_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/goals_logged_in_user/goals_logged_in_user_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/goals_logged_in_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tUid = 'usEr_123';
  const tRole = 'admin';
  const tEmail = 'test@example.com';
  const tDisplayName = 'Test User';

  group('GoalsLoggedInUser', () {
    group('Instantiation and Normalization', () {
      test('should create a valid instance and normalize fields', () {
        const dirtyEmailValue = '  Test@EXAMPLE.com  ';
        const dirtyDisplayName = '  Test  User  ';

        // Act
        final user = GoalsLoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: dirtyEmailValue,
          displayName: dirtyDisplayName,
        );

        // Assert
        expect(user.uid, equals(tUid));
        expect(user.role, equals(tRole));
        expect(user.email.value, equals(tEmail));
        expect(user.displayName, equals(tDisplayName));
      });
    });

    group('Validation Failures', () {
      test('should throw GoalsLoggedInUserFailure (emptyUid) when uid is empty',
          () {
        expect(
          () => GoalsLoggedInUser.create(
            uid: '   ',
            role: tRole,
            email: tEmail,
            displayName: tDisplayName,
          ),
          throwsA(
            isA<GoalsLoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              GoalsLoggedInUserFailureReason.emptyUid,
            ),
          ),
        );
      });

      test(
          'should throw GoalsLoggedInUserFailure (invalidEmail) when email is malformed',
          () {
        expect(
          () => GoalsLoggedInUser.create(
            uid: tUid,
            role: tRole,
            email: 'invalid-email',
            displayName: tDisplayName,
          ),
          throwsA(
            isA<GoalsLoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              GoalsLoggedInUserFailureReason.invalidEmail,
            ),
          ),
        );
      });

      test(
          'should throw GoalsLoggedInUserFailure (emptyRole) when role is empty',
          () {
        expect(
          () => GoalsLoggedInUser.create(
            uid: tUid,
            role: '',
            email: tEmail,
            displayName: tDisplayName,
          ),
          throwsA(
            isA<GoalsLoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              GoalsLoggedInUserFailureReason.emptyRole,
            ),
          ),
        );
      });

      test(
          'should throw GoalsLoggedInUserFailure (emptyDisplayName) when displayName is empty',
          () {
        expect(
          () => GoalsLoggedInUser.create(
            uid: tUid,
            role: tRole,
            email: tEmail,
            displayName: ' \n ',
          ),
          throwsA(
            isA<GoalsLoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              GoalsLoggedInUserFailureReason.emptyDisplayName,
            ),
          ),
        );
      });
    });

    group('Getters', () {
      test('should return correct values from getters', () {
        // Arrange
        final user = GoalsLoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );

        // Act & Assert
        expect(user.uid, equals(tUid));
        expect(user.role, equals(tRole));
        expect(user.email.value, equals(tEmail));
        expect(user.displayName, equals(tDisplayName));
      });
    });

    group('Equality and Value Object properties', () {
      test('should be equal when all properties are identical', () {
        final user1 = GoalsLoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );
        final user2 = GoalsLoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when one property differs', () {
        final user1 = GoalsLoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );
        final user2 = GoalsLoggedInUser.create(
          uid: 'different_uid',
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('stringify should be true for better debug logs', () {
        final user = GoalsLoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );

        expect(user.toString(), contains(tUid));
        expect(user.toString(), contains(tEmail));
        expect(user.toString(), contains(tDisplayName));
        expect(user.toString(), contains(tUid));
        expect(user.stringify, isTrue);
      });
    });
  });
}
