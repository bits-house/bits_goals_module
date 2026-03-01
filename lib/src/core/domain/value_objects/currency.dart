class Currency {
  final String _code;
  final String _symbol;

  Currency._({
    required String code,
    required String symbol,
  })  : _code = code,
        _symbol = symbol;

  factory Currency.fromISO4217(String code) {
    // TODO: mapping of ISO 4217 codes to symbols here
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'BRL': 'R\$',
      // Add more currencies as needed
    };

    final symbol = symbols[code] ?? '';
    return Currency._(
      code: code,
      symbol: symbol,
    );
  }
}
