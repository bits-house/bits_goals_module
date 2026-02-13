import 'package:bits_goals_module/src/core/application/dtos/action_log_metadata_dto.dart';

/// Application port for gathering execution/request context for logging.
abstract class ActionLogMetadataProvider {
  Future<ActionLogMetadataDto> get metadata;
}
