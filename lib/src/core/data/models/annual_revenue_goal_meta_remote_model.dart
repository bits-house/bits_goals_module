import 'package:bits_goals_module/src/core/data/extensions/map_parsing_extension.dart';
import 'package:equatable/equatable.dart';

class AnnualRevenueGoalMetaRemoteSchemaV1 {
  static const int version = 1;

  static const String year = 'year';
  static const String schemaVersion = 'schema_version';
}

typedef AnnualRevenueGoalMetaCurrentSchema
    = AnnualRevenueGoalMetaRemoteSchemaV1;

class AnnualRevenueGoalMetaRemoteModel extends Equatable {
  final int year;
  final int schemaVersion;

  // ===========================================================================
  // CONSTRUCTORS
  // ===========================================================================

  factory AnnualRevenueGoalMetaRemoteModel.fromYear(int year) {
    return AnnualRevenueGoalMetaRemoteModel._(
      year: year,
      schemaVersion: AnnualRevenueGoalMetaCurrentSchema.version,
    );
  }

  const AnnualRevenueGoalMetaRemoteModel._({
    required this.year,
    required this.schemaVersion,
  });

  factory AnnualRevenueGoalMetaRemoteModel.fromMap(Map<String, dynamic> map) {
    try {
      final yearInt = map.getInt(
        key: AnnualRevenueGoalMetaCurrentSchema.year,
      );

      final schemaVersionInt = map.getInt(
        key: AnnualRevenueGoalMetaCurrentSchema.schemaVersion,
      );

      return AnnualRevenueGoalMetaRemoteModel._(
        year: yearInt,
        schemaVersion: schemaVersionInt,
      );
    } catch (e) {
      throw const FormatException('Invalid AnnualRevenueGoalMetaRemoteModel');
    }
  }

  // ===========================================================================
  // TO MAP (Serialization)
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      AnnualRevenueGoalMetaCurrentSchema.year: year,
      AnnualRevenueGoalMetaCurrentSchema.schemaVersion: schemaVersion,
    };
  }

  // ===========================================================================
  // EQUATABLE
  // ===========================================================================

  @override
  List<Object?> get props => [year, schemaVersion];

  @override
  bool get stringify => true;
}
