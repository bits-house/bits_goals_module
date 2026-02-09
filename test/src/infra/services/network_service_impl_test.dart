import 'dart:convert';
import 'dart:io';

import 'package:bits_goals_module/src/core/application/exceptions/network_service_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bits_goals_module/src/infra/adapters/network_service_impl.dart';

// =============================================================================
// MOCKS & HELPERS
// =============================================================================

/// Helper interface to allow Mocktail to mock the [TcpChecker] typedef.
abstract class TcpHelper {
  Future<bool> check(String host, int port, Duration timeout);
}

class MockTcpHelper extends Mock implements TcpHelper {}

/// Mock for the low-level Socket to verify resource cleanup (destroy).
class MockSocket extends Mock implements Socket {}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class TestHttpOverrides extends HttpOverrides {
  final HttpClient client;

  TestHttpOverrides(this.client);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return client;
  }
}

void main() {
  late NetworkServiceImpl networkService;
  late MockTcpHelper mockTcp;

  const defaultDomainsCount = 5;

  setUpAll(() {
    // Required for Mocktail to handle 'any()' with custom types like Duration.
    registerFallbackValue(Duration.zero);

    registerFallbackValue(Uri.parse('https://fallback.test'));
  });

  setUp(() {
    mockTcp = MockTcpHelper();
    // Default injection for testing logic without hitting the real network.
    networkService = NetworkServiceImpl(tcpChecker: mockTcp.check);
  });

  group('NetworkServiceImpl (Strategy & Logic) |', () {
    // =========================================================================
    // 1. BASIC CONNECTIVITY
    // =========================================================================

    test('Should return TRUE if at least one domain connects successfully',
        () async {
      // Arrange
      when(() => mockTcp.check(any(), any(), any()))
          .thenAnswer((_) async => true);

      // Act
      final result = await networkService.isConnected;

      // Assert
      expect(result, isTrue);
    });

    test('Should return FALSE if ALL domains fail to connect', () async {
      // Arrange
      when(() => mockTcp.check(any(), any(), any()))
          .thenAnswer((_) async => false);

      // Act
      final result = await networkService.isConnected;

      // Assert
      expect(result, isFalse);
      verify(() => mockTcp.check(any(), any(), any()))
          .called(defaultDomainsCount);
    });

    // =========================================================================
    // 2. RACE STRATEGY ("Fastest Wins")
    // =========================================================================

    test('Should return TRUE immediately when the FASTEST domain responds',
        () async {
      // Arrange
      // 1. Setup default failure for all domains.
      when(() => mockTcp.check(any(), any(), any()))
          .thenAnswer((_) async => false);

      // 2. Mock 'google.com' to hang for 10 seconds.
      when(() => mockTcp.check('google.com', any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return true;
      });

      // 3. Mock 'cloudflare.com' to respond in 10ms (The Winner).
      when(() => mockTcp.check('cloudflare.com', any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return true;
      });

      // Act
      final stopwatch = Stopwatch()..start();
      final result = await networkService.isConnected;
      stopwatch.stop();

      // Assert
      expect(result, isTrue);
      // Proves the logic did not wait for the 10s Google check.
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    // =========================================================================
    // 3. PERFORMANCE: CACHING & DEBOUNCING
    // =========================================================================

    test(
        'Should return CACHED result on subsequent calls within validity window',
        () async {
      // Arrange
      when(() => mockTcp.check(any(), any(), any()))
          .thenAnswer((_) async => true);

      // Act
      await networkService.isConnected; // Call 1 (Triggers network check)
      await networkService.isConnected; // Call 2 (Returns cached value)
      await networkService.isConnected; // Call 3 (Returns cached value)

      // Assert
      // Interaction count should stay at 5 (one batch for one network check).
      verify(() => mockTcp.check(any(), any(), any()))
          .called(defaultDomainsCount);
    });

    test('Should DEBOUNCE simultaneous calls into a single execution',
        () async {
      // Arrange
      when(() => mockTcp.check(any(), any(), any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      // Act
      // Fire multiple calls at the same time.
      final results = await Future.wait([
        networkService.isConnected,
        networkService.isConnected,
        networkService.isConnected,
      ]);

      // Assert
      expect(results.every((r) => r == true), isTrue);
      // Verification ensures they all joined the same Future.
      verify(() => mockTcp.check(any(), any(), any()))
          .called(defaultDomainsCount);
    });

    // =========================================================================
    // 4. EDGE CASES & TIMEOUTS
    // =========================================================================

    test('Should return FALSE if domain list is empty', () async {
      // Arrange
      final emptyNetworkService = NetworkServiceImpl(domains: []);

      // Act
      final result = await emptyNetworkService.isConnected;

      // Assert
      expect(result, isFalse);
    });

    test(
        'Should return FALSE if the GLOBAL timeout is reached before any success',
        () async {
      // Arrange
      // Mock all domains to hang forever.
      when(() => mockTcp.check(any(), any(), any())).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return true;
      });

      // Act
      final stopwatch = Stopwatch()..start();
      final result = await networkService.isConnected;
      stopwatch.stop();

      // Assert
      expect(result, isFalse);
      // Ensures the globalTimer (4s) cut the execution short.
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });

  // ===========================================================================
  // GRUPO 2: LOW-LEVEL IMPLEMENTATION COVERAGE (_defaultTcpCheck)
  // ===========================================================================

  group('NetworkServiceImpl (Implementation Coverage) |', () {
    test('Should cover _defaultTcpCheck SUCCESS path using IOOverrides',
        () async {
      final mockSocket = MockSocket();
      when(() => mockSocket.destroy()).thenReturn(null);

      await IOOverrides.runZoned(() async {
        // Instantiate without mocking the checker to force the static method.
        final realImpl = NetworkServiceImpl(domains: ['google.com']);

        final result = await realImpl.isConnected;

        expect(result, isTrue);
        // Verify resource cleanup (socket?.destroy()).
        verify(() => mockSocket.destroy()).called(1);
      }, socketConnect: (host, port,
          {sourceAddress, int sourcePort = 0, timeout}) {
        return Future.value(mockSocket);
      });
    });

    test('Should cover _defaultTcpCheck FAILURE path (SocketException)',
        () async {
      await IOOverrides.runZoned(() async {
        final realImpl = NetworkServiceImpl(domains: ['google.com']);

        final result = await realImpl.isConnected;

        expect(result, isFalse);
      }, socketConnect: (host, port,
          {sourceAddress, int sourcePort = 0, timeout}) {
        throw const SocketException('Simulated Network Unreachable');
      });
    });
  });

  // ===========================================================================
  // GRUPO 3: PUBLIC IP RETRIEVAL (ipAddress)
  // ===========================================================================

  group('ipAddress', () {
    late MockHttpClient httpClient;
    late MockHttpClientRequest request;
    late MockHttpClientResponse response;
    late NetworkServiceImpl service;

    setUp(() {
      httpClient = MockHttpClient();
      request = MockHttpClientRequest();
      response = MockHttpClientResponse();

      service = NetworkServiceImpl(
        ipServices: [
          'https://service1.test',
          'https://service2.test',
        ],
      );
    });

    test('returns IpAddress when first service succeeds', () async {
      // Arrange
      when(() => httpClient.getUrl(any())).thenAnswer((_) async => request);

      when(() => request.close()).thenAnswer((_) async => response);

      when(() => response.statusCode).thenReturn(200);

      when(() => response.transform(utf8.decoder)).thenAnswer(
        (_) => Stream.value('8.8.8.8'),
      );

      HttpOverrides.runZoned(
        () async {
          // Act
          final result = await service.ipAddress;

          // Assert
          expect(result.value, '8.8.8.8');
        },
        createHttpClient: (_) => httpClient,
      );
    });

    test('fails first service and succeeds on second', () async {
      // Arrange
      when(() => httpClient.getUrl(any())).thenAnswer((_) async => request);

      when(() => request.close()).thenThrow(const SocketException('Timeout'));

      when(() => response.statusCode).thenReturn(200);

      when(() => response.transform(utf8.decoder)).thenAnswer(
        (_) => Stream.value('1.1.1.1'),
      );

      var callCount = 0;

      when(() => httpClient.getUrl(any())).thenAnswer((_) async {
        callCount++;
        return request;
      });

      when(() => request.close()).thenAnswer((_) async {
        if (callCount == 1) {
          throw const SocketException('Timeout');
        }
        return response;
      });

      HttpOverrides.runZoned(
        () async {
          // Act
          final result = await service.ipAddress;

          // Assert
          expect(result.value, '1.1.1.1');
          expect(callCount, 2);
        },
        createHttpClient: (_) => httpClient,
      );
    });

    test('throws NetworkServiceException when all services fail', () async {
      // Arrange
      when(() => httpClient.getUrl(any()))
          .thenThrow(const SocketException('No internet'));

      HttpOverrides.runZoned(
        () async {
          // Act & Assert
          expect(
            () => service.ipAddress,
            throwsA(isA<NetworkServiceException>()),
          );
        },
        createHttpClient: (_) => httpClient,
      );
    });
  });
}
