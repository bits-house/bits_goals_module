import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bits_goals_module/src/infra/platform/network_info_impl.dart';

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

void main() {
  late NetworkInfoImpl networkInfo;
  late MockTcpHelper mockTcp;

  const defaultDomainsCount = 5;

  setUpAll(() {
    // Required for Mocktail to handle 'any()' with custom types like Duration.
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockTcp = MockTcpHelper();
    // Default injection for testing logic without hitting the real network.
    networkInfo = NetworkInfoImpl(tcpChecker: mockTcp.check);
  });

  group('NetworkInfoImpl (Strategy & Logic) |', () {
    // =========================================================================
    // 1. BASIC CONNECTIVITY
    // =========================================================================

    test('Should return TRUE if at least one domain connects successfully',
        () async {
      // Arrange
      when(() => mockTcp.check(any(), any(), any()))
          .thenAnswer((_) async => true);

      // Act
      final result = await networkInfo.isConnected;

      // Assert
      expect(result, isTrue);
    });

    test('Should return FALSE if ALL domains fail to connect', () async {
      // Arrange
      when(() => mockTcp.check(any(), any(), any()))
          .thenAnswer((_) async => false);

      // Act
      final result = await networkInfo.isConnected;

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
      final result = await networkInfo.isConnected;
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
      await networkInfo.isConnected; // Call 1 (Triggers network check)
      await networkInfo.isConnected; // Call 2 (Returns cached value)
      await networkInfo.isConnected; // Call 3 (Returns cached value)

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
        networkInfo.isConnected,
        networkInfo.isConnected,
        networkInfo.isConnected,
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
      final emptyNetworkInfo = NetworkInfoImpl(domains: []);

      // Act
      final result = await emptyNetworkInfo.isConnected;

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
      final result = await networkInfo.isConnected;
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

  group('NetworkInfoImpl (Implementation Coverage) |', () {
    test('Should cover _defaultTcpCheck SUCCESS path using IOOverrides',
        () async {
      final mockSocket = MockSocket();
      when(() => mockSocket.destroy()).thenReturn(null);

      await IOOverrides.runZoned(() async {
        // Instantiate without mocking the checker to force the static method.
        final realImpl = NetworkInfoImpl(domains: ['google.com']);

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
        final realImpl = NetworkInfoImpl(domains: ['google.com']);

        final result = await realImpl.isConnected;

        expect(result, isFalse);
      }, socketConnect: (host, port,
          {sourceAddress, int sourcePort = 0, timeout}) {
        throw const SocketException('Simulated Network Unreachable');
      });
    });
  });
}
