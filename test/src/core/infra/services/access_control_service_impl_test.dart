import 'package:bits_goals_module/src/core/domain/value_objects/goals_logged_in_user.dart';
import 'package:bits_goals_module/src/core/infra/services/access_control_service_impl.dart';
import 'package:bits_goals_module/src/goals_module_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// ---------------------------------------------------------------------
/// STUBS FOR CONTEXT (Copy this logic into your actual test file)
/// ---------------------------------------------------------------------

// Mocking the Config class
class MockGoalsModuleConfig extends Mock implements GoalsModuleConfig {}

void main() {
  late MockGoalsModuleConfig mockConfig;
  late AccessControlServiceImpl accessControlService;

  setUp(() {
    mockConfig = MockGoalsModuleConfig();
    accessControlService = AccessControlServiceImpl(mockConfig);
  });

  group('AccessControlServiceImpl |', () {
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

    // -------------------------------------------------------------------------
    // Scenario: Permission.none
    // -------------------------------------------------------------------------

    test(
      'Should return TRUE when permission is [GoalsModulePermission.none], '
      'regardless of the current role or configuration',
      () {
        // Arrange
        // We purposefully do not stub the config here to prove it isn't accessed
        // when permission is none.

        // Act
        final result =
            accessControlService.hasPermission(GoalsModulePermission.none);

        // Assert
        expect(result, isTrue);

        // Verify no interaction occurred with config
        verifyZeroInteractions(mockConfig);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Role HAS permission (Happy Path)
    // -------------------------------------------------------------------------

    test(
      'Should return TRUE when the current user role contains the requested permission',
      () {
        // Arrange
        const userRole = 'admin';
        const requestedPermission = GoalsModulePermission.manageGlobalGoals;

        // Mock the user role
        when(() => mockConfig.getCurrentUser)
            .thenReturn(() => generateMockUser(role: userRole));

        // Mock the permissions map containing the specific permission
        when(() => mockConfig.rolePermissions).thenReturn({
          userRole: [
            GoalsModulePermission.none,
            GoalsModulePermission.manageGlobalGoals,
          ],
        });

        // Act
        final result = accessControlService.hasPermission(requestedPermission);

        // Assert
        expect(result, isTrue);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Role lacks permission (Sad Path)
    // -------------------------------------------------------------------------

    test(
      'Should return FALSE when the current user role does NOT contain the requested permission',
      () {
        // Arrange
        const userRole = 'viewer';
        const requestedPermission = GoalsModulePermission.manageGlobalGoals;

        when(() => mockConfig.getCurrentUser).thenReturn(
          () => generateMockUser(role: userRole),
        );

        when(() => mockConfig.rolePermissions).thenReturn({
          userRole: [GoalsModulePermission.none],
        });

        // Act
        final result = accessControlService.hasPermission(requestedPermission);

        // Assert
        expect(result, isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Role not found in Config (Edge Case: Null Safety)
    // -------------------------------------------------------------------------

    test(
      'Should return FALSE when the current user role is not defined in the permissions map '
      '(handling the null coalescing operator ?? [])',
      () {
        // Arrange
        const userRole = 'unknown_role';
        const requestedPermission = GoalsModulePermission.manageGlobalGoals;

        when(() => mockConfig.getCurrentUser).thenReturn(
          () => generateMockUser(role: userRole),
        );

        // Mock a map that does not contain 'unknown_role'
        when(() => mockConfig.rolePermissions).thenReturn({
          'admin': [GoalsModulePermission.manageGlobalGoals],
        });

        // Act
        final result = accessControlService.hasPermission(requestedPermission);

        // Assert
        expect(result, isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Role exists but has empty permissions list
    // -------------------------------------------------------------------------

    test(
      'Should return FALSE when the current user role exists but has an empty list of permissions',
      () {
        // Arrange
        const userRole = 'restricted_user';

        when(() => mockConfig.getCurrentUser).thenReturn(
          () => generateMockUser(role: userRole),
        );
        when(() => mockConfig.rolePermissions).thenReturn({
          userRole: [],
        });

        // Act
        final result = accessControlService
            .hasPermission(GoalsModulePermission.manageGlobalGoals);

        // Assert
        expect(result, isFalse);
      },
    );
  });
}
