import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/year/invalid_year_reason.dart';
import 'package:equatable/equatable.dart';

/// Year Value Object
///
/// - Represents a calendar year
/// - Immutable
/// - Equality based on value
class Year extends Equatable {
  final int _value;

  const Year._(this._value);

  /// Creates a valid Year
  factory Year.fromInt(int value) {
    if (value < 0) {
      throw const InvalidYearFailure(InvalidYearReason.negative);
    } else if (value == 0) {
      throw const InvalidYearFailure(InvalidYearReason.zero);
    }
    return Year._(value);
  }

  int get value => _value;

  /// Returns true if this year is before [other]
  bool isBefore(Year other) => _value < other._value;

  /// Returns true if this year is after [other]
  bool isAfter(Year other) => _value > other._value;

  @override
  List<Object> get props => [_value];
}
