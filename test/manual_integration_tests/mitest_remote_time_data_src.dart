// ignore_for_file: avoid_print

import 'dart:io';
import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source_impl.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:ntp/ntp.dart';

// --- HELPERS ---
class _SpyDateClient extends http.BaseClient {
  final http.Client _inner;
  _SpyDateClient(this._inner);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.headers.containsKey('date')) {
      print('URL Requested: ${request.url}');
      final localDateTime = HttpDate.parse(response.headers['date']!).toLocal();
      print('Date from Server (toLocal): $localDateTime\n');
    }
    return response;
  }
}

// Necessary to prevent HandshakeException when calling HTTPS (Brasil API) from a local script.
http.Client _createInsecureClient() {
  final ioClient = HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);

  final insecureClient = IOClient(ioClient);
  return _SpyDateClient(insecureClient);
}

Future<DateTime> Function() _createSpyNtpRunner() {
  return () async {
    // Real NTP call
    final date = await NTP.now();
    print('Date from NTP (toLocal): ${date.toLocal()}\n');
    return date;
  };
}

void main() async {
  print('STARTING REMOTE TIME DATA SOURCE TESTS\n');

  final client = _createInsecureClient();

  // ---------------------------------------------------------
  // TEST 1: PRIMARY SOURCE (NTP)
  // Expectation: Should use NTP and not even call the HTTP Client.
  // ---------------------------------------------------------
  print('TEST 1: Happy Path (NTP Working)');
  try {
    final dataSource = RemoteTimeDataSourceImpl(
      client: client,
      ntpRunner: _createSpyNtpRunner(),
    );

    final stopwatch = Stopwatch()..start();
    final year = await dataSource.getCurrentYear();
    stopwatch.stop();

    print('   Result: $year');
    print('   Time: ${stopwatch.elapsedMilliseconds}ms');
    print('   SUCCESS (Expected)\n');
  } catch (e) {
    print('   FAIL: $e\n');
  }

  // ---------------------------------------------------------
  // TEST 2: FALLBACK SOURCE (Brasil API)
  // Expectation: NTP fails -> System calls Brasil API successfully.
  // ---------------------------------------------------------
  print('TEST 2: Fallback (NTP Failure -> Brasil API)');
  try {
    // Force NTP to fail by injecting a throwing function
    final dataSource = RemoteTimeDataSourceImpl(
      client: client,
      ntpRunner: () async => throw Exception('Simulated: NTP Blocked'),
    );

    final stopwatch = Stopwatch()..start();
    final year = await dataSource.getCurrentYear();
    stopwatch.stop();

    print('   Result: $year');
    print('   Time: ${stopwatch.elapsedMilliseconds}ms');
    print('   SUCCESS (Expected)\n');
  } catch (e) {
    print('   FAIL: $e\n');
  } finally {
    client.close();
  }

  print('REMOTE TIME DATA SOURCE TESTS COMPLETED');
}
