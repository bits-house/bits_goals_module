import 'dart:async';
import 'dart:io';

import 'package:bits_goals_module/src/core/data/data_sources/remote_time/remote_time_data_source_impl.dart';
import 'package:bits_goals_module/src/core/data/exceptions/server_exception.dart';
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

  // Helper to create Brasil API HEAD response with Date header
  http.Response brasilApiResponse(String rfc1123Date, {int statusCode = 200}) {
    return http.Response(
      '', // Body is always empty in HEAD
      statusCode,
      headers: {
        HttpHeaders.dateHeader:
            rfc1123Date, // e.g., "Thu, 15 Jan 2026 19:00:00 GMT"
      },
    );
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

    test('should return year from Brasil API when NTP fails (Fallback)',
        () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        ntpRunner: () async => throw Exception('NTP Timeout'),
      );

      // Stubbing HTTP Client to return a successful HEAD response with a Date header
      // RFC-1123 Format: "Thu, 15 Jan 2026 19:00:00 GMT"
      when(() => mockHttpClient.head(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => brasilApiResponse("Thu, 15 Jan 2026 19:00:00 GMT"),
      );

      // Act
      final result = await dataSource.getCurrentYear();

      // Assert
      expect(result, 2026);
      verify(() => mockHttpClient.head(
            Uri.parse('https://brasilapi.com.br/api/ddd/v1/11'),
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
      when(() => mockHttpClient.head(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response('', 500),
      );

      // Act & Assert
      final call = dataSource.getCurrentYear;

      // Note: Make sure RemoteTimeException is exported or imported correctly
      await expectLater(() => call(), throwsA(isA<ServerException>()));
    });

    test(
        'should throw RemoteTimeException when NTP fails AND API response is missing Date header',
        () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        ntpRunner: () async => throw Exception('NTP failed'),
      );

      // Stubbing HTTP Client to return 200 OK, but NO headers
      when(() => mockHttpClient.head(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response('', 200, headers: {}), // Empty headers
      );

      // Act & Assert
      final call = dataSource.getCurrentYear;

      expect(() => call(), throwsA(isA<ServerException>()));
    });

    test('should handle NTP timeout correctly by switching to API', () async {
      // Arrange
      dataSource = RemoteTimeDataSourceImpl(
        client: mockHttpClient,
        ntpRunner: () async => throw TimeoutException('NTP timed out'),
      );

      when(() => mockHttpClient.head(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => brasilApiResponse("Mon, 01 Jan 2024 10:00:00 GMT"),
      );

      // Act
      final result = await dataSource.getCurrentYear();

      // Assert
      expect(result, 2024);
    });
  });
}
