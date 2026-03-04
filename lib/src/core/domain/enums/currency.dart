import 'package:bits_goals_module/src/core/domain/failures/enums/currency/currency_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/enums/currency/currency_failure_reason.dart';

/// Subset of ISO 4217 currencies supported by this module.
/// Name MUST be the ISO 4217 code in lowercase (e.g., "brl", "usd").
enum Currency {
  brl(symbol: r'R$', locale: 'pt-BR'),
  pyg(symbol: r'₲', locale: 'es-PY'),
  usd(symbol: r'$', locale: 'en-US'),
  eur(symbol: '€', locale: 'de-DE'),
  gbp(symbol: '£', locale: 'en-GB'),
  jpy(symbol: '¥', locale: 'ja-JP'),
  cny(symbol: 'CN¥', locale: 'zh-CN'),
  chf(symbol: 'CHF', locale: 'de-CH'),
  cad(symbol: r'C$', locale: 'en-CA'),
  aud(symbol: r'A$', locale: 'en-AU'),
  inr(symbol: '₹', locale: 'en-IN'),
  mxn(symbol: r'MX$', locale: 'es-MX'),
  krw(symbol: '₩', locale: 'ko-KR');

  /// The currency symbol (e.g., "$", "R$").
  final String symbol;

  /// The default locale associated with this currency, expressed as a
  /// BCP 47 language tag (e.g., "pt-BR", "en-US").
  ///
  /// Format:
  /// - Language: ISO 639-1 (e.g., "pt", "en")
  /// - Region: ISO 3166-1 alpha-2 (e.g., "BR", "US")
  /// - Combined using BCP 47 syntax with a hyphen separator.
  /// - This form is compatible with the intl package.
  ///
  /// Note:
  /// - Currency and locale are conceptually independent.
  /// - This locale is provided as a *convenience* for formatting
  ///   and input parsing of monetary values only.
  final String locale;

  const Currency({
    required this.symbol,
    required this.locale,
  });

  /// Factory constructor to create a [Currency] from an
  /// ISO 4217 code (e.g., "BRL", "USD").
  factory Currency.fromISO4217(String code) {
    try {
      return Currency.values.firstWhere(
        (currency) => currency.name == code.toLowerCase(),
      );
    } catch (e) {
      throw const CurrencyFailure(
        CurrencyFailureReason.unsupportedOrInvalidCurrency,
      );
    }
  }

  /// Returns the [Currency] ISO 4217 code (e.g., "BRL", "USD").
  String get iso4217Code => name.toUpperCase();
}
