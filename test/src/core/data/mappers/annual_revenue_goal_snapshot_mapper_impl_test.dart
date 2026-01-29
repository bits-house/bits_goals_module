import 'package:bits_goals_module/src/core/data/mappers/annual_revenue_goal_mapper_impl.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AnnualRevenueGoalMapperImpl();

  AnnualRevenueGoal createValidAnnualGoal({
    int yearValue = 2030,
    int monthlyTargetCents = 10000,
  }) {
    final year = Year.fromInt(yearValue);

    final goals = List.generate(12, (index) {
      return MonthlyRevenueGoal.reconstruct(
        id: IdUuidV7.generate(),
        year: year,
        month: Month.fromInt(index + 1),
        target: Money.fromCents(monthlyTargetCents),
        progress: Money.fromCents(0),
      );
    });

    return AnnualRevenueGoal.build(year: year, monthlyGoals: goals);
  }

  group('AnnualRevenueGoalMapperImpl |', () {
    test('should map all required top-level keys', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);

      expect(map.containsKey('year'), isTrue);
      expect(map.containsKey('monthly_goals'), isTrue);
      expect(map.containsKey('total_annual_target_cents'), isTrue);
    });

    test('should map primitive values correctly (year and total target)', () {
      const monthlyTargetCents = 5000;
      final entity = createValidAnnualGoal(
        yearValue: 2025,
        monthlyTargetCents: monthlyTargetCents,
      );

      final map = mapper.map(entity);

      expect(map['year'], equals(2025));
      expect(map['total_annual_target_cents'], equals(monthlyTargetCents * 12));
    });

    test('should recursively map all MonthlyRevenueGoals', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);
      final goalsList = map['monthly_goals'] as List;

      expect(goalsList.length, equals(12));
      for (int i = 0; i < 12; i++) {
        final goalMap = goalsList[i] as Map<String, dynamic>;
        expect(goalMap['month'], equals(i + 1));
      }
    });

    test('should maintain correct data types in Map structure', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);

      expect(map['year'], isA<int>());
      expect(map['total_annual_target_cents'], isA<int>());
      expect(map['monthly_goals'], isA<List>());

      final firstGoal = (map['monthly_goals'] as List).first as Map;
      expect(firstGoal['id'], isA<String>());
      expect(firstGoal['month'], isA<int>());
      expect(firstGoal['year'], isA<int>());
      expect(firstGoal['target_cents'], isA<int>());
      expect(firstGoal['progress_cents'], isA<int>());
    });

    test('should be immutable (modifications do not affect entity)', () {
      final entity = createValidAnnualGoal(yearValue: 2030);

      final map = mapper.map(entity);
      map['year'] = 1999;
      final goals = map['monthly_goals'] as List;
      final firstGoal = goals.first as Map<String, dynamic>;
      firstGoal['month'] = 99;

      expect(entity.year.value, equals(2030));
      expect(entity.monthlyGoals.length, equals(12));
    });
  });
}
