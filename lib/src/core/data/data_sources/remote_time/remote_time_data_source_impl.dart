import 'dart:convert';
import 'dart:async'; // Required for TimeoutException
import 'package:http/http.dart' as http;
import 'package:ntp/ntp.dart';
import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source.dart';

// TODO: Refactor exception handling
class RemoteTimeException implements Exception {
  final String message;
  RemoteTimeException(this.message);

  @override
  String toString() => 'RemoteTimeException: $message';
}

// TODO: Refactor NtpRunner typedef
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
        const Duration(seconds: 4),
      );
      return ntpTime.year;
    } catch (e) {
      // 2. FALLBACK: HTTP API
      return _getYearFromPublicApi();
    }
  }

  Future<int> _getYearFromPublicApi() async {
    try {
      final response = await client
          .get(
            Uri.parse('http://worldtimeapi.org/api/timezone/Etc/UTC'),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dateTime = DateTime.parse(data['datetime']);
        return dateTime.year;
      } else {
        throw RemoteTimeException(
            'API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw RemoteTimeException('Failed to retrieve remote time: $e');
    }
  }
}
