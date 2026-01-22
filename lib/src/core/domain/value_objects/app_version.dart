import 'package:bits_goals_module/src/core/domain/failures/app_version/app_version_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/app_version/app_version_failure_reason.dart';
import 'package:equatable/equatable.dart';

/// Value Object representing a Semantic Version (SemVer).
/// Ensures that the version string is always valid upon instantiation.
class AppVersion extends Equatable {
  final String value;

  // =================================================================
  // Constructors
  // =================================================================

  /// Private constructor to enforce validation through the factory.
  const AppVersion._(this.value);

  /// Factory constructor that centralizes business rules for versioning.
  ///
  /// Throws a [AppVersionFailure] if the version string does not follow
  /// the pattern 'major.minor.patch' or 'major.minor.patch+build'.
  factory AppVersion(String version) {
    if (!_isValid(version)) {
      throw const AppVersionFailure(AppVersionFailureReason.invalidFormat);
    }
    return AppVersion._(version);
  }

  // =================================================================
  // Validation
  // =================================================================

  /// Validates the version against a Strict Semantic Versioning Regex.
  static bool _isValid(String version) {
    final semVerRegex = RegExp(r'^\d+\.\d+\.\d+(\+[\w\.-]+)?$');
    return semVerRegex.hasMatch(version);
  }

  // =================================================================
  // Getters
  // =================================================================

  int get major => int.parse(value.split('.')[0]);

  int get minor => int.parse(value.split('.')[1]);

  int get patch {
    final patchPart = value.split('.')[2];
    return int.parse(
        patchPart.contains('+') ? patchPart.split('+')[0] : patchPart);
  }

  String? get build {
    if (!value.contains('+')) return null;
    return value.split('+').last;
  }

  bool get hasBuildMetadata => value.contains('+');

  // =================================================================
  // Equatable Overrides
  // =================================================================

  @override
  List<Object?> get props => [value];

  @override
  bool? get stringify => true;
}
