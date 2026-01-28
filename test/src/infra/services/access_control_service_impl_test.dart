import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_config.dart';
import 'package:bits_goals_module/src/infra/services/access_control_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// ---------------------------------------------------------------------
/// MOCKS
/// ---------------------------------------------------------------------
class MockGoalsModuleConfig extends Mock implements GoalsModuleConfig {}

class MockLoggedInUser extends Mock implements LoggedInUser {}

void main() {
  late MockGoalsModuleConfig mockConfig;
  late AccessControlServiceImpl accessControlService;

  setUp(() {
    mockConfig = MockGoalsModuleConfig();
    accessControlService = AccessControlServiceImpl(mockConfig);
  });

  group('AccessControlServiceImpl Tests |', () {
    // ============================================================
    // FIXTURES AND HELPERS
    // ============================================================

    /// Helper to create a LoggedInUser instance with a specific role name.
    /// Note: The User object only holds the role name (String).
    /// The actual permissions are resolved via the Config.
    LoggedInUser generateMockUser({
      required String roleName,
    }) {
      return LoggedInUser.create(
        uid: 'user_123',
        roleName: roleName,
        email: 'testuser@example.com',
        displayName: 'Test User',
      );
    }

    // -------------------------------------------------------------------------
    // Scenario 1: Optimization Check (Permission.none)
    // -------------------------------------------------------------------------

    test(
      'Should return TRUE immediately when checking [GoalsModulePermission.none], '
      'skipping any config or user lookup to optimize performance',
      () {
        // Act
        final result =
            accessControlService.hasPermission(GoalsModulePermission.none);

        // Assert
        expect(result, isTrue);

        // Verify: Ensure we didn't waste resources fetching user or config
        verifyZeroInteractions(mockConfig);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario 2: Role HAS permission (Happy Path)
    // -------------------------------------------------------------------------

    test(
      'Should return TRUE when the current user role exists in config AND has the requested permission',
      () {
        // Arrange
        const userRoleName = 'admin';
        const requestedPermission = GoalsModulePermission.manageGlobalGoals;

        // 1. Mock the Current User
        // FIX: We mock the method call `()` instead of the property getter
        when(() => mockConfig.getCurrentUser).thenReturn(
          () => generateMockUser(roleName: userRoleName),
        );

        // 2. Mock the Config Roles (The Source of Truth)
        when(() => mockConfig.roles).thenReturn([
          UserRole(
            roleName: userRoleName,
            rolePermissions: const [
              GoalsModulePermission.manageGlobalGoals, // Permission present
            ],
          ),
        ]);

        // Act
        final result = accessControlService.hasPermission(requestedPermission);

        // Assert
        expect(result, isTrue);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario 3: Role LACKS permission (Sad Path)
    // -------------------------------------------------------------------------

    test(
      'Should return FALSE when the current user role exists but LACKS the requested permission',
      () {
        // Arrange
        const userRoleName = 'viewer';
        const requestedPermission = GoalsModulePermission.manageGlobalGoals;

        when(() => mockConfig.getCurrentUser).thenReturn(
          () => generateMockUser(roleName: userRoleName),
        );

        when(() => mockConfig.roles).thenReturn([
          UserRole(
            roleName: userRoleName,
            rolePermissions: const [
              GoalsModulePermission.none, // Lacks 'manageGlobalGoals'
            ],
          ),
        ]);

        // Act
        final result = accessControlService.hasPermission(requestedPermission);

        // Assert
        expect(result, isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario 4: Role not found in Config (Security Fallback)
    // -------------------------------------------------------------------------

    test(
      'Should return FALSE (Safe Fallback) when the current user role is NOT defined in the config',
      () {
        // Arrange
        const unknownRole = 'unknown_or_deprecated_role';
        const requestedPermission = GoalsModulePermission.manageGlobalGoals;

        // User has a role that the app config doesn't know about
        when(() => mockConfig.getCurrentUser).thenReturn(
          () => generateMockUser(roleName: unknownRole),
        );

        // Config only knows about 'admin'
        when(() => mockConfig.roles).thenReturn([
          UserRole(
            roleName: 'admin',
            rolePermissions: const [GoalsModulePermission.manageGlobalGoals],
          ),
        ]);

        // Act
        final result = accessControlService.hasPermission(requestedPermission);

        // Assert
        expect(result, isFalse,
            reason:
                'Unknown roles must default to restricted access (Null Object Pattern)');
      },
    );

    // -------------------------------------------------------------------------
    // Scenario 5: User Proxy
    // -------------------------------------------------------------------------

    test(
      'loggedInUser getter should forward the user object directly from config',
      () {
        // Arrange
        final expectedUser = generateMockUser(roleName: 'user');
        when(() => mockConfig.getCurrentUser).thenReturn(() => expectedUser);

        // Act
        final result = accessControlService.loggedInUser;

        // Assert
        expect(result, equals(expectedUser));
        verify(() => mockConfig.getCurrentUser()).called(1);
      },
    );
  });
}
