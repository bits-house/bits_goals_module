import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';

abstract class RealTimeService {
  /// Gets the current year from an external time source.
  Future<Year> getCurrentYear();
}
