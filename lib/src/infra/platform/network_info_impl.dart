import 'dart:async';
import 'dart:io';

import 'package:bits_goals_module/src/infra/platform/network_info.dart';

/// Typedef to allow mocking the TCP check logic.
/// Returns [true] if a TCP handshake to [host]:[port] succeeds.
typedef TcpChecker = Future<bool> Function(
    String host, int port, Duration timeout);

class NetworkInfoImpl implements NetworkInfo {
  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  static const List<String> _defaultReliableDomains = [
    'google.com',
    'cloudflare.com',
    'microsoft.com',
    'apple.com',
    'amazon.com',
  ];

  static const Duration _globalTimeout = Duration(seconds: 4);
  static const Duration _socketTimeout = Duration(seconds: 3);
  static const Duration _cacheValidity = Duration(seconds: 2);

  // ===========================================================================
  // DEPENDENCIES & STATE
  // ===========================================================================

  final TcpChecker _tcpChecker;
  final List<String> _domains;

  bool _cacheStatus = false;
  DateTime _lastCheckTime = DateTime.fromMillisecondsSinceEpoch(0);
  Future<bool>? _currentCheck;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  /// [tcpChecker]: Optional injection for testing (mocks).
  /// [domains]: Optional list of domains.
  NetworkInfoImpl({
    TcpChecker? tcpChecker,
    List<String>? domains,
  })  : _tcpChecker = tcpChecker ?? _defaultTcpCheck,
        _domains = domains ?? _defaultReliableDomains;

  /// The real implementation that establishes a socket connection.
  ///
  /// This BYPASSES the OS DNS cache because [Socket.connect] forces a
  /// TCP SYN packet to be sent. If the server doesn't respond (SYN-ACK),
  /// we know there is no real internet connection, regardless of DNS resolution.
  static Future<bool> _defaultTcpCheck(
      String host, int port, Duration timeout) async {
    Socket? socket;
    try {
      // Port 443 (HTTPS) is the most reliable port, rarely blocked by firewalls.
      socket = await Socket.connect(host, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy(); // Vital: Release OS resources immediately.
    }
  }

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  @override
  Future<bool> get isConnected async {
    // 1. Cache Check (Performance)
    // Prevents spamming sockets if the app checks connectivity frequently.
    if (DateTime.now().difference(_lastCheckTime) < _cacheValidity) {
      return _cacheStatus;
    }

    // 2. Debounce / Concurrency Control
    // If a check is already running, join the existing Future instead of
    // starting a completely new race.
    _currentCheck ??= _executeRaceToSuccess();

    try {
      return await _currentCheck!;
    } finally {
      _currentCheck = null;
    }
  }

  // ===========================================================================
  // INTERNAL LOGIC (RACE STRATEGY)
  // ===========================================================================

  /// Executes multiple TCP connection attempts in parallel ("Race to Success").
  ///
  /// - Returns [true] as soon as the **FIRST** domain connects.
  /// - Returns [false] only if **ALL** domains fail or the global timeout occurs.
  Future<bool> _executeRaceToSuccess() async {
    if (_domains.isEmpty) return false;

    final completer = Completer<bool>();
    int failureCount = 0;

    // Safety timeout to ensure the UI never hangs indefinitely.
    final globalTimer = Timer(_globalTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    for (final domain in _domains) {
      // Fire and forget: We don't await individual checks here.
      _tcpChecker(domain, 443, _socketTimeout).then((isConnected) {
        // If the race is already won/lost, ignore subsequent results.
        if (completer.isCompleted) return;

        if (isConnected) {
          // HAPPY PATH
          globalTimer.cancel();
          completer.complete(true);
        } else {
          // SAD PATH: One candidate failed.
          failureCount++;

          // Check if EVERYONE has failed.
          if (failureCount == _domains.length) {
            globalTimer.cancel();
            // Double-check isCompleted to avoid race conditions with the timer.
            if (!completer.isCompleted) completer.complete(false);
          }
        }
      });
    }

    final result = await completer.future;
    _updateCache(result);
    return result;
  }

  void _updateCache(bool status) {
    _cacheStatus = status;
    _lastCheckTime = DateTime.now();
  }
}
