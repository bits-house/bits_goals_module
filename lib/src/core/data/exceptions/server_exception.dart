import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';

class ServerException implements Exception {
  final ServerExceptionReason reason;
  final String? message;

  ServerException({
    required this.reason,
    this.message,
  });
}
