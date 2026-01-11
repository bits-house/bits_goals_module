import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/month/invalid_month_reason.dart';
import 'package:equatable/equatable.dart';
import 'month_name.dart';

/// Month Value Object
///
/// - Represents a month of the year (1 to 12)
/// - Immutable
/// - Equality is based on value
/// - Does not depend on DateTime
class Month extends Equatable {
  /// Month number (1 = January, 12 = December)
  final int _value;

  /// Private constructor to enforce invariants
  const Month._(this._value);

  /// Factory constructor to create a Month from an integer
  ///
  /// Throws [InvalidMonthFailure] if the value is outside the valid range.
  factory Month.fromInt(int value) {
    if (value < 1) {
      throw const InvalidMonthFailure(InvalidMonthReason.belowRange);
    }

    if (value > 12) {
      throw const InvalidMonthFailure(InvalidMonthReason.aboveRange);
    }

    return Month._(value);
  }

  /// Numeric value of the month (1 to 12)
  int get value => _value;

  /// Semantic name of the month
  MonthName get name => MonthName.values[_value - 1];

  /// Returns true if this month comes before [other]
  bool isBefore(Month other) => _value < other._value;

  /// Returns true if this month comes after [other]
  bool isAfter(Month other) => _value > other._value;

  /// Returns true if this month is the same as [other]
  bool isSame(Month other) => _value == other._value;

  /// Indicates whether this is the first month of the year
  bool get isFirstMonth => _value == 1;

  /// Indicates whether this is the last month of the year
  bool get isLastMonth => _value == 12;

  @override
  List<Object> get props => [_value];
}
