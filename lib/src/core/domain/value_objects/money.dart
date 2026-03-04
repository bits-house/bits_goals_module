import 'package:bits_goals_module/src/core/domain/failures/value_objects/money/invalid_money_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/value_objects/money/invalid_money_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/currency.dart';
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

  final Currency currency;

  /// Private constructor to enforce invariants
  const Money._({
    required int cents,
    required this.currency,
  }) : _cents = cents;

  /// Factory constructor to create Money from a double value
  ///
  /// The value is rounded to the nearest cent.
  factory Money.fromDouble({
    required double value,
    required Currency currency,
  }) {
    final int cents = (value * 100).round();
    return Money._(cents: cents, currency: currency);
  }

  /// Gets the monetary value in cents
  int get cents => _cents;

  /// Factory constructor to create Money from integer cents
  factory Money.fromCents({
    required int cents,
    required Currency currency,
  }) {
    return Money._(cents: cents, currency: currency);
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
    if (currency != other.currency) {
      throw const InvalidMoneyFailure(InvalidMoneyReason.currencyMismatch);
    }

    final result = _cents + other._cents;

    return Money._(cents: result, currency: currency);
  }

  /// Subtracts another Money value
  Money operator -(Money other) {
    if (currency != other.currency) {
      throw const InvalidMoneyFailure(InvalidMoneyReason.currencyMismatch);
    }

    final result = _cents - other._cents;

    return Money._(cents: result, currency: currency);
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
  /// final money = Money.fromCents(cents: 100, ...);
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
      return Money._(cents: amount, currency: currency);
    });
  }

  @override
  List<Object> get props => [_cents, currency];

  @override
  bool? get stringify => true;
}
