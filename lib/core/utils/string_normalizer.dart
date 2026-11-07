/// Utility functions for string normalization, specifically handling Spanish diacritics.
class StringNormalizer {
  StringNormalizer._();

  /// Normalizes a string by trimming whitespace, converting to lower case,
  /// and replacing accented characters (á, é, í, ó, ú, ü) with their unaccented equivalents.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    return input
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  /// Compares two strings for equivalence ignoring case, leading/trailing whitespace,
  /// and Spanish diacritical accents.
  static bool areEquivalent(String a, String b) {
    return normalize(a) == normalize(b);
  }
}

