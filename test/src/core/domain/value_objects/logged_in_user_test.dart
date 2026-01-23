import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tUid = 'usEr_123';
  final tRole = UserRole(
    roleName: 'admin',
    rolePermissions: const [GoalsModulePermission.manageGlobalGoals],
  );
  const tEmail = 'test@example.com';
  const tDisplayName = 'Test User';

  group('LoggedInUser', () {
    group('Instantiation and Normalization', () {
      test('should create a valid instance and normalize fields', () {
        const dirtyEmailValue = '  Test@EXAMPLE.com  ';
        const dirtyDisplayName = '  Test  User  ';

        // Act
        final user = LoggedInUser.create(
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
      test('should throw LoggedInUserFailure (emptyUid) when uid is empty', () {
        expect(
          () => LoggedInUser.create(
            uid: '   ',
            role: tRole,
            email: tEmail,
            displayName: tDisplayName,
          ),
          throwsA(
            isA<LoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              LoggedInUserFailureReason.emptyUid,
            ),
          ),
        );
      });

      test(
          'should throw LoggedInUserFailure (invalidEmail) when email is malformed',
          () {
        expect(
          () => LoggedInUser.create(
            uid: tUid,
            role: tRole,
            email: 'invalid-email',
            displayName: tDisplayName,
          ),
          throwsA(
            isA<LoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              LoggedInUserFailureReason.invalidEmail,
            ),
          ),
        );
      });

      test(
          'should throw LoggedInUserFailure (emptyDisplayName) when displayName is empty',
          () {
        expect(
          () => LoggedInUser.create(
            uid: tUid,
            role: tRole,
            email: tEmail,
            displayName: ' \n ',
          ),
          throwsA(
            isA<LoggedInUserFailure>().having(
              (e) => e.reason,
              'reason',
              LoggedInUserFailureReason.emptyDisplayName,
            ),
          ),
        );
      });
    });

    group('Getters', () {
      test('should return correct values from getters', () {
        // Arrange
        final user = LoggedInUser.create(
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
        final user1 = LoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );
        final user2 = LoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when one property differs', () {
        final user1 = LoggedInUser.create(
          uid: tUid,
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );
        final user2 = LoggedInUser.create(
          uid: 'different_uid',
          role: tRole,
          email: tEmail,
          displayName: tDisplayName,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('stringify should be true for better debug logs', () {
        final user = LoggedInUser.create(
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
