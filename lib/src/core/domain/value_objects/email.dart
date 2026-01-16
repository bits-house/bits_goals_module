import 'package:bits_goals_module/src/core/domain/failures/email/email_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/email/email_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/utils/string_utils.dart';
import 'package:equatable/equatable.dart';

/// Email Value Object
///
/// - Represents a validated and normalized email address
/// - Immutable
class Email extends Equatable {
  /// The normalized email address string
  final String _value;

  /// Private constructor to enforce invariants
  const Email._(this._value);

  /// Factory constructor to create a validated Email
  ///
  /// Normalizes the input (trim and lowercase) before validation.
  ///
  /// Throws [EmailFailure] with [EmailFailureReason.invalid] reason.
  factory Email(String email) {
    final String normalizedEmail = StringUtils.normalize(email);
    final validEmail = StringUtils.isValidEmail(normalizedEmail);
    if (!validEmail) {
      throw const EmailFailure(EmailFailureReason.invalid);
    }
    return Email._(normalizedEmail);
  }

  /// Returns the raw email string
  String get value => _value.toString();

  @override
  List<Object?> get props => [_value];

  @override
  bool? get stringify => true;
}
