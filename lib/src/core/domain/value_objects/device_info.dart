import 'package:bits_goals_module/src/core/domain/failures/device_info/device_info_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/device_info/device_info_failure_reason.dart';
import 'package:equatable/equatable.dart';

/// Value Object representing device identification information.
///
/// This VO ensures that device descriptions (e.g., "iPhone 13, iOS 15.4")
/// are not empty or invalid before being used in the domain layer.
class DeviceInfo extends Equatable {
  final String value;

  // =================================================================
  // Constructors
  // =================================================================

  /// Private constructor for immutability and controlled instantiation.
  const DeviceInfo._(this.value);

  /// Factory constructor that validates the device info string.
  ///
  /// Throws a [DeviceInfoFailure] if the info is empty or whitespace only.
  factory DeviceInfo(String info) {
    if (!_isValid(info)) {
      throw const DeviceInfoFailure(DeviceInfoFailureReason.emptyOrInvalid);
    }
    return DeviceInfo._(info.trim());
  }

  // =================================================================
  // Validation
  // =================================================================

  /// Checks if the info string contains actual content.
  static bool _isValid(String info) {
    return info.trim().isNotEmpty;
  }

  // =================================================================
  // Equatable Overrides
  // =================================================================

  @override
  List<Object?> get props => [value];

  @override
  bool? get stringify => true;
}
