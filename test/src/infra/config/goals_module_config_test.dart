import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:bits_goals_module/src/infra/config/data_sources/firestore_config.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_config.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreDataSourceConfig extends Mock implements FirestoreConfig {}

void main() {
  late MockFirestoreDataSourceConfig firestoreConfig;

  setUp(() {
    firestoreConfig = MockFirestoreDataSourceConfig();
    when(() => firestoreConfig.client).thenReturn(FakeFirebaseFirestore());
  });

  group('GoalsModuleConfig Tests', () {
    // ============================================================
    // FIXTURES AND HELPERS
    // ============================================================

    /// Helper to create a logged-in user with a valid Role entity.
    LoggedInUser generateUser({
      required String roleName,
      String uid = 'user_123',
    }) {
      return LoggedInUser.create(
        uid: uid,
        roleName: roleName,
        email: 'testuser@example.com',
        displayName: 'Test User',
      );
    }

    /// Fixture for a simple valid role list.
    final simpleRoleList = [
      UserRole(
        roleName: 'user',
        rolePermissions: const [GoalsModulePermission.none],
      ),
    ];

    // ============================================================
    // TESTS
    // ============================================================

    test('should initialize correctly with a valid List<UserRole>', () {
      // Arrange
      final adminRole = UserRole(
        roleName: 'admin',
        rolePermissions: const [GoalsModulePermission.manageGlobalGoals],
      );

      // Act
      final config = GoalsModuleConfig(
        roles: [adminRole],
        getCurrentUser: () => generateUser(roleName: 'admin'),
        remoteDataSrcConfig: firestoreConfig,
      );

      // Assert
      expect(config.roles.length, 1);
      expect(config.roles.first.roleName, 'admin');
      expect(
        config.roles.first.rolePermissions,
        contains(GoalsModulePermission.manageGlobalGoals),
      );
    });

    test('should execute the getCurrentUser callback and return full user data',
        () {
      // Arrange
      final expectedUser = generateUser(roleName: 'manager', uid: 'mgr_123');

      final config = GoalsModuleConfig(
        roles:
            simpleRoleList, // Config roles don't strictly need to match the user here
        getCurrentUser: () => expectedUser,
        remoteDataSrcConfig: firestoreConfig,
      );

      // Act
      final result = config.getCurrentUser();

      // Assert
      // Accessing the role name through the UserRole entity
      expect(result.roleName, equals('manager'));
      expect(result.uid, equals('mgr_123'));
      expect(result, isA<LoggedInUser>());
    });

    test('should maintain reference to the provided remoteDataSrcConfig', () {
      // Act
      final config = GoalsModuleConfig(
        roles: simpleRoleList,
        getCurrentUser: () => generateUser(roleName: 'user'),
        remoteDataSrcConfig: firestoreConfig,
      );

      // Assert
      expect(config.remoteDataSrcConfig, same(firestoreConfig));
      expect(config.remoteDataSrcConfig.client, isA<FakeFirebaseFirestore>());
    });

    test('should handle UserRole entities with multiple permissions', () {
      // Arrange
      final editorRole = UserRole(
        roleName: 'editor',
        rolePermissions: const [
          GoalsModulePermission.manageGlobalGoals,
          GoalsModulePermission.none,
        ],
      );

      final config = GoalsModuleConfig(
        roles: [editorRole],
        getCurrentUser: () => generateUser(roleName: 'editor'),
        remoteDataSrcConfig: firestoreConfig,
      );

      // Act
      final savedRole = config.roles.firstWhere((r) => r.roleName == 'editor');

      // Assert
      expect(savedRole.rolePermissions.length, 2);
      expect(
        savedRole.rolePermissions,
        containsAll([
          GoalsModulePermission.manageGlobalGoals,
          GoalsModulePermission.none,
        ]),
      );
    });

    test(
        'should return different users on subsequent calls if callback logic changes',
        () {
      // Arrange
      var currentRoleName = 'guest';

      final config = GoalsModuleConfig(
        roles: simpleRoleList,
        getCurrentUser: () => generateUser(roleName: currentRoleName),
        remoteDataSrcConfig: firestoreConfig,
      );

      // Act & Assert 1
      expect(config.getCurrentUser().roleName, 'guest');

      // Act & Assert 2: Simulate state change
      currentRoleName = 'admin';
      expect(config.getCurrentUser().roleName, 'admin');
    });

    test('should throw AssertionError when roles list is empty', () {
      // Assert
      expect(
        () => GoalsModuleConfig(
          roles: [], // Empty list forbidden
          getCurrentUser: () => generateUser(roleName: 'user'),
          remoteDataSrcConfig: firestoreConfig,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    // ============================================================
    // DUPLICATE ROLES
    // ============================================================
    test(
        'should throw AssertionError or ArgumentError when duplicate role names are provided',
        () {
      // Arrange
      final duplicateRoles = [
        UserRole(
            roleName: 'manager',
            rolePermissions: const [GoalsModulePermission.none]),
        UserRole(
            roleName: 'manager',
            rolePermissions: const [GoalsModulePermission.manageGlobalGoals]),
      ];

      // Act & Assert
      expect(
        () => GoalsModuleConfig(
          roles: duplicateRoles,
          getCurrentUser: () => generateUser(roleName: 'manager'),
          remoteDataSrcConfig: firestoreConfig,
        ),
        throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>())),
        reason: 'GoalsModuleConfig must not allow two roles with the same name',
      );
    });
  });
}
