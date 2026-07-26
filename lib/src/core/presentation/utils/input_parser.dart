import 'package:intl/intl.dart';

// TODO: Add unit tests for this class.
class InputParser {
  /// Tries to parse a string representing a money value into a double.
  /// Returns null if parsing fails.
  ///
  /// Uses the [intl] package to correctly interpret thousand and decimal
  /// separators based on the provided [locale] (e.g., 'pt_BR', 'en_US').
  static double? tryParseMoneyString({
    required String input,
    required String currencyLocale,
  }) {
    // 1. Basic trimming of leading and trailing spaces.
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return null;

    try {
      // 2. Create the formatter based on the locale.
      // The decimalPattern handles thousand and decimal separators.
      final formatter = NumberFormat.decimalPattern(currencyLocale);

      // 3. The intl package returns a 'num', so we explicitly convert it to double.
      return formatter.parse(cleanInput).toDouble();
    } catch (e) {
      return null;
    }
  }
}
