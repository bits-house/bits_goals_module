import 'package:bits_goals_module/src/core/data/extensions/map_parsing_extension.dart';
import 'package:equatable/equatable.dart';

class AnnualRevenueGoalMetaRemoteSchemaV1 {
  static const String year = 'year';
  static const String version = 'schema_version';
}

class AnnualRevenueGoalMetaRemoteModel extends Equatable {
  final int year;
  final int schemaVersion;

  // ===========================================================================
  // CONSTRUCTORS
  // ===========================================================================

  factory AnnualRevenueGoalMetaRemoteModel.fromYear(int year) {
    return AnnualRevenueGoalMetaRemoteModel._(
      year: year,
      schemaVersion: 1,
    );
  }

  const AnnualRevenueGoalMetaRemoteModel._({
    required this.year,
    required this.schemaVersion,
  });

  factory AnnualRevenueGoalMetaRemoteModel.fromMap(Map<String, dynamic> map) {
    try {
      final yearInt = map.getInt(
        key: AnnualRevenueGoalMetaRemoteSchemaV1.year,
      );

      final schemaVersionInt = map.getInt(
        key: AnnualRevenueGoalMetaRemoteSchemaV1.version,
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
      AnnualRevenueGoalMetaRemoteSchemaV1.year: year,
      AnnualRevenueGoalMetaRemoteSchemaV1.version: schemaVersion,
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
