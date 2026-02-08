abstract class StringUtils {
  /// Verify if a string is null or empty (after trimming).
  static bool isEmpty(String? value) => value == null || value.trim().isEmpty;

  /// Returns the normalized email (trimmed and lowercase).
  static String normalize(String value) => value.trim().toLowerCase();

  /// Cleans up extra spaces and capitalizes the first letter of each word.
  static String cleanAndCapitalizeAll(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (isEmpty(cleaned)) return cleaned;

    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
