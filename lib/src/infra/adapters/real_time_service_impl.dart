import 'dart:async';
import 'dart:io';

import 'package:bits_goals_module/src/core/application/exceptions/real_time_service_exception.dart';
import 'package:bits_goals_module/src/core/application/ports/infra/real_time_service.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:http/http.dart' as http;
import 'package:ntp/ntp.dart';

/// For NTP.now function, to test fallback behavior.
typedef NtpRunner = Future<DateTime> Function();

/// Infra implementation of [RealTimeService].
class RealTimeServiceImpl implements RealTimeService {
  final http.Client client;
  final NtpRunner _ntpRunner;

  RealTimeServiceImpl({
    required this.client,
    NtpRunner? ntpRunner,
  }) : _ntpRunner = ntpRunner ?? NTP.now;

  @override
  Future<Year> getCurrentYear() async {
    try {
      // 1. PRIMARY ATTEMPT: NTP
      final DateTime ntpTime = await _ntpRunner().timeout(
        const Duration(seconds: 3),
      );
      final localDateTime = ntpTime.toLocal();
      return Year.fromInt(localDateTime.year);
    } catch (_) {
      // 2. FALLBACK: HTTP API
      return _getFromBrasilApi();
    }
  }

  Future<Year> _getFromBrasilApi() async {
    final response = await client
        .head(Uri.parse('https://brasilapi.com.br/api/ddd/v1/11'))
        .timeout(const Duration(seconds: 5));

    if (response.headers['date'] != null) {
      final dateHeader = response.headers['date']!;
      final serverTime = HttpDate.parse(dateHeader);
      final localDateTime = serverTime.toLocal();
      return Year.fromInt(localDateTime.year);
    }

    throw const RealTimeServiceException(
      'Failed to retrieve time from Brasil API: Missing Date header',
    );
  }
}
