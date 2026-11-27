import '../../../core/utils/string_normalizer.dart';

/// Parsed culinary or retail measurement unit.
enum ParsedMeasureUnit {
  gram,
  kilogram,
  pound,
  ounce,
  milliliter,
  liter,
  cup,
  tablespoon,
  teaspoon,
  unit,
  clove,
  sprig,
  bunch,
  leaf,
  stalk,
  can,
  fillet,
}

/// Numeric value and measure unit extracted from Spanish text.
class ParsedQuantity {
  const ParsedQuantity({
    required this.value,
    required this.unit,
  });

  final double value;
  final ParsedMeasureUnit unit;
}

/// Deterministic parser for Spanish recipe `displayAmount` strings and
/// Guatemalan supermarket/receipt product quantities.
class QuantityParser {
  QuantityParser._();

  static final RegExp _rangePattern = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*(?:a|-)\s*(\d+(?:\.\d+)?)',
  );
  static final RegExp _mixedFractionPattern = RegExp(
    r'(\d+)\s+(\d+)\s*/\s*(\d+)',
  );
  static final RegExp _fractionPattern = RegExp(r'(\d+)\s*/\s*(\d+)');
  static final RegExp _numberPattern = RegExp(r'(\d+(?:[.,]\d+)?)');
  static final RegExp _packPattern = RegExp(
    r'(\d+)\s*(?:pack|pq|paq|uds?|unidades?)',
  );

  /// Extracts a quantity and unit from [rawText]. Returns `null` when no
  /// numeric quantity or recognizable unit is present.
  static ParsedQuantity? parse(String rawText) {
    final norm = StringNormalizer.normalize(rawText);
    if (norm.isEmpty) return null;

    final value = _extractNumericValue(norm);
    final unit = _detectUnit(norm);

    if (value == null || value <= 0) {
      if (unit == ParsedMeasureUnit.bunch || unit == ParsedMeasureUnit.can) {
        return ParsedQuantity(value: 1.0, unit: unit);
      }
      return null;
    }

    return ParsedQuantity(value: value, unit: unit);
  }

  /// Extracts a pack multiplier when a retail product includes a pack count
  /// without explicit total weight/volume (e.g. "3 Pack" -> 3).
  static int extractPackMultiplier(String rawText) {
    final norm = StringNormalizer.normalize(rawText);
    final match = _packPattern.firstMatch(norm);
    if (match == null) return 1;
    final parsed = int.tryParse(match.group(1) ?? '');
    if (parsed == null || parsed <= 0 || parsed > 100) return 1;
    return parsed;
  }

  static double? _extractNumericValue(String norm) {
    final rangeMatch = _rangePattern.firstMatch(norm);
    if (rangeMatch != null) {
      final low = double.tryParse(rangeMatch.group(1) ?? '');
      final high = double.tryParse(rangeMatch.group(2) ?? '');
      if (low != null && high != null) {
        return (low + high) / 2.0;
      }
    }

    final mixedMatch = _mixedFractionPattern.firstMatch(norm);
    if (mixedMatch != null) {
      final whole = double.tryParse(mixedMatch.group(1) ?? '');
      final num = double.tryParse(mixedMatch.group(2) ?? '');
      final den = double.tryParse(mixedMatch.group(3) ?? '');
      if (whole != null && num != null && den != null && den != 0) {
        return whole + (num / den);
      }
    }

    final fracMatch = _fractionPattern.firstMatch(norm);
    if (fracMatch != null) {
      final num = double.tryParse(fracMatch.group(1) ?? '');
      final den = double.tryParse(fracMatch.group(2) ?? '');
      if (num != null && den != null && den != 0) {
        return num / den;
      }
    }

    final numMatch = _numberPattern.firstMatch(norm);
    if (numMatch != null) {
      final clean = (numMatch.group(1) ?? '').replaceAll(',', '.');
      return double.tryParse(clean);
    }

    return null;
  }

  static ParsedMeasureUnit _detectUnit(String norm) {
    final padded = ' $norm ';

    if (RegExp(r'(?:^|\s|\d)(?:kg|kilo|kilos|kilogramo|kilogramos)(?:\s|$)').hasMatch(norm)) {
      return ParsedMeasureUnit.kilogram;
    }
    if (RegExp(r'(?:^|\s|\d)(?:lb|lbs|libra|libras)(?:\s|$)').hasMatch(norm)) {
      return ParsedMeasureUnit.pound;
    }
    if (RegExp(r'(?:^|\s|\d)(?:oz|onza|onzas)(?:\s|$)').hasMatch(norm)) {
      return ParsedMeasureUnit.ounce;
    }
    if (RegExp(r'(?:^|\s|\d)(?:ml|mililitro|mililitros)(?:\s|$)').hasMatch(norm)) {
      return ParsedMeasureUnit.milliliter;
    }
    if (RegExp(r'(?:^|\s|\d)(?:l|lt|lts|litro|litros)(?:\s|$)').hasMatch(norm)) {
      return ParsedMeasureUnit.liter;
    }
    if (RegExp(r'(?:^|\s|\d)(?:g|gr|gramo|gramos)(?:\s|$)').hasMatch(norm)) {
      return ParsedMeasureUnit.gram;
    }
    if (padded.contains(' cucharadita') || padded.contains(' cdita')) {
      return ParsedMeasureUnit.teaspoon;
    }
    if (padded.contains(' cucharada') || padded.contains(' cda')) {
      return ParsedMeasureUnit.tablespoon;
    }
    if (padded.contains(' taza')) {
      return ParsedMeasureUnit.cup;
    }
    if (padded.contains(' diente')) {
      return ParsedMeasureUnit.clove;
    }
    if (padded.contains(' ramita')) {
      return ParsedMeasureUnit.sprig;
    }
    if (padded.contains(' manojo')) {
      return ParsedMeasureUnit.bunch;
    }
    if (padded.contains(' hoja')) {
      return ParsedMeasureUnit.leaf;
    }
    if (padded.contains(' tallo')) {
      return ParsedMeasureUnit.stalk;
    }
    if (padded.contains(' lata')) {
      return ParsedMeasureUnit.can;
    }
    if (padded.contains(' filete')) {
      return ParsedMeasureUnit.fillet;
    }
    return ParsedMeasureUnit.unit;
  }
}
