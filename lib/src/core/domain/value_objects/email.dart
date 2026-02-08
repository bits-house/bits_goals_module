import 'package:bits_goals_module/src/core/domain/failures/value_objects/email/email_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/value_objects/email/email_failure_reason.dart';
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
    _validateEmail(normalizedEmail);
    return Email._(normalizedEmail);
  }

  /// Validates the email format following strict TLD and structure rules.
  static void _validateEmail(String? email) {
    const failure = EmailFailure(EmailFailureReason.invalid);

    if (StringUtils.isEmpty(email)) throw failure;

    // 1. RFC: Total length must not exceed 254 characters
    if (email!.length > 254) throw failure;

    // 2. Basic structure: user@domain.tld
    // This Regex ensures there is an @ and at least one dot in the domain part
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );

    if (!emailRegex.hasMatch(email)) throw failure;

    final parts = email.split('@');
    final localPart = parts[0];
    final domainPart = parts[1];

    // 3. Validation of the Local-part (before the @)
    // Blocks dots at the start, end, or consecutive dots (..).
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      throw failure;
    }

    // 4. Validation of the Domain-part (after the @)
    // Blocks dots at the end or consecutive dots (..).
    final domainSegments = domainPart.split('.');

    // Blocks TLDs (last segment) that are purely numeric or too short (< 2 characters).
    final tld = domainSegments.last;
    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(tld);
    if (tld.length < 2 || isNumeric) {
      throw failure;
    }
  }

  /// Returns the raw email string
  String get value => _value.toString();

  @override
  List<Object?> get props => [_value];

  @override
  bool? get stringify => true;
}
