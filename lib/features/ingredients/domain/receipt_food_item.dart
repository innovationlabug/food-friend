/// Model representing an edible ingredient/food item extracted from a supermarket receipt.
class ReceiptFoodItem {
  const ReceiptFoodItem({
    required this.rawName,
    required this.standardIngredient,
    this.brand = 'Genérica',
    this.category = 'Abarrotes',
    this.quantity = '1 unidad',
    this.unitCount = 1,
    this.priceGtq,
    this.totalPriceGtq,
    this.confidence = 'medium',
    this.isSelected = false,
  });

  /// Printed line description from the receipt (e.g. "MOLINERO AR/BLA 400G").
  final String rawName;

  /// Clean, standardized culinary ingredient name in Spanish (e.g. "Arroz blanco").
  final String standardIngredient;

  /// Brand name if recognized.
  final String brand;

  /// Culinary category in Spanish.
  final String category;

  /// Quantity or weight string.
  final String quantity;

  /// Number of units purchased.
  final int unitCount;

  /// Unit price in Guatemalan Quetzales (GTQ / Q).
  final double? priceGtq;

  /// Total price paid for this item in Quetzales (GTQ / Q).
  final double? totalPriceGtq;

  /// Confidence level: 'high', 'medium', or 'low'.
  final String confidence;

  /// Whether this item is selected for batch adding to the user's available ingredients.
  final bool isSelected;

  /// Whether confidence is high.
  bool get isHighConfidence => confidence.toLowerCase() == 'high';

  /// Whether confidence is medium.
  bool get isMediumConfidence => confidence.toLowerCase() == 'medium';

  /// Whether confidence is low.
  bool get isLowConfidence => confidence.toLowerCase() == 'low';

  /// Spanish label for confidence level.
  String get confidenceLabel {
    switch (confidence.toLowerCase()) {
      case 'high':
        return 'Alta';
      case 'low':
        return 'Baja';
      case 'medium':
      default:
        return 'Media';
    }
  }

  /// Formatted total price in Guatemalan Quetzales (e.g. "Q 16.90").
  String? get formattedPrice {
    final price = totalPriceGtq ?? priceGtq;
    if (price == null) return null;
    return 'Q ${price.toStringAsFixed(2)}';
  }

  /// Creates a copy with modified fields.
  ReceiptFoodItem copyWith({
    String? rawName,
    String? standardIngredient,
    String? brand,
    String? category,
    String? quantity,
    int? unitCount,
    double? priceGtq,
    double? totalPriceGtq,
    String? confidence,
    bool? isSelected,
  }) {
    return ReceiptFoodItem(
      rawName: rawName ?? this.rawName,
      standardIngredient: standardIngredient ?? this.standardIngredient,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unitCount: unitCount ?? this.unitCount,
      priceGtq: priceGtq ?? this.priceGtq,
      totalPriceGtq: totalPriceGtq ?? this.totalPriceGtq,
      confidence: confidence ?? this.confidence,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Deserializes a JSON map into a [ReceiptFoodItem].
  /// By default, high confidence items are pre-selected, while medium/low are unselected.
  factory ReceiptFoodItem.fromJson(Map<String, dynamic> json) {
    final rawConf = (json['confidence'] ?? json['confianza'] ?? 'medium')
        .toString()
        .toLowerCase();
    final normalizedConfidence = (rawConf == 'high' || rawConf == 'alta')
        ? 'high'
        : (rawConf == 'low' || rawConf == 'baja')
            ? 'low'
            : 'medium';

    final rawName =
        (json['rawName'] ?? json['nombre_ticket'] ?? '').toString().trim();
    final standard = (json['standardIngredient'] ??
            json['ingrediente_estandar'] ??
            rawName)
        .toString()
        .trim();

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final price = parseDouble(json['priceGtq'] ?? json['precio_unitario_gtq']);
    final total = parseDouble(json['totalPriceGtq'] ?? json['precio_total_gtq']) ?? price;

    final unitCount = json['unitCount'] is int
        ? json['unitCount'] as int
        : int.tryParse(json['unitCount']?.toString() ?? '') ?? 1;

    return ReceiptFoodItem(
      rawName: rawName.isNotEmpty ? rawName : standard,
      standardIngredient: standard.isNotEmpty ? standard : rawName,
      brand: (json['brand'] ?? json['marca'] ?? 'Genérica').toString().trim(),
      category: (json['category'] ?? json['categoria'] ?? 'Abarrotes')
          .toString()
          .trim(),
      quantity: (json['quantity'] ??
              json['cantidad_o_peso'] ??
              '1 unidad')
          .toString()
          .trim(),
      unitCount: unitCount,
      priceGtq: price,
      totalPriceGtq: total,
      confidence: normalizedConfidence,
      isSelected: normalizedConfidence == 'high',
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() {
    return {
      'rawName': rawName,
      'standardIngredient': standardIngredient,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'unitCount': unitCount,
      if (priceGtq != null) 'priceGtq': priceGtq,
      if (totalPriceGtq != null) 'totalPriceGtq': totalPriceGtq,
      'confidence': confidence,
      'isSelected': isSelected,
    };
  }
}

