import 'package:bits_goals_module/src/goals_module_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalsModuleConfig', () {
    test('should initialize with correct rolePermissions map', () {
      // Arrange
      final permissions = {
        'admin': [GoalsModulePermission.manageGlobalGoals],
        'user': [GoalsModulePermission.viewPersonalGoals],
      };

      // Act
      final config = GoalsModuleConfig(
        rolePermissions: permissions,
        getCurrentUserRole: () => 'admin',
      );

      // Assert
      expect(config.rolePermissions, equals(permissions));
      expect(config.rolePermissions['admin'],
          contains(GoalsModulePermission.manageGlobalGoals));
      expect(config.rolePermissions['user'],
          contains(GoalsModulePermission.viewPersonalGoals));
    });

    test('should execute the getCurrentUserRole callback correctly', () {
      // Arrange
      const expectedRole = 'super_admin';

      final config = GoalsModuleConfig(
        rolePermissions: {},
        getCurrentUserRole: () => expectedRole,
      );

      // Act
      final actualRole = config.getCurrentUserRole();

      // Assert
      expect(actualRole, equals(expectedRole));
    });

    test('should handle empty permissions map', () {
      // Arrange
      final config = GoalsModuleConfig(
        rolePermissions: {},
        getCurrentUserRole: () => 'guest',
      );

      // Assert
      expect(config.rolePermissions, isEmpty);
    });
  });
}
