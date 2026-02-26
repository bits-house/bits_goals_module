import 'dart:async';
import 'dart:io';

import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:bits_goals_module/src/infra/adapters/real_time_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late RealTimeServiceImpl realTime;
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

  group('RealTimeServiceImpl', () {
    final tYear = Year.fromInt(2026);
    final tDate = DateTime(tYear.value, 1, 1);

    test('should return year from NTP when NTP call is successful', () async {
      // Arrange
      realTime = RealTimeServiceImpl(
        client: mockHttpClient,
        // Mocking NTP via the typedef injection
        ntpRunner: () async => tDate,
      );

      // Act
      final result = await realTime.getCurrentYear();

      // Assert
      expect(result, tYear);
      // Verify HTTP client was NEVER called (optimization check)
      verifyNever(() => mockHttpClient.get(any()));
    });

    test('should return year from Brasil API when NTP fails (Fallback)',
        () async {
      // Arrange
      realTime = RealTimeServiceImpl(
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
      final result = await realTime.getCurrentYear();

      // Assert
      expect(result, tYear);
      verify(() => mockHttpClient.head(
            Uri.parse('https://brasilapi.com.br/api/ddd/v1/11'),
          )).called(1);
    });

    test('should throw Exception when NTP fails AND API returns non-200',
        () async {
      // Arrange
      realTime = RealTimeServiceImpl(
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
      final call = realTime.getCurrentYear;

      // Note: Make sure RealTimeServiceException is exported or imported correctly
      await expectLater(() => call(), throwsA(isA<Exception>()));
    });

    test(
        'should throw Exception when NTP fails AND API response is missing Date header',
        () async {
      // Arrange
      realTime = RealTimeServiceImpl(
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
      final call = realTime.getCurrentYear;

      expect(() => call(), throwsA(isA<Exception>()));
    });

    test('should handle NTP timeout correctly by switching to API', () async {
      // Arrange
      realTime = RealTimeServiceImpl(
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
      final result = await realTime.getCurrentYear();

      // Assert
      expect(result, Year.fromInt(2024));
    });
  });
}
