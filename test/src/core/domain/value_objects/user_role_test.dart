import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/domain/failures/user_role/user_role_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/user_role/user_role_failure_reason.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';

void main() {
  group('UserRole Value Object Tests', () {
    // Helper constants for tests
    const defaultPermission = GoalsModulePermission.none;

    // =================================================================
    // 1. Instantiation & Validation Logic
    // =================================================================
    group('Instantiation & Validation', () {
      test('should create a valid UserRole when data is correct', () {
        // Arrange
        const name = 'Administrator';
        final permissions = [defaultPermission];

        // Act
        final role = UserRole(roleName: name, rolePermissions: permissions);

        // Assert
        expect(role.roleName, name);
        expect(role.rolePermissions, equals(permissions));
      });

      test('should automatically trim whitespace from roleName', () {
        // Arrange
        const untrimmedName = '   Manager   ';

        // Act
        final role = UserRole(roleName: untrimmedName);

        // Assert
        expect(role.roleName, 'Manager');
      });

      test('should throw UserRoleFailure when roleName is empty', () {
        // Act & Assert
        expect(
          () => UserRole(roleName: ''),
          throwsA(
            isA<UserRoleFailure>().having(
              (f) => f.reason,
              'reason',
              UserRoleFailureReason.emptyName,
            ),
          ),
        );
      });

      test('should throw UserRoleFailure when roleName is whitespace only', () {
        // Act & Assert
        expect(
          () => UserRole(roleName: '   '),
          throwsA(isA<UserRoleFailure>()),
        );
      });

      test(
          'should throw UserRoleFailure when rolePermissions is explicitly empty',
          () {
        // Act & Assert
        // Note: The factory has a default value, but if [] is passed explicitly, it must fail.
        expect(
          () => UserRole(roleName: 'Admin', rolePermissions: const []),
          throwsA(
            isA<UserRoleFailure>().having(
              (f) => f.reason,
              'reason',
              UserRoleFailureReason.emptyPermissions,
            ),
          ),
        );
      });

      test(
          'should use default [GoalsModulePermission.none] if permissions are omitted',
          () {
        // Act
        final role = UserRole(roleName: 'Viewer');

        // Assert
        expect(role.rolePermissions, isNotEmpty);
        expect(role.rolePermissions, contains(GoalsModulePermission.none));
      });
    });

    // =================================================================
    // 2. Immutability & Defensive Copying
    // =================================================================
    group('Immutability & Security', () {
      test('should create a defensive copy of the permissions list', () {
        // Arrange
        final mutableList = [defaultPermission];
        final role = UserRole(roleName: 'Editor', rolePermissions: mutableList);

        // Act: Modify the original list externally
        mutableList.clear();

        // Assert: The entity's list should remain unaffected
        expect(role.rolePermissions, contains(defaultPermission));
        expect(mutableList, isEmpty);
      });

      test(
          'should throw UnsupportedError when trying to modify rolePermissions directly',
          () {
        // Arrange
        final role = UserRole(roleName: 'Tester');

        // Act & Assert
        // Since List.unmodifiable is used, any mutation attempt throws at runtime.
        expect(() => role.rolePermissions.add(defaultPermission),
            throwsUnsupportedError);
        expect(() => role.rolePermissions.clear(), throwsUnsupportedError);
      });
    });

    // =================================================================
    // 3. Domain Logic
    // =================================================================
    group('Domain Logic', () {
      test('hasPermission should return true if permission exists', () {
        // Arrange
        final role = UserRole(
          roleName: 'SuperUser',
          rolePermissions: const [
            GoalsModulePermission.none
          ], // Assuming 'none' is the test target
        );

        // Act & Assert
        expect(role.hasPermission(GoalsModulePermission.none), isTrue);
      });

      test('hasPermission should return false if permission does not exist',
          () {
        // Arrange
        final role = UserRole(
            roleName: 'Guest',
            rolePermissions: const [GoalsModulePermission.none]);

        // Act & Assert
        expect(role.hasPermission(GoalsModulePermission.manageGlobalGoals),
            isFalse);
      });
    });

    // =================================================================
    // 4. Equality & Representation
    // =================================================================
    group('Equality & Stringify', () {
      test('should verify value equality (Equatable)', () {
        // Arrange
        final role1 = UserRole(
            roleName: 'Admin', rolePermissions: const [defaultPermission]);
        final role2 = UserRole(
            roleName: 'Admin', rolePermissions: const [defaultPermission]);
        final role3 = UserRole(
            roleName: 'User', rolePermissions: const [defaultPermission]);
        // Assert
        expect(role1, equals(role2));
        expect(role1, isNot(equals(role3)));
      });

      test('toString should return a formatted string with props', () {
        // Arrange
        final role = UserRole(roleName: 'SysAdmin');

        // Act
        final stringRep = role.toString();

        // Assert
        expect(stringRep, contains('UserRole'));
        expect(stringRep, contains('SysAdmin'));
      });
    });
  });
}
