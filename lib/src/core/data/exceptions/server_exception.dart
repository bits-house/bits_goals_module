import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';

class ServerException implements Exception {
  final ServerExceptionReason reason;
  final Object? error;

  const ServerException({
    required this.reason,
    this.error,
  });
}
