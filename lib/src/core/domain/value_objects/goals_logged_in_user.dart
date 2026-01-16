import 'package:bits_goals_module/src/core/domain/failures/goals_logged_in_user/goals_logged_in_user_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/goals_logged_in_user/goals_logged_in_user_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/utils/string_utils.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/email.dart';
import 'package:equatable/equatable.dart';

/// GoalsLoggedInUser Value Object
///
/// - Represents the authenticated user within the goals module context
/// - Contains essential identity and authorization data
/// - Immutable
/// - Equality is based on all attributes
class GoalsLoggedInUser extends Equatable {
  /// Unique identifier from the main app authentication provider
  final String _uid;

  /// Role assigned to the user for access control (e.g., 'admin', 'manager')
  final String _role;

  /// User's logging email address
  final Email _email;

  /// User's name for display purposes
  final String _displayName;

  // =============================================================
  // Constructors
  // =============================================================

  /// Private constructor to enforce invariants
  const GoalsLoggedInUser._(
    this._uid,
    this._role,
    this._email,
    this._displayName,
  );

  /// Factory constructor to create a GoalsLoggedInUser with validation
  ///
  /// Performs domain validation to ensure the user object is in a valid state.
  ///
  /// Throws [GoalsLoggedInUserFailure] if:
  /// - [uid] is empty.
  /// - [email] is invalid or empty.
  /// - [role] is empty.
  /// - [displayName] is empty.
  factory GoalsLoggedInUser.create({
    required String uid,
    required String role,
    required String email,
    required String displayName,
  }) {
    final uUid = _getValidUid(uid);
    final uRole = _getValidRole(role);
    final uEmail = _getValidEmail(email);
    final uDisplayName = _getValidDisplayName(displayName);
    return GoalsLoggedInUser._(
      uUid,
      uRole,
      uEmail,
      uDisplayName,
    );
  }

  // =============================================================
  // Getters
  // =============================================================

  String get role => _role.toString();

  String get uid => _uid.toString();

  Email get email => Email(_email.value);

  String get displayName => _displayName.toString();

  // =============================================================
  // Validation Helpers
  // =============================================================

  static String _getValidUid(String uid) {
    if (StringUtils.isEmpty(uid)) {
      throw const GoalsLoggedInUserFailure(
        GoalsLoggedInUserFailureReason.emptyUid,
      );
    }
    return uid;
  }

  static String _getValidRole(String role) {
    if (StringUtils.isEmpty(role)) {
      throw const GoalsLoggedInUserFailure(
        GoalsLoggedInUserFailureReason.emptyRole,
      );
    }
    return role;
  }

  static Email _getValidEmail(String email) {
    try {
      final validEmail = Email(email);
      return validEmail;
    } catch (_) {
      throw const GoalsLoggedInUserFailure(
        GoalsLoggedInUserFailureReason.invalidEmail,
      );
    }
  }

  static String _getValidDisplayName(String displayName) {
    if (StringUtils.isEmpty(displayName)) {
      throw const GoalsLoggedInUserFailure(
        GoalsLoggedInUserFailureReason.emptyDisplayName,
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
