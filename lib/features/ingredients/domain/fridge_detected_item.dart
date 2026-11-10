/// Model representing an ingredient or product detected in a refrigerator or pantry photo.
class FridgeDetectedItem {
  const FridgeDetectedItem({
    required this.name,
    required this.standardIngredient,
    this.brand = 'Genérica',
    this.quantity = '1 unidad',
    this.confidence = 'medium',
    this.isLocalBrand = false,
    this.category = 'Varios',
    this.notes,
    this.isSelected = false,
  });

  /// Specific/commercial name detected in the photo (e.g. "Ketchup Pollo Campero").
  final String name;

  /// Standardized Spanish culinary ingredient name (e.g. "Ketchup").
  final String standardIngredient;

  /// Brand name if visible, or "Genérica" / "Casero".
  final String brand;

  /// Estimated quantity or container size (e.g. "1 botella de 397 g").
  final String quantity;

  /// Confidence level: 'high', 'medium', or 'low'.
  final String confidence;

  /// Whether the brand is a traditional Guatemalan or Central American brand.
  final bool isLocalBrand;

  /// Culinary category in Spanish.
  final String category;

  /// Additional notes or observations.
  final String? notes;

  /// Whether this item is selected for batch adding to the user's ingredients.
  final bool isSelected;

  /// Whether this item has high confidence.
  bool get isHighConfidence => confidence.toLowerCase() == 'high';

  /// Whether this item has medium confidence.
  bool get isMediumConfidence => confidence.toLowerCase() == 'medium';

  /// Whether this item has low confidence.
  bool get isLowConfidence => confidence.toLowerCase() == 'low';

  /// Human-readable confidence label in Spanish.
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

  /// Creates a copy of this item with modified fields.
  FridgeDetectedItem copyWith({
    String? name,
    String? standardIngredient,
    String? brand,
    String? quantity,
    String? confidence,
    bool? isLocalBrand,
    String? category,
    String? notes,
    bool? isSelected,
  }) {
    return FridgeDetectedItem(
      name: name ?? this.name,
      standardIngredient: standardIngredient ?? this.standardIngredient,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      confidence: confidence ?? this.confidence,
      isLocalBrand: isLocalBrand ?? this.isLocalBrand,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Deserializes a JSON map into a [FridgeDetectedItem].
  /// By default, high confidence items are pre-selected, while medium/low are unselected.
  factory FridgeDetectedItem.fromJson(Map<String, dynamic> json) {
    final rawConf = (json['confidence'] ?? json['confianza'] ?? 'medium')
        .toString()
        .toLowerCase();
    final normalizedConfidence = (rawConf == 'high' || rawConf == 'alta')
        ? 'high'
        : (rawConf == 'low' || rawConf == 'baja')
            ? 'low'
            : 'medium';

    final name = (json['name'] ?? json['producto'] ?? '').toString().trim();
    final standard = (json['standardIngredient'] ??
            json['ingrediente_estandar'] ??
            name)
        .toString()
        .trim();

    return FridgeDetectedItem(
      name: name.isNotEmpty ? name : standard,
      standardIngredient: standard.isNotEmpty ? standard : name,
      brand: (json['brand'] ?? json['marca'] ?? 'Genérica').toString().trim(),
      quantity: (json['quantity'] ??
              json['cantidad'] ??
              json['cantidad_estimada'] ??
              '1 unidad')
          .toString()
          .trim(),
      confidence: normalizedConfidence,
      isLocalBrand: json['isLocalBrand'] == true || json['es_marca_local'] == true,
      category: (json['category'] ?? json['categoria'] ?? 'Varios')
          .toString()
          .trim(),
      notes: json['notes']?.toString() ?? json['observaciones']?.toString(),
      isSelected: normalizedConfidence == 'high',
    );
  }

  /// Serializes this item to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'standardIngredient': standardIngredient,
      'brand': brand,
      'quantity': quantity,
      'confidence': confidence,
      'isLocalBrand': isLocalBrand,
      'category': category,
      if (notes != null) 'notes': notes,
      'isSelected': isSelected,
    };
  }
}
