import 'package:bits_goals_module/src/core/domain/value_objects/ip_address.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bits_goals_module/src/core/domain/failures/ip_address/ip_address_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/ip_address/ip_address_failure_reason.dart';

void main() {
  group('IpAddress Extended Tests', () {
    // ================================================================
    // VALID SCENARIOS
    // ================================================================
    group('Valid IPv4 Cases', () {
      final validIpv4s = [
        '0.0.0.0', // Localhost/Any
        '127.0.0.1', // Loopback
        '192.168.0.1', // Private Class C
        '10.0.0.254', // Private Class A
        '172.16.0.1', // Private Class B
        '255.255.255.255', // Broadcast
        '8.8.8.8', // Google DNS
        '1.1.1.1', // Cloudflare DNS
        '169.254.1.1', // APIPA
        '224.0.0.1', // Multicast
        '45.79.12.203', // Public IP
        '192.168.0.0', // Network Address
        '1.0.0.0', // Min valid public
        '255.0.0.0', // Netmask like IP
      ];

      for (var ip in validIpv4s) {
        test('should accept valid IPv4: $ip', () {
          final result = IpAddress(ip);
          expect(result.value, ip);
          expect(result.isIpv4, isTrue);
          expect(result.isIpv6, isFalse);
        });
      }
    });

    group('Valid IPv6 Cases', () {
      final validIpv6s = [
        '2001:0db8:85a3:0000:0000:8a2e:0370:7334', // Full
        '2001:db8:85a3:0:0:8a2e:370:7334', // Leading zeros removed
        '2001:db8:85a3::8a2e:370:7334', // Compressed zeros
        '::1', // Loopback
        '::', // Unspecified
        'fe80::1', // Link-local compressed
        '2001:db8::', // Trailing compression
        '::ffff:192.168.0.1', // IPv4-mapped (transition)
        '2001:4860:4860::8888', // Google DNS IPv6
        'abcd:ef01:2345:6789:abcd:ef01:2345:6789', // All segments full
        'fe80::1%eth0', // Link-local com Zone ID (Interface)
        'fe80::1%12', // Link-local com Zone ID numérico
        '::ffff:0.0.0.0', // Mapped lowest IPv4
        '::ffff:255.255.255.255', // Mapped highest IPv4
      ];

      for (var ip in validIpv6s) {
        test('should accept valid IPv6: $ip', () {
          final result = IpAddress(ip);

          expect(result.value, ip.toLowerCase());
          expect(result.isIpv6, isTrue);

          // CRITICAL: Ensure a Mapped IP is NOT considered v4,
          // as it is a v6 envelope
          expect(result.isIpv4, isFalse,
              reason: 'Mapped IPv6 is structurally IPv6');
        });
      }
    });

    // ================================================================
    // INVALID SCENARIOS (FAILURES)
    // ================================================================
    group('Invalid IP Cases (Failures)', () {
      // --- IPv4 Errors ---
      test('should throw invalidFormat for out of range octets (IPv4)', () {
        expect(
            () => IpAddress('256.0.0.1'),
            throwsA(isA<IpAddressFailure>().having((f) => f.reason, 'reason',
                IpAddressFailureReason.invalidFormat)));
      });

      test('should throw for incomplete IPv4', () {
        expect(() => IpAddress('192.168.1'), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for IPv4 with too many octets', () {
        expect(
            () => IpAddress('192.168.0.0.1'), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for IPv4 with negative numbers', () {
        // Novo
        expect(
            () => IpAddress('192.168.0.-1'), throwsA(isA<IpAddressFailure>()));
      });

      // --- IPv6 Errors ---
      test('should throw for IPv6 with too many segments', () {
        expect(() => IpAddress('1:2:3:4:5:6:7:8:9'),
            throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for invalid hex characters in IPv6', () {
        expect(
            () => IpAddress('2001:db8::xyz'), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for ambiguous double colon (::) usage', () {
        // Critical
        // The standard prohibits :: from appearing more than once
        expect(() => IpAddress('2001::1::2'), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for triple colon', () {
        expect(() => IpAddress(':::'), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for invalid IPv4 part inside IPv6 mapped', () {
        expect(() => IpAddress('::ffff:256.0.0.1'),
            throwsA(isA<IpAddressFailure>()));
        expect(() => IpAddress('::ffff:192.168.1'),
            throwsA(isA<IpAddressFailure>()));
      });

      // --- Input/Security Errors ---
      test('should throw for empty or whitespace strings', () {
        expect(() => IpAddress(''), throwsA(isA<IpAddressFailure>()));
        expect(() => IpAddress('   '), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for non-IP strings (Injection attempts)', () {
        expect(() => IpAddress('SELECT * FROM users'),
            throwsA(isA<IpAddressFailure>()));
        expect(() => IpAddress('localhost'), throwsA(isA<IpAddressFailure>()));
      });

      test('should throw for incorrect separators', () {
        // Critical
        expect(
            () => IpAddress('192-168-0-1'), throwsA(isA<IpAddressFailure>()));
        expect(
            () => IpAddress('192,168,0,1'), throwsA(isA<IpAddressFailure>()));
      });
    });

    // ================================================================
    // LOGIC & UTILITIES
    // ================================================================
    group('Normalization & Equality', () {
      test('should be case-insensitive for IPv6 equality', () {
        final ipUpper = IpAddress('2001:DB8::1');
        final ipLower = IpAddress('2001:db8::1');
        expect(ipUpper, equals(ipLower));
      });

      test('should trim inputs automatically', () {
        final trimmed = IpAddress('  127.0.0.1  ');
        expect(trimmed.value, '127.0.0.1');
      });

      test('toString should match Equatable stringify pattern', () {
        final ip = IpAddress('8.8.8.8');
        expect(ip.toString(), 'IpAddress(8.8.8.8)');
      });

      test('should correctly identify IP versions logic', () {
        // Critical
        final v4 = IpAddress('192.168.1.1');
        final v6 = IpAddress('::1');
        final v6Mapped = IpAddress('::ffff:192.168.1.1');

        expect(v4.isIpv4, isTrue);
        expect(v4.isIpv6, isFalse);

        expect(v6.isIpv4, isFalse);
        expect(v6.isIpv6, isTrue);

        expect(v6Mapped.isIpv4, isFalse, reason: 'Mapped is v6');
        expect(v6Mapped.isIpv6, isTrue);
      });
    });
  });
}
