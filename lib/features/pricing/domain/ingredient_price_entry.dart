import '../../../core/utils/string_normalizer.dart';

/// Base physical measurement unit used to normalize ingredient GTQ prices.
enum PriceUnit {
  gram('g'),
  milliliter('ml'),
  unit('ud');

  const PriceUnit(this.shortLabel);

  final String shortLabel;

  static PriceUnit fromString(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final value in PriceUnit.values) {
      if (value.name.toLowerCase() == normalized ||
          value.shortLabel == normalized) {
        return value;
      }
    }
    return PriceUnit.unit;
  }
}

/// Origin of an ingredient GTQ price used for recipe cost estimation.
enum PriceSource {
  receipt('receipt'),
  supermarketDeal('supermarket_deal'),
  baseline('baseline');

  const PriceSource(this.key);

  final String key;

  static PriceSource fromString(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final value in PriceSource.values) {
      if (value.key == normalized || value.name.toLowerCase() == normalized) {
        return value;
      }
    }
    return PriceSource.baseline;
  }
}

/// Persisted GTQ price observation for an ingredient from a scanned receipt
/// or supermarket deal, normalized to [baseUnit].
class IngredientPriceEntry {
  const IngredientPriceEntry({
    required this.ingredientName,
    required this.priceGtq,
    required this.baseUnit,
    required this.pricePerBaseUnitGtq,
    required this.source,
    required this.updatedAt,
    this.quantityText = '1 unidad',
    this.supermarket,
  });

  /// Display ingredient name in Spanish.
  final String ingredientName;

  /// Raw package/line unit price observed in Guatemalan Quetzales (Q).
  final double priceGtq;

  /// Normalized physical unit for [pricePerBaseUnitGtq].
  final PriceUnit baseUnit;

  /// Cost per single gram, milliliter, or discrete unit in GTQ.
  final double pricePerBaseUnitGtq;

  /// Where this price came from.
  final PriceSource source;

  /// Optional supermarket chain name (e.g. 'La Torre', 'Walmart').
  final String? supermarket;

  /// Original quantity text used to derive [pricePerBaseUnitGtq].
  final String quantityText;

  /// Timestamp when this price was persisted.
  final DateTime updatedAt;

  /// Normalized Spanish lookup key.
  String get normalizedName => StringNormalizer.normalize(ingredientName);

  Map<String, dynamic> toJson() {
    return {
      'ingredientName': ingredientName,
      'priceGtq': priceGtq,
      'baseUnit': baseUnit.name,
      'pricePerBaseUnitGtq': pricePerBaseUnitGtq,
      'source': source.key,
      'quantityText': quantityText,
      if (supermarket != null) 'supermarket': supermarket,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory IngredientPriceEntry.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return IngredientPriceEntry(
      ingredientName: (json['ingredientName'] ?? '').toString().trim(),
      priceGtq: toDouble(json['priceGtq']),
      baseUnit: PriceUnit.fromString(json['baseUnit']?.toString()),
      pricePerBaseUnitGtq: toDouble(json['pricePerBaseUnitGtq']),
      source: PriceSource.fromString(json['source']?.toString()),
      quantityText: (json['quantityText'] ?? '1 unidad').toString(),
      supermarket: json['supermarket']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
