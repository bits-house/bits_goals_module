import 'dart:async';
import 'dart:io';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception_reason.dart';
import 'package:http/http.dart' as http;
import 'package:ntp/ntp.dart';
import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source.dart';

/// For NTP.now function, to test fallback behavior.
typedef NtpRunner = Future<DateTime> Function();

class RemoteTimeDataSourceImpl implements RemoteTimeDataSource {
  final http.Client client;
  final NtpRunner _ntpRunner;

  RemoteTimeDataSourceImpl({
    required this.client,
    NtpRunner? ntpRunner,
  }) : _ntpRunner = ntpRunner ?? NTP.now;

  @override
  Future<int> getCurrentYear() async {
    try {
      // 1. PRIMARY ATTEMPT: NTP
      final DateTime ntpTime = await _ntpRunner().timeout(
        const Duration(seconds: 3),
      );
      return ntpTime.toLocal().year;
    } catch (e) {
      // 2. FALLBACK: HTTP API
      return _getFromBrasilApi();
    }
  }

  Future<int> _getFromBrasilApi() async {
    final response = await client
        .head(Uri.parse('https://brasilapi.com.br/api/ddd/v1/11'))
        .timeout(const Duration(seconds: 5));

    if (response.headers['date'] != null) {
      final dateHeader = response.headers['date']!;
      final serverTime = HttpDate.parse(dateHeader);
      final localDateTime = serverTime.toLocal();
      return localDateTime.year;
    } else {
      throw const ServerException(
        reason: ServerExceptionReason.connectionError,
        error: 'Brasil API did not return a Date header.',
      );
    }
  }
}
