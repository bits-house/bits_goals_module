import 'package:bits_goals_module/src/core/data/extensions/map_parsing_extension.dart';
import 'package:bits_goals_module/src/core/domain/entities/monthly_revenue_goal.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/id_uuid_v7.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/money.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/month/month.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:equatable/equatable.dart';

// DO NOT DELETE OR EDIT LEGACY/OLD SCHEMAS AND NAMES.
// create a new version instead
// and ADD LEGACY KEYS IN PARSING EXTENSION.
class MonthlyRevenueGoalRemoteModelSchemaV1 {
  static const String uuidV7 = 'uuid_v7';
  static const String month = 'month';
  static const String year = 'year';
  static const String targetCents = 'target_cents';
  static const String progressCents = 'progress_cents';
  static const String schemaVersion = 'schema_version';
}

class MonthlyRevenueGoalRemoteModel extends Equatable {
  final IdUuidV7 uuidV7;
  final Month month;
  final Year year;
  final Money target;
  final Money progress;
  final int schemaVersion;

  const MonthlyRevenueGoalRemoteModel._({
    required this.uuidV7,
    required this.month,
    required this.year,
    required this.target,
    required this.progress,
    required this.schemaVersion,
  });

  // ===========================================================================
  // FROM ENTITY
  // ===========================================================================

  factory MonthlyRevenueGoalRemoteModel.fromEntity(MonthlyRevenueGoal entity) {
    return MonthlyRevenueGoalRemoteModel._(
      uuidV7: entity.id,
      month: entity.month,
      year: entity.year,
      target: entity.target,
      progress: entity.progress,
      schemaVersion: 1,
    );
  }

  // ===========================================================================
  // FROM MAP (Parsing)
  // ===========================================================================

  factory MonthlyRevenueGoalRemoteModel.fromMap(Map<String, dynamic> map) {
    try {
      final idString = map.getString(
        key: MonthlyRevenueGoalRemoteModelSchemaV1.uuidV7,
      );

      final monthInt = map.getInt(
        key: MonthlyRevenueGoalRemoteModelSchemaV1.month,
      );

      final yearInt = map.getInt(
        key: MonthlyRevenueGoalRemoteModelSchemaV1.year,
      );

      final targetVal = map.getInt(
        key: MonthlyRevenueGoalRemoteModelSchemaV1.targetCents,
      );

      final progressVal = map.getInt(
        key: MonthlyRevenueGoalRemoteModelSchemaV1.progressCents,
      );

      final schemaVer = map.getInt(
        key: MonthlyRevenueGoalRemoteModelSchemaV1.schemaVersion,
        defaultValue: 0,
      );

      return MonthlyRevenueGoalRemoteModel._(
        uuidV7: IdUuidV7.fromString(idString),
        month: Month.fromInt(monthInt),
        year: Year.fromInt(yearInt),
        target: Money.fromCents(targetVal),
        progress: Money.fromCents(progressVal),
        schemaVersion: schemaVer,
      );
    } catch (e) {
      throw FormatException(
          'Exception while parsing MonthlyRevenueGoalRemoteModel fromMap: $e');
    }
  }

  // ===========================================================================
  // TO MAP (Serialization)
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      MonthlyRevenueGoalRemoteModelSchemaV1.uuidV7: uuidV7.value,
      MonthlyRevenueGoalRemoteModelSchemaV1.month: month.value,
      MonthlyRevenueGoalRemoteModelSchemaV1.year: year.value,
      MonthlyRevenueGoalRemoteModelSchemaV1.targetCents: target.cents,
      MonthlyRevenueGoalRemoteModelSchemaV1.progressCents: progress.cents,
      MonthlyRevenueGoalRemoteModelSchemaV1.schemaVersion: schemaVersion,
    };
  }

  // ===========================================================================
  // EQUATABLE
  // ===========================================================================

  @override
  List<Object?> get props => [
        uuidV7,
        month,
        year,
        target,
        progress,
        schemaVersion,
      ];

  @override
  bool get stringify => true;
}
