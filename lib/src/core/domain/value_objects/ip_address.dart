import 'package:bits_goals_module/src/core/domain/failures/ip_address/ip_address_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/ip_address/ip_address_failure_reason.dart';
import 'package:equatable/equatable.dart';

class IpAddress extends Equatable {
  final String value;

  // ================================================================
  // CONSTRUCTORS
  // ================================================================

  const IpAddress._(this.value);

  factory IpAddress(String ip) {
    final cleanedIp = ip.trim().toLowerCase();
    if (!_isValid(cleanedIp)) {
      throw const IpAddressFailure(IpAddressFailureReason.invalidFormat);
    }
    return IpAddress._(cleanedIp);
  }

  // ================================================================
  // HELPERS
  // ================================================================

  static bool _isValid(String ip) {
    final ipv4Regex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    // Validation of Standard IPv6 (Hexadecimal with '::' compression)
    final ipv6StdRegex = RegExp(
      r'^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$|^([a-fA-F0-9]{1,4}:){1,7}:$|^([a-fA-F0-9]{1,4}:){1,6}:[a-fA-F0-9]{1,4}$|^([a-fA-F0-9]{1,4}:){1,5}(:[a-fA-F0-9]{1,4}){1,2}$|^([a-fA-F0-9]{1,4}:){1,4}(:[a-fA-F0-9]{1,4}){1,3}$|^([a-fA-F0-9]{1,4}:){1,3}(:[a-fA-F0-9]{1,4}){1,4}$|^([a-fA-F0-9]{1,4}:){1,2}(:[a-fA-F0-9]{1,4}){1,5}$|^[a-fA-F0-9]{1,4}:((:[a-fA-F0-9]{1,4}){1,6})$|^:((:[a-fA-F0-9]{1,4}){1,7}|:)$|^fe80:(:[a-fA-F0-9]{0,4}){0,4}%[0-9a-zA-Z]{1,}$',
    );

    // Validation of IPv6 Mapped (IPv4 embedded in IPv6)
    final ipv6MappedRegex = RegExp(
      r'^::ffff:(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      caseSensitive: false,
    );

    return ipv4Regex.hasMatch(ip) ||
        ipv6StdRegex.hasMatch(ip) ||
        ipv6MappedRegex.hasMatch(ip);
  }

  // ================================================================
  // GETTERS
  // ================================================================

  bool get isIpv6 => value.contains(':');

  bool get isIpv4 => value.contains('.') && !value.contains(':');

  // ================================================================
  // EQUATABLE OVERRIDES
  // ================================================================

  @override
  List<Object?> get props => [value];

  @override
  bool? get stringify => true;
}
