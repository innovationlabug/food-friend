import '../../../core/utils/string_normalizer.dart';

/// Enumeration of measurement units supported for ingredients.
/// Provides English internal identifiers and Spanish localized display names.
enum AmountUnit {
  liters('liters', 'litro', 'litros', 'L'),
  milliliters('milliliters', 'mililitro', 'mililitros', 'ml'),
  grams('grams', 'gramo', 'gramos', 'g'),
  kilograms('kilograms', 'kilogramo', 'kilogramos', 'kg'),
  pieces('pieces', 'pieza', 'piezas', 'pza'),
  units('units', 'unidad', 'unidades', 'ud'),
  cups('cups', 'taza', 'tazas', 'tza'),
  tablespoons('tablespoons', 'cucharada', 'cucharadas', 'cda'),
  teaspoons('teaspoons', 'cucharadita', 'cucharaditas', 'cdta'),
  ounces('ounces', 'onza', 'onzas', 'oz'),
  pounds('pounds', 'libra', 'libras', 'lb');

  const AmountUnit(
    this.key,
    this.singularSpanish,
    this.pluralSpanish,
    this.shortSymbol,
  );

  /// Key identifier used in serialization and storage
  final String key;

  /// Singular Spanish label (e.g. 'litro')
  final String singularSpanish;

  /// Plural Spanish label (e.g. 'litros')
  final String pluralSpanish;

  /// Short abbreviation symbol (e.g. 'L', 'g', 'ml')
  final String shortSymbol;

  /// Returns localized Spanish text based on the numeric value.
  String formatForAmount(double? amount) {
    if (amount == null || amount == 1.0) {
      return singularSpanish;
    }
    return pluralSpanish;
  }

  /// Parses a string into an AmountUnit matching either internal key,
  /// Spanish forms, or abbreviations.
  static AmountUnit? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = StringNormalizer.normalize(value);

    for (final unit in AmountUnit.values) {
      if (unit.key.toLowerCase() == normalized ||
          StringNormalizer.normalize(unit.singularSpanish) == normalized ||
          StringNormalizer.normalize(unit.pluralSpanish) == normalized ||
          StringNormalizer.normalize(unit.shortSymbol) == normalized) {
        return unit;
      }
    }

    return null;
  }
}

