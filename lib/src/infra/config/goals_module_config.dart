import 'package:bits_goals_module/bits_goals_module.dart';
import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/infra/config/data_sources/remote_data_source_config.dart';
import 'package:flutter/material.dart';

/// Configuration class for Goals Module access control.
/// Defines roles and their associated permissions.
/// Must be provided during module initialization.
///
/// Used in [BitsGoalsModule.init] to configure and initialize the module. Is accessed within the
/// module via [BuildContext] and [AppProvider] to enforce access control based on user roles and
/// permissions.
class GoalsModuleConfig {
  /// Callback function to fetch the list of user roles and their permissions within the goals module.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  ///   getRoles: () => [
  ///     UserRole(
  ///       roleName: 'admin',
  ///       rolePermissions: [
  ///         GoalsModulePermission.manageGlobalGoals,
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
  final List<UserRole> Function() getRoles;

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

  /// Callback to fetch the current currency used in the goals module.
  /// Usage example:
  /// ```dart
  /// final config = GoalsModuleConfig(
  /// ...
  ///   getCurrentCurrency: () => Currency.fromISO4217('BRL'),
  /// );
  /// ```
  final Currency Function() getCurrentCurrency;

  GoalsModuleConfig({
    required this.getRoles,
    required this.getCurrentUser,
    required this.remoteDataSrcConfig,
    required this.getCurrentCurrency,
  })  : assert(getRoles().isNotEmpty, 'roles cannot be empty'),
        assert(
            getRoles().map((e) => e.roleName).toSet().length ==
                getRoles().length,
            'Duplicate role names are not allowed');
}
