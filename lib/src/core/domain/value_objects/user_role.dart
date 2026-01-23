import 'package:bits_goals_module/src/core/domain/failures/user_role/user_role_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/user_role/user_role_failure_reason.dart';
import 'package:bits_goals_module/src/infra/config/goals_module_permission.dart';
import 'package:equatable/equatable.dart';

/// Entity representing a User Role and its associated permissions.
///
/// Ensures strict validation: roles must have a name and at least one permission.
class UserRole extends Equatable {
  final String roleName;
  final List<GoalsModulePermission> rolePermissions;

  // =================================================================
  // Constructors
  // =================================================================

  /// Private constructor to enforce validation and immutability.
  const UserRole._({
    required this.roleName,
    required this.rolePermissions,
  });

  /// Factory constructor that centralizes business rules for Roles.
  ///
  /// Throws a [UserRoleFailure] if:
  /// - [roleName] is empty or whitespace only.
  /// - [rolePermissions] is empty.
  factory UserRole({
    required String roleName,
    List<GoalsModulePermission> rolePermissions = const [
      GoalsModulePermission.none
    ],
  }) {
    final trimmedName = roleName.trim();

    if (trimmedName.isEmpty) {
      throw const UserRoleFailure(UserRoleFailureReason.emptyName);
    }

    if (rolePermissions.isEmpty) {
      throw const UserRoleFailure(UserRoleFailureReason.emptyPermissions);
    }

    return UserRole._(
      roleName: trimmedName,
      // Defensive Copy
      rolePermissions: List.unmodifiable(rolePermissions),
    );
  }

  // =================================================================
  // Domain Logic
  // =================================================================

  /// Checks if the role holds a specific permission.
  bool hasPermission(GoalsModulePermission permission) {
    return rolePermissions.contains(permission);
  }

  // =================================================================
  // Equatable Overrides
  // =================================================================

  @override
  List<Object?> get props => [roleName, rolePermissions];

  @override
  bool? get stringify => true;
}
