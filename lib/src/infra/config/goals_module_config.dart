import 'package:bits_goals_module/src/core/domain/value_objects/logged_in_user.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:bits_goals_module/src/infra/config/data_sources/remote_data_src_config.dart';

/// Configuration class for Goals Module access control.
/// Defines roles and their associated permissions.
/// Must be provided during module initialization.
class GoalsModuleConfig {
  /// List of user roles and their permissions within the goals module.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  ///   roles: [
  ///     UserRole(
  ///       roleName: 'admin',
  ///       rolePermissions: [
  ///         GoalsModulePermission.createGoal,
  ///       ],
  ///     ),
  ///     UserRole(
  ///       roleName: 'guest',
  ///       rolePermissions: [
  ///         GoalsModulePermission.none,
  ///       ],
  ///     ),
  ///   ],
  /// ...
  /// );
  /// ```
  final List<UserRole> roles;

  /// Callback to fetch the current user's role and other details.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  /// ...
  /// getCurrentUser: () => mainAppService.getCurrentUser(),
  /// // returns LoggedInUser (goals module user representation)
  /// ```
  final LoggedInUser Function() getCurrentUser;

  /// Configuration for the remote data source (cloud database api) used by the goals module.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  /// ...
  ///   remoteDataSrcConfig: FirestoreConfig(
  ///     client: FirebaseFirestore.instance,
  ///     some_collection_name: 'collection_name',
  ///   ),
  /// );
  /// ```
  final RemoteDataSourceConfig remoteDataSrcConfig;

  GoalsModuleConfig({
    required this.roles,
    required this.getCurrentUser,
    required this.remoteDataSrcConfig,
  })  : assert(roles.isNotEmpty, 'roles cannot be empty'),
        assert(roles.map((e) => e.roleName).toSet().length == roles.length,
            'Duplicate role names are not allowed');
}
