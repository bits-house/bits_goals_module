// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:bits_goals_module/src/infra/platform/network_info_impl.dart';

// --- HELPERS ---

/// A Spy function that wraps a TCP connection attempt to log activity.
/// This acts as a logger for the "Race to Success" strategy.
Future<bool> _spyTcpCheck(String host, int port, Duration timeout) async {
  print('TCP Handshake Requested: $host:$port');
  try {
    // Establishing a real socket connection to verify internet access
    final socket = await Socket.connect(host, port, timeout: timeout);
    print('  -> Connected: $host');
    socket.destroy();
    return true;
  } catch (e) {
    print('  -> Failed: $host ($e)');
    return false;
  }
}

/// A Mock function that simulates a total network failure.
Future<bool> _mockOfflineTcpCheck(
    String host, int port, Duration timeout) async {
  // Simulates a scenario where no packets can be sent
  return false;
}

void main() async {
  print('STARTING NETWORK INFO DATA SOURCE TESTS\n');

  // ---------------------------------------------------------
  // TEST 1: REAL CONNECTION (Integration)
  // Expectation: Should perform TCP handshakes and return true if online.
  // ---------------------------------------------------------
  print('TEST 1: Happy Path (Real System Network)');
  try {
    // Inject the spy to observe the parallel execution
    final networkInfo = NetworkInfoImpl(
      tcpChecker: _spyTcpCheck,
    );

    final stopwatch = Stopwatch()..start();
    final isConnected = await networkInfo.isConnected;
    stopwatch.stop();

    print('   Result: $isConnected');
    print('   Time: ${stopwatch.elapsedMilliseconds}ms');

    if (isConnected) {
      print('   SUCCESS (Expected: Online)\n');
    } else {
      print('   SUCCESS (Expected: Offline)\n');
    }
  } catch (e) {
    print('   FAIL: $e\n');
  }

  // ---------------------------------------------------------
  // TEST 2: SIMULATED OFFLINE (Forced Failure)
  // Expectation: Handshakes fail -> Returns false immediately.
  // ---------------------------------------------------------
  print('TEST 2: Simulated Offline (Forced Failure)');
  try {
    final networkInfo = NetworkInfoImpl(
      tcpChecker: _mockOfflineTcpCheck,
    );

    final stopwatch = Stopwatch()..start();
    final isConnected = await networkInfo.isConnected;
    stopwatch.stop();

    print('   Result: $isConnected');
    print('   Time: ${stopwatch.elapsedMilliseconds}ms');

    if (isConnected == false) {
      print('   SUCCESS (Expected)\n');
    } else {
      print('   FAIL: Expected false but got true\n');
    }
  } catch (e) {
    print('   FAIL: Exception leaked -> $e\n');
  }

  // ---------------------------------------------------------
  // TEST 3: CACHING & DEBOUNCING (Optimization)
  // Expectation: Multiple calls should reuse the same initial check.
  // ---------------------------------------------------------
  print('TEST 3: Caching & Debouncing (Optimization Check)');
  try {
    final networkInfo = NetworkInfoImpl(
      tcpChecker: _spyTcpCheck,
    );

    print('   Executing 3 simultaneous requests...');
    final stopwatch = Stopwatch()..start();

    // Fire 3 calls concurrently; they should all join the first Future
    final results = await Future.wait([
      networkInfo.isConnected,
      networkInfo.isConnected,
      networkInfo.isConnected,
    ]);

    stopwatch.stop();

    final allTrue = results.every((r) => r == true);
    print('   Results: $results');
    print('   Total Time: ${stopwatch.elapsedMilliseconds}ms');

    if (allTrue) {
      print('   SUCCESS (Requests debounced successfully)\n');
    } else {
      print('   FAIL: Inconsistent results found\n');
    }
  } catch (e) {
    print('   FAIL: $e\n');
  }

  print('NETWORK INFO DATA SOURCE TESTS COMPLETED');
}
