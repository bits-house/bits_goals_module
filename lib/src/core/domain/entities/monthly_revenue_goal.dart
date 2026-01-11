import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/monthly_revenue_goal/monthly_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:equatable/equatable.dart';

/// Represents a global monthly revenue goal.
class MonthlyRevenueGoal extends Equatable {
  final IdUuidV7 _id;

  /// The month this goal is set for.
  /// Natural key for the aggregate.
  final Month _month;

  /// The year this goal is set for.
  /// Natural key for the aggregate.
  final Year _year;

  /// The revenue goal amount for this month.
  final Money _target;

  /// Progress is the sum of all valid revenue in sales orders for the
  final Money _progress;

  // =========================
  // Constructors
  // =========================

  /// Private constructor to enforce invariants
  const MonthlyRevenueGoal._({
    required IdUuidV7 id,
    required Month month,
    required Year year,
    required Money target,
    required Money progress,
  })  : _target = target,
        _progress = progress,
        _month = month,
        _year = year,
        _id = id;

  /// Factory constructor that validates all domain invariants
  factory MonthlyRevenueGoal.create({
    required Month month,
    required Year year,
    required Money target,
    Money? progress,
    IdUuidV7? id,
  }) {
    final uid = id ?? IdUuidV7.generate();

    _validateGoalTarget(target);

    final prog = progress ?? Money.fromCents(0);
    return MonthlyRevenueGoal._(
      id: uid,
      month: month,
      year: year,
      target: target,
      progress: prog,
    );
  }

  // =========================
  // Getters
  // =========================

  Money get target => Money.fromCents(_target.cents);

  Money get progress => Money.fromCents(_progress.cents);

  IdUuidV7 get id => IdUuidV7.fromString(_id.value);

  Month get month => Month.fromInt(_month.value);

  Year get year => Year.fromInt(_year.value);

  // =========================
  // Domain Validations
  // =========================

  static void _validateGoalTarget(Money target) {
    final bool isZeroOrNegativeTarget = target.cents <= 0;

    if (isZeroOrNegativeTarget) {
      throw const MonthlyRevenueGoalFailure(
        MonthlyRevenueGoalFailureReason.zeroOrNegativeTarget,
      );
    }
  }

  // =========================
  // Equatable Overrides
  // =========================

  @override
  List<Object?> get props => [
        _id,
        _month,
        _year,
        _target,
        _progress,
      ];

  @override
  bool get stringify => true;
}
