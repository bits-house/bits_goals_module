import 'package:bits_goals_module/src/core/data/extensions/map_parsing_extension.dart';
import 'package:equatable/equatable.dart';

class AnnualRevenueGoalMetaRemoteSchemaV1 {
  static const String year = 'year';
}

class AnnualRevenueGoalMetaRemoteModel extends Equatable {
  final int year;

  const AnnualRevenueGoalMetaRemoteModel({
    required this.year,
  });

  // ===========================================================================
  // FROM MAP (Parsing)
  // ===========================================================================

  factory AnnualRevenueGoalMetaRemoteModel.fromMap(Map<String, dynamic> map) {
    try {
      final yearInt = map.getInt(
        key: AnnualRevenueGoalMetaRemoteSchemaV1.year,
      );

      return AnnualRevenueGoalMetaRemoteModel(
        year: yearInt,
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
    };
  }

  // ===========================================================================
  // EQUATABLE
  // ===========================================================================

  @override
  List<Object?> get props => [year];

  @override
  bool get stringify => true;
}
