extension MapParsingExtension on Map<String, dynamic> {
  /// Usage:
  /// ```dart
  /// final myInt = myMap.getInt(
  /// key: 'my_key',
  /// legacyKeys: ['last_key', 'very_old_key'], // order matters
  /// defaultValue: 0,
  /// );
  /// ```
  /// This will try to get the int value for 'my_key'.
  /// If not found, it will try 'last_key', then 'very_old_key'.
  /// If none are found or parseable, it will return 0.
  /// Handles int, double (truncating), and numeric Strings.
  int getInt({
    required String key,
    List<String> legacyKeys = const [],
    int? defaultValue,
  }) {
    int? tryGetKey(String k) {
      if (!containsKey(k) || this[k] == null) return null;
      final value = this[k];

      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final doubleValue = double.tryParse(value);
        if (doubleValue != null) {
          return doubleValue.toInt();
        }
        return int.tryParse(value);
      }
      return null;
    }

    var result = tryGetKey(key);
    if (result != null) return result;

    // Try legacy keys
    for (final legacyKey in legacyKeys) {
      result = tryGetKey(legacyKey);
      if (result != null) return result;
    }

    if (defaultValue != null) {
      return defaultValue;
    }
    throw FormatException(
        'Key "$key" not found and no valid legacy keys found, and no defaultValue provided.');
  }

  /// Usage:
  /// ```dart
  /// final myString = myMap.getString(
  /// key: 'my_key',
  /// legacyKeys: ['last_key', 'very_old_key'], // order matters
  /// defaultValue: 'default',
  /// );
  /// ```
  /// This will try to get the String value for 'my_key'.
  /// If not found, it will try 'last_key', then 'very_old_key'.
  /// If none are found, it will return 'default'.
  /// Converts non-String values to String using toString().
  String getString({
    required String key,
    List<String> legacyKeys = const [],
    String? defaultValue,
  }) {
    String? tryGetKey(String k) {
      if (!containsKey(k) || this[k] == null) return null;
      return this[k].toString();
    }

    var result = tryGetKey(key);
    if (result != null) return result;

    for (final legacyKey in legacyKeys) {
      result = tryGetKey(legacyKey);
      if (result != null) return result;
    }

    if (defaultValue != null) {
      return defaultValue;
    }
    throw FormatException(
        'Key "$key" not found and no valid legacy keys found, and no defaultValue provided.');
  }
}
