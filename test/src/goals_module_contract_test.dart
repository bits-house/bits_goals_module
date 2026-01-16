import 'package:bits_goals_module/src/core/domain/value_objects/goals_logged_in_user.dart';
import 'package:bits_goals_module/src/goals_module_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalsModuleConfig', () {
    // ============================================================
    // FIXTURES AND HELPERS
    // ============================================================
    GoalsLoggedInUser generateMockUser({required String role}) {
      return GoalsLoggedInUser.create(
        uid: 'user_123',
        role: role,
        email: 'testuser@example.com',
        displayName: 'Test User',
      );
    }

    test('should initialize with correct rolePermissions map', () {
      // Arrange
      final permissions = {
        'admin': [GoalsModulePermission.manageGlobalGoals],
        'user': [GoalsModulePermission.none],
      };

      // Act
      final config = GoalsModuleConfig(
        rolePermissions: permissions,
        getCurrentUser: () => generateMockUser(role: 'admin'),
      );

      // Assert
      expect(config.rolePermissions, equals(permissions));
      expect(config.rolePermissions['admin'],
          contains(GoalsModulePermission.manageGlobalGoals));
      expect(
          config.rolePermissions['user'], contains(GoalsModulePermission.none));
    });

    test('should execute the getCurrentUserRole callback correctly', () {
      // Arrange
      const expectedRole = 'super_admin';

      final config = GoalsModuleConfig(
        rolePermissions: {},
        getCurrentUser: () => generateMockUser(role: expectedRole),
      );

      // Act
      final actualRole = config.getCurrentUser().role;

      // Assert
      expect(actualRole, equals(expectedRole));
    });

    test('should handle empty permissions map', () {
      // Arrange
      final config = GoalsModuleConfig(
        rolePermissions: {},
        getCurrentUser: () => generateMockUser(role: 'guest'),
      );

      // Assert
      expect(config.rolePermissions, isEmpty);
    });
  });
}
