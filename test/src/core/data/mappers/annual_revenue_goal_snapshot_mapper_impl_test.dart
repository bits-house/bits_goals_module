import 'package:bits_goals_module/src/core/data/mappers/annual_revenue_goal_action_log_mapper_impl.dart';
import 'package:bits_goals_module/src/core/data/models/annual_revenue_goal_meta_remote_model.dart';
import 'package:bits_goals_module/src/core/data/models/monthly_revenue_goal_remote_model.dart';
import 'package:bits_goals_module/src/core/domain/entities/annual_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AnnualRevenueGoalActionLogMapperImpl();

  AnnualRevenueGoal createValidAnnualGoal({
    int yearValue = 2030,
    int monthlyTargetCents = 10000,
  }) {
    final currency = Currency.fromISO4217('BRL');
    final year = Year.fromInt(yearValue);

    final goals = List.generate(12, (index) {
      return MonthlyRevenueGoal.reconstruct(
        id: IdUuidV7.generate(),
        year: year,
        month: Month.fromInt(index + 1),
        target: Money.fromCents(
          cents: monthlyTargetCents,
          currency: currency,
        ),
        progress: Money.fromCents(
          cents: 0,
          currency: currency,
        ),
      );
    });

    return AnnualRevenueGoal.build(year: year, monthlyGoals: goals);
  }

  group('AnnualRevenueGoalActionLogMapperImpl |', () {
    test('should map all required top-level keys', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);

      expect(
        map.containsKey(AnnualRevenueGoalMetaCurrentSchema.year),
        isTrue,
      );
      expect(map.containsKey('monthly_goals'), isTrue);
    });

    test('should map primitive values correctly (year)', () {
      const monthlyTargetCents = 5000;
      final entity = createValidAnnualGoal(
        yearValue: 2025,
        monthlyTargetCents: monthlyTargetCents,
      );

      final map = mapper.map(entity);

      expect(map[AnnualRevenueGoalMetaCurrentSchema.year], equals(2025));
    });

    test('should recursively map all MonthlyRevenueGoals', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);
      final goalsList = map['monthly_goals'] as List;

      expect(goalsList.length, equals(12));
      for (int i = 0; i < 12; i++) {
        final goalMap = goalsList[i] as Map<String, dynamic>;
        expect(
          goalMap[MonthlyRevenueGoalRemoteSchemaV1.month],
          equals(i + 1),
        );
        expect(
          goalMap[MonthlyRevenueGoalRemoteSchemaV1.schemaVersion],
          equals(1),
        );
      }
    });

    test('should include schema version for monthly goals', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);
      final firstGoal = (map['monthly_goals'] as List).first as Map;

      expect(
        firstGoal[MonthlyRevenueGoalRemoteSchemaV1.schemaVersion],
        equals(1),
      );
    });

    test('should maintain correct data types in Map structure', () {
      final entity = createValidAnnualGoal();

      final map = mapper.map(entity);

      expect(map[AnnualRevenueGoalMetaCurrentSchema.year], isA<int>());
      expect(map['monthly_goals'], isA<List>());

      final firstGoal = (map['monthly_goals'] as List).first as Map;
      expect(firstGoal[MonthlyRevenueGoalRemoteSchemaV1.uuidV7], isA<String>());
      expect(firstGoal[MonthlyRevenueGoalRemoteSchemaV1.month], isA<int>());
      expect(firstGoal[MonthlyRevenueGoalRemoteSchemaV1.year], isA<int>());
      expect(
        firstGoal[MonthlyRevenueGoalRemoteSchemaV1.targetCents],
        isA<int>(),
      );
      expect(
        firstGoal[MonthlyRevenueGoalRemoteSchemaV1.progressCents],
        isA<int>(),
      );
      expect(
        firstGoal[MonthlyRevenueGoalRemoteSchemaV1.schemaVersion],
        isA<int>(),
      );
    });

    test('should be immutable (modifications do not affect entity)', () {
      final entity = createValidAnnualGoal(yearValue: 2030);

      final map = mapper.map(entity);
      map[AnnualRevenueGoalMetaCurrentSchema.year] = 1999;
      final goals = map['monthly_goals'] as List;
      final firstGoal = goals.first as Map<String, dynamic>;
      firstGoal[MonthlyRevenueGoalRemoteSchemaV1.month] = 99;

      expect(entity.year.value, equals(2030));
      expect(entity.monthlyGoals.length, equals(12));
    });
  });
}
