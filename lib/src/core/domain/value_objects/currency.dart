import 'package:bits_goals_module/src/core/domain/failures/value_objects/currency/currency_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/value_objects/currency/currency_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/utils/string_utils.dart';
import 'package:equatable/equatable.dart';

/// Currency Value Object
///
/// - Represents a ISO 4217 currency code + its symbol for display
/// - Immutable
/// - Equality is based on code only (symbol is derived from code)
class Currency extends Equatable {
  final String _code;
  final String _symbol;

  // =============================================================
  // Constructors
  // =============================================================

  /// Private constructor to enforce invariants
  const Currency._(this._code, this._symbol);

  /// Factory constructor to create a Currency from an ISO 4217 code.
  ///
  /// Throws [CurrencyFailure] if:
  /// - [code] is empty
  /// - [code] is not supported by this module
  factory Currency.fromISO4217({
    required String code,
  }) {
    final validCode = _getValidIso4217Code(code);
    final symbol = _symbolFromIso4217(validCode);
    return Currency._(validCode, symbol);
  }

  // =============================================================
  // Getters
  // =============================================================

  /// ISO 4217 currency code (normalized to uppercase)
  String get code => _code;

  /// Currency symbol when known. $ is used as a fallback for unknown symbols
  String get symbol => _symbol;

  // =============================================================
  // Validation Helpers
  // =============================================================

  static String _getValidIso4217Code(String code) {
    if (StringUtils.isEmpty(code)) {
      throw const CurrencyFailure(CurrencyFailureReason.emptyCode);
    }

    final normalized = code.trim().toUpperCase();

    // Validate against a real dataset of known currency codes.
    // This ensures we reject non-existent codes (not just wrong format).
    if (!_iso4217SymbolByCode.containsKey(normalized)) {
      throw const CurrencyFailure(CurrencyFailureReason.invalidCode);
    }

    return normalized;
  }

  static String _symbolFromIso4217(String iso4217Code) {
    const fallbackSymbol = r'$';
    final symbol = _iso4217SymbolByCode[iso4217Code];
    if (symbol == null) {
      return fallbackSymbol;
    }
    return symbol.isEmpty ? fallbackSymbol : symbol;
  }

  // =============================================================
  // Equatable Overrides
  // =============================================================

  @override
  List<Object?> get props => [
        _code,
      ];

  @override
  bool? get stringify => true;

  /// Single source of truth for:
  /// - Which ISO 4217 codes are considered valid
  /// - The symbol to display for a code (best-effort; may be empty)
  ///
  /// Kept internal by design (no external packages / no intl dependency).
  static const Map<String, String> _iso4217SymbolByCode = {
    // ISO 4217 currency/funds codes (symbol best-effort; empty means fallback to code)
    'BRL': r'R$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'USD': r'$',
    'AED': '',
    'AFN': '',
    'ALL': '',
    'AMD': '',
    'ANG': '',
    'AOA': '',
    'ARS': r'$',
    'AUD': r'$',
    'AWG': '',
    'AZN': '',
    'BAM': '',
    'BBD': r'$',
    'BDT': '',
    'BGN': '',
    'BHD': '',
    'BIF': '',
    'BMD': r'$',
    'BND': r'$',
    'BOB': '',
    'BOV': '',
    'BSD': r'$',
    'BTN': '',
    'BWP': '',
    'BYN': '',
    'BZD': r'$',
    'CAD': r'$',
    'CDF': '',
    'CHE': '',
    'CHF': '',
    'CHW': '',
    'CLF': '',
    'CLP': r'$',
    'CNY': '¥',
    'COP': r'$',
    'COU': '',
    'CRC': '₡',
    'CUP': r'$',
    'CVE': '',
    'CZK': 'Kč',
    'DJF': '',
    'DKK': 'kr',
    'DOP': r'$',
    'DZD': '',
    'EGP': '£',
    'ERN': '',
    'ETB': '',
    'FJD': r'$',
    'FKP': '£',
    'GEL': '',
    'GHS': '₵',
    'GIP': '£',
    'GMD': '',
    'GNF': '',
    'GTQ': 'Q',
    'GYD': r'$',
    'HKD': r'$',
    'HNL': 'L',
    'HTG': '',
    'HUF': 'Ft',
    'IDR': 'Rp',
    'ILS': '₪',
    'INR': '₹',
    'IQD': '',
    'IRR': '',
    'ISK': 'kr',
    'JMD': r'$',
    'JOD': '',
    'KES': '',
    'KGS': '',
    'KHR': '៛',
    'KMF': '',
    'KPW': '₩',
    'KRW': '₩',
    'KWD': '',
    'KYD': r'$',
    'KZT': '₸',
    'LAK': '₭',
    'LBP': '£',
    'LKR': 'Rs',
    'LRD': r'$',
    'LSL': '',
    'LYD': '',
    'MAD': '',
    'MDL': '',
    'MGA': '',
    'MKD': '',
    'MMK': 'K',
    'MNT': '₮',
    'MOP': '',
    'MRU': '',
    'MUR': 'Rs',
    'MVR': '',
    'MWK': '',
    'MXN': r'$',
    'MXV': '',
    'MYR': 'RM',
    'MZN': '',
    'NAD': r'$',
    'NGN': '₦',
    'NIO': r'C$',
    'NOK': 'kr',
    'NPR': 'Rs',
    'NZD': r'$',
    'OMR': '',
    'PAB': 'B/.',
    'PEN': 'S/',
    'PGK': '',
    'PHP': '₱',
    'PKR': 'Rs',
    'PLN': 'zł',
    'PYG': '₲',
    'QAR': '',
    'RON': 'lei',
    'RSD': '',
    'RUB': '₽',
    'RWF': '',
    'SAR': '',
    'SBD': r'$',
    'SCR': 'Rs',
    'SDG': '',
    'SEK': 'kr',
    'SGD': r'$',
    'SHP': '£',
    'SLE': '',
    'SLL': '',
    'SOS': '',
    'SRD': r'$',
    'SSP': '',
    'STN': '',
    'SVC': r'$',
    'SYP': '£',
    'SZL': '',
    'THB': '฿',
    'TJS': '',
    'TMT': '',
    'TND': '',
    'TOP': '',
    'TRY': '₺',
    'TTD': r'$',
    'TWD': r'$',
    'TZS': '',
    'UAH': '₴',
    'UGX': '',
    'USN': r'$',
    'UYI': '',
    'UYU': r'$',
    'UZS': '',
    'VED': '',
    'VES': '',
    'VND': '₫',
    'VUV': '',
    'WST': '',
    'XAF': '',
    'XAG': '',
    'XAU': '',
    'XBA': '',
    'XBB': '',
    'XBC': '',
    'XBD': '',
    'XCD': r'$',
    'XDR': '',
    'XOF': '',
    'XPD': '',
    'XPF': '',
    'XPT': '',
    'XSU': '',
    'XTS': '',
    'XUA': '',
    'XXX': '',
    'YER': '',
    'ZAR': 'R',
    'ZMW': '',
    'ZWL': r'$',
  };
}
