import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/logged_in_user/logged_in_user_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/utils/string_utils.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/email.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/user_role.dart';
import 'package:equatable/equatable.dart';

/// LoggedInUser Value Object
///
/// - Represents the authenticated user within the goals module context
/// - Contains essential identity and authorization data
/// - Immutable
/// - Equality is based on all attributes
class LoggedInUser extends Equatable {
  /// Unique identifier from the main app authentication provider
  final String _uid;

  final UserRole _role;

  /// User's logging email address
  final Email _email;

  /// User's name for display purposes
  final String _displayName;

  // =============================================================
  // Constructors
  // =============================================================

  /// Private constructor to enforce invariants
  const LoggedInUser._(
    this._uid,
    this._role,
    this._email,
    this._displayName,
  );

  /// Factory constructor to create a LoggedInUser with validation
  ///
  /// Performs domain validation to ensure the user object is in a valid state.
  ///
  /// Throws [LoggedInUserFailure] if:
  /// - [uid] is empty.
  /// - [email] is invalid or empty.
  /// - [role] is empty.
  /// - [displayName] is empty.
  factory LoggedInUser.create({
    required String uid,
    required UserRole role,
    required String email,
    required String displayName,
  }) {
    final uUid = _getValidUid(uid);
    final uEmail = _getValidEmail(email);
    final uDisplayName = _getValidDisplayName(displayName);
    return LoggedInUser._(
      uUid,
      UserRole(
        roleName: role.roleName,
        rolePermissions: role.rolePermissions,
      ),
      uEmail,
      uDisplayName,
    );
  }

  // =============================================================
  // Getters
  // =============================================================

  UserRole get role => UserRole(
        roleName: _role.roleName,
        rolePermissions: _role.rolePermissions,
      );

  String get uid => _uid.toString();

  Email get email => Email(_email.value);

  String get displayName => _displayName.toString();

  // =============================================================
  // Validation Helpers
  // =============================================================

  static String _getValidUid(String uid) {
    if (StringUtils.isEmpty(uid)) {
      throw const LoggedInUserFailure(
        LoggedInUserFailureReason.emptyUid,
      );
    }
    return uid;
  }

  static Email _getValidEmail(String email) {
    try {
      final validEmail = Email(email);
      return validEmail;
    } catch (_) {
      throw const LoggedInUserFailure(
        LoggedInUserFailureReason.invalidEmail,
      );
    }
  }

  static String _getValidDisplayName(String displayName) {
    if (StringUtils.isEmpty(displayName)) {
      throw const LoggedInUserFailure(
        LoggedInUserFailureReason.emptyDisplayName,
      );
    }
    return StringUtils.cleanAndCapitalizeAll(displayName);
  }

  // =============================================================
  // Equatable Overrides
  // =============================================================

  @override
  List<Object?> get props => [
        _uid,
        _role,
        _email,
        _displayName,
      ];

  @override
  bool? get stringify => true;
}
