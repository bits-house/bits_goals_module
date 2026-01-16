abstract class StringUtils {
  /// Verify if a string is null or empty (after trimming).
  static bool isEmpty(String? value) => value == null || value.trim().isEmpty;

  /// Returns the normalized email (trimmed and lowercase).
  static String normalize(String value) => value.trim().toLowerCase();

  /// Validates the email format following strict TLD and structure rules.
  static bool isValidEmail(String? email) {
    if (isEmpty(email)) return false;

    // 1. RFC: Total length must not exceed 254 characters
    if (email!.length > 254) return false;

    // 2. Basic structure: user@domain.tld
    // This Regex ensures there is an @ and at least one dot in the domain part
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );

    if (!emailRegex.hasMatch(email)) return false;

    final parts = email.split('@');
    final localPart = parts[0];
    final domainPart = parts[1];

    // 3. Validation of the Local-part (before the @)
    // Blocks dots at the start, end, or consecutive dots (..).
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return false;
    }

    // 4. Validation of the Domain-part (after the @)
    // Blocks dots at the end or consecutive dots (..).
    final domainSegments = domainPart.split('.');

    // Blocks TLDs (last segment) that are purely numeric or too short (< 2 characters).
    final tld = domainSegments.last;
    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(tld);
    if (tld.length < 2 || isNumeric) return false;

    return true;
  }

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
