import 'package:bits_goals_module/src/core/application/exceptions/real_time_service_exception.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';

abstract class RealTimeService {
  /// Gets the current year from an external time source.
  ///
  /// Throws:
  /// - [RealTimeServiceException]
  ///
  /// Returns:
  /// - The current year as a [Year] value object.
  Future<Year> getCurrentYear();
}
