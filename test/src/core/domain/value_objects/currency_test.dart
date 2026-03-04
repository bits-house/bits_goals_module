import 'package:bits_goals_module/src/core/domain/failures/value_objects/currency/currency_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/value_objects/currency/currency_failure_reason.dart';
import 'package:bits_goals_module/src/core/domain/value_objects/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    group('Instantiation and Normalization', () {
      test('should fromISO4217 a valid instance and normalize code', () {
        final currency = Currency.fromISO4217('  brl  ');

        expect(currency.code, equals('BRL'));
        expect(currency.symbol, equals(r'R$'));
      });
    });

    group('Top currencies', () {
      final cases = <({String code, String expectedSymbol})>[
        (code: 'USD', expectedSymbol: r'$'),
        (code: 'EUR', expectedSymbol: '€'),
        (code: 'JPY', expectedSymbol: '¥'),
        (code: 'GBP', expectedSymbol: '£'),
        (code: 'AUD', expectedSymbol: r'$'),
        (code: 'CAD', expectedSymbol: r'$'),
        (code: 'CNY', expectedSymbol: '¥'),
        (code: 'HKD', expectedSymbol: r'$'),
        (code: 'SGD', expectedSymbol: r'$'),
        (code: 'NZD', expectedSymbol: r'$'),
        (code: 'SEK', expectedSymbol: 'kr'),
        (code: 'NOK', expectedSymbol: 'kr'),
        (code: 'DKK', expectedSymbol: 'kr'),
        (code: 'KRW', expectedSymbol: '₩'),
        (code: 'INR', expectedSymbol: '₹'),
        (code: 'BRL', expectedSymbol: r'R$'),
        (code: 'MXN', expectedSymbol: r'$'),
        (code: 'RUB', expectedSymbol: '₽'),
        (code: 'ZAR', expectedSymbol: 'R'),
        (code: 'TRY', expectedSymbol: '₺'),
        (code: 'PLN', expectedSymbol: 'zł'),
        (code: 'THB', expectedSymbol: '฿'),
      ];

      for (final currencyCase in cases) {
        test(
          'should create ${currencyCase.code} and keep expected symbol',
          () {
            final currency = Currency.fromISO4217(
              currencyCase.code.toLowerCase(),
            );

            expect(currency.code, equals(currencyCase.code));
            expect(currency.symbol, equals(currencyCase.expectedSymbol));
          },
        );
      }
    });

    group('Validation Failures', () {
      test('should throw CurrencyFailure (emptyCode) when code is empty', () {
        expect(
          () => Currency.fromISO4217('   '),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.emptyCode,
            ),
          ),
        );
      });

      test(
          'should throw CurrencyFailure (invalidCode) when code is not supported',
          () {
        expect(
          () => Currency.fromISO4217('US'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.invalidCode,
            ),
          ),
        );

        expect(
          () => Currency.fromISO4217('USDx'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.invalidCode,
            ),
          ),
        );

        expect(
          () => Currency.fromISO4217(r'12$'),
          throwsA(
            isA<CurrencyFailure>().having(
              (e) => e.reason,
              'reason',
              CurrencyFailureReason.invalidCode,
            ),
          ),
        );
      });
    });

    group('Equality and Value Object properties', () {
      test('should be equal when all properties are identical', () {
        final c1 = Currency.fromISO4217('usd');
        final c2 = Currency.fromISO4217('USD');

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('stringify should be true for better debug logs', () {
        final c = Currency.fromISO4217('EUR');

        expect(c.toString(), contains('EUR'));
        expect(c.stringify, isTrue);
      });
    });

    group('Fallback symbol', () {
      test(
          'should use fallback symbol (\$) when the currency has no defined symbol',
          () {
        final currenciesWithoutSymbol = ['AED', 'AFN', 'ALL', 'AMD', 'ANG'];

        for (final code in currenciesWithoutSymbol) {
          final currency = Currency.fromISO4217(code);

          expect(currency.code, equals(code));
          expect(currency.symbol, equals(r'$'));
        }
      });
    });

    test('should not be equal when currency codes are different', () {
      final c1 = Currency.fromISO4217('USD');
      final c2 = Currency.fromISO4217('EUR');

      expect(c1, isNot(equals(c2)));
      expect(c1.hashCode, isNot(equals(c2.hashCode)));
    });
  });
}
