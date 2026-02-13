import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';

class CreateAnnualRevenueGoalParams {
  final Year year;
  final Money annualRevenueTarget;

  const CreateAnnualRevenueGoalParams({
    required this.year,
    required this.annualRevenueTarget,
  });
}
