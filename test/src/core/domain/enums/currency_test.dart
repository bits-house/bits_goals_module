import 'package:bits_goals_module/src/core/domain/failures/enums/currency/currency_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/enums/currency/currency_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/enums/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    group('Instantiation and Normalization', () {
      test('should create a valid instance and normalize casing', () {
        final currency = Currency.fromISO4217('bRl');

        expect(currency, equals(Currency.brl));
        expect(currency.iso4217Code, equals('BRL'));
        expect(currency.symbol, equals(r'R$'));
        expect(currency.locale, equals('pt-BR'));
      });
    });

    group('Supported currencies', () {
      final cases =
          <({String code, Currency expected, String symbol, String locale})>[
        (code: 'BRL', expected: Currency.brl, symbol: r'R$', locale: 'pt-BR'),
        (code: 'USD', expected: Currency.usd, symbol: r'$', locale: 'en-US'),
        (code: 'PYG', expected: Currency.pyg, symbol: r'₲', locale: 'es-PY'),
      ];

      for (final currencyCase in cases) {
        test('should create ${currencyCase.code} and keep expected metadata',
            () {
          final currency = Currency.fromISO4217(currencyCase.code);

          expect(currency, equals(currencyCase.expected));
          expect(currency.iso4217Code, equals(currencyCase.code));
          expect(currency.symbol, equals(currencyCase.symbol));
          expect(currency.locale, equals(currencyCase.locale));
        });
      }
    });

    group('Validation Failures', () {
      test('should throw CurrencyFailure when code is empty', () {
        expect(
          () => Currency.fromISO4217('   '),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.unsupportedOrInvalidCurrency,
            ),
          ),
        );
      });

      test('should throw CurrencyFailure when code is not supported', () {
        expect(
          () => Currency.fromISO4217('US'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.unsupportedOrInvalidCurrency,
            ),
          ),
        );

        expect(
          () => Currency.fromISO4217('USDx'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.unsupportedOrInvalidCurrency,
            ),
          ),
        );

        expect(
          () => Currency.fromISO4217(r'12$'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.unsupportedOrInvalidCurrency,
            ),
          ),
        );

        expect(
          () => Currency.fromISO4217('EUR'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.unsupportedOrInvalidCurrency,
            ),
          ),
        );
      });
    });

    group('Equality', () {
      test('should be equal when all properties are identical', () {
        final c1 = Currency.fromISO4217('usd');
        final c2 = Currency.fromISO4217('USD');

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      });
    });

    test('should not be equal when currency codes are different', () {
      final c1 = Currency.fromISO4217('USD');
      final c2 = Currency.fromISO4217('BRL');

      expect(c1, isNot(equals(c2)));
      expect(c1.hashCode, isNot(equals(c2.hashCode)));
    });
  });
}
