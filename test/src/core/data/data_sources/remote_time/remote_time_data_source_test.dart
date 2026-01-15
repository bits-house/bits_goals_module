import 'dart:async';
import 'dart:convert';

import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late RemoteTimeDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
  });

  // Helper to simulate the WorldTimeAPI JSON response
  String apiResponseBody(String datetime) {
    return jsonEncode({
      "abbreviation": "UTC",
      "datetime": datetime, // e.g., "2026-01-15T10:00:00.000+00:00"
      "utc_offset": "+00:00"
    });
  }

  group('RemoteTimeDataSourceImpl', () {
    const tYear = 2026;
    final tDate = DateTime(tYear, 1, 1);

    test('should return year from NTP when NTP call is successful', () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        // Mocking NTP via the typedef injection
        ntpRunner: () async => tDate,
      );

      // Act
      final result = await dataSource.getCurrentYear();

      // Assert
      expect(result, tYear);
      // Verify HTTP client was NEVER called (optimization check)
      verifyNever(() => mockHttpClient.get(any()));
    });

    test('should return year from Public API when NTP fails (Fallback)',
        () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        // Mocking NTP failure
        ntpRunner: () async => throw Exception('NTP Timeout'),
      );

      // Stubbing HTTP Client to return success
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(
            apiResponseBody("2025-10-10T10:00:00.000+00:00"), 200),
      );

      // Act
      final result = await dataSource.getCurrentYear();

      // Assert
      expect(result, 2025);
      verify(() => mockHttpClient.get(
            Uri.parse('http://worldtimeapi.org/api/timezone/Etc/UTC'),
          )).called(1);
    });

    test(
        'should throw RemoteTimeException when NTP fails AND API returns non-200',
        () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        ntpRunner: () async => throw Exception('NTP failed'),
      );

      // Stubbing HTTP Client to return 500 Error
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      // Act & Assert
      final call = dataSource.getCurrentYear;

      await expectLater(() => call(), throwsA(isA<RemoteTimeException>()));

      verify(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test(
        'should throw RemoteTimeException when NTP fails AND API throws Exception',
        () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        ntpRunner: () async => throw Exception('NTP failed'),
      );

      // Stubbing HTTP Client to throw exception
      when(() => mockHttpClient.get(any())).thenThrow(Exception('No Internet'));

      // Act & Assert
      final call = dataSource.getCurrentYear;

      expect(() => call(), throwsA(isA<RemoteTimeException>()));
    });

    test(
        'should throw RemoteTimeException when NTP fails AND API returns malformed JSON',
        () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        ntpRunner: () async => throw Exception('NTP failed'),
      );

      // Stubbing HTTP Client to return 200 but garbage body
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('{ "wrong_key": "data" }', 200),
      );

      // Act & Assert
      final call = dataSource.getCurrentYear;

      // This will fail inside _getYearFromPublicApi during DateTime.parse or map access
      // and should be caught and rethrown as RemoteTimeException
      expect(() => call(), throwsA(isA<RemoteTimeException>()));
    });

    test('should handle NTP timeout correctly by switching to API', () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        // Simulate a timeout exception specifically
        ntpRunner: () async => throw TimeoutException('NTP timed out'),
      );

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(apiResponseBody("2024-01-01T00:00:00"), 200),
      );

      // Act
      final result = await dataSource.getCurrentYear();

      // Assert
      expect(result, 2024);
    });
  });
}
