import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/money/invalid_money_reason.dart';
import 'package:equatable/equatable.dart';

/// Money Value Object
///
/// - Represents a monetary value
/// - Internally stored as integer cents to avoid floating point precision issues
/// - Immutable
/// - Equality is based on value (cents)
class Money extends Equatable {
  /// Monetary value represented in cents (e.g. R$10.50 -> 1050)
  final int _cents;

  /// Private constructor to enforce invariants
  const Money._(this._cents);

  /// Factory constructor to create Money from a double value
  ///
  /// The value is rounded to the nearest cent.
  factory Money.fromDouble(double value) {
    final int cents = (value * 100).round();
    return Money._(cents);
  }

  /// Gets the monetary value in cents
  int get cents => _cents;

  /// Factory constructor to create Money from integer cents
  factory Money.fromCents(int cents) {
    return Money._(cents);
  }

  /// Converts the monetary value back to double
  ///
  /// Intended for presentation purposes only.
  double toDouble() {
    return _cents / 100;
  }

  /// Adds two Money values
  ///
  /// Returns a new Money instance.
  /// Original instances remain unchanged.
  Money operator +(Money other) {
    return Money._(_cents + other._cents);
  }

  /// Subtracts another Money value
  Money operator -(Money other) {
    final result = _cents - other._cents;

    return Money._(result);
  }

  /// Splits the money into [partsCount] chunks, distributing the remainder
  /// [cents] to the first chunks.
  ///
  /// Example: R$ 1,00 split in 3:
  /// [R$ 0,34, R$ 0,33, R$ 0,33]
  ///
  /// Throws [InvalidMoneyFailure] if parts is less than 2.
  /// Throws [InvalidMoneyFailure] if money is negative.
  ///
  /// Usage:
  /// ```dart
  /// final money = Money.fromCents(100);
  /// final splits = money.split(3);
  /// // splits is [Money(34), Money(33), Money(33)]
  /// ```
  List<Money> split(int partsCount) {
    if (_cents < 0) {
      throw const InvalidMoneyFailure(InvalidMoneyReason.splitNegativeCents);
    }
    if (partsCount < 2) {
      throw const InvalidMoneyFailure(InvalidMoneyReason.invalidSplitCount);
    }

    final baseCents = _cents ~/ partsCount;
    final remainder = _cents % partsCount;

    return List.generate(partsCount, (index) {
      final amount = baseCents + (index < remainder ? 1 : 0);
      return Money._(amount);
    });
  }

  @override
  List<Object> get props => [_cents];
}
