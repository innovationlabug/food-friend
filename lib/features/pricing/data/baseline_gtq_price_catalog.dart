import '../../../core/utils/string_normalizer.dart';
import '../../recipes/domain/recipe.dart';
import '../domain/ingredient_price_entry.dart';
import 'quantity_parser.dart';

/// Baseline Guatemalan supermarket price profile for a culinary ingredient.
class BaselineIngredientPrice {
  const BaselineIngredientPrice({
    required this.canonicalName,
    required this.baseUnit,
    required this.pricePerBaseUnitGtq,
    required this.defaultPackageUnits,
    this.gramsPerUnit,
    this.gramsPerCup,
    this.isClovePriced = false,
    this.isBunchPriced = false,
  });

  factory BaselineIngredientPrice.perPound(
    String name,
    double gtqPerPound, {
    double? gramsPerUnit,
    double? gramsPerCup,
  }) {
    return BaselineIngredientPrice(
      canonicalName: name,
      baseUnit: PriceUnit.gram,
      pricePerBaseUnitGtq: gtqPerPound / 453.592,
      defaultPackageUnits: 453.592,
      gramsPerUnit: gramsPerUnit,
      gramsPerCup: gramsPerCup,
    );
  }

  factory BaselineIngredientPrice.per100g(
    String name,
    double gtqPer100g, {
    double defaultPackageGrams = 250.0,
    double? gramsPerUnit,
    double? gramsPerCup,
  }) {
    return BaselineIngredientPrice(
      canonicalName: name,
      baseUnit: PriceUnit.gram,
      pricePerBaseUnitGtq: gtqPer100g / 100.0,
      defaultPackageUnits: defaultPackageGrams,
      gramsPerUnit: gramsPerUnit,
      gramsPerCup: gramsPerCup,
    );
  }

  factory BaselineIngredientPrice.perLiter(
    String name,
    double gtqPerLiter, {
    double defaultPackageMl = 1000.0,
  }) {
    return BaselineIngredientPrice(
      canonicalName: name,
      baseUnit: PriceUnit.milliliter,
      pricePerBaseUnitGtq: gtqPerLiter / 1000.0,
      defaultPackageUnits: defaultPackageMl,
    );
  }

  factory BaselineIngredientPrice.perUnit(
    String name,
    double gtqPerUnit, {
    double? gramsPerUnit,
    double? gramsPerCup,
    double defaultPackageUnits = 1.0,
    bool isClovePriced = false,
    bool isBunchPriced = false,
  }) {
    return BaselineIngredientPrice(
      canonicalName: name,
      baseUnit: PriceUnit.unit,
      pricePerBaseUnitGtq: gtqPerUnit,
      defaultPackageUnits: defaultPackageUnits,
      gramsPerUnit: gramsPerUnit,
      gramsPerCup: gramsPerCup,
      isClovePriced: isClovePriced,
      isBunchPriced: isBunchPriced,
    );
  }

  final String canonicalName;
  final PriceUnit baseUnit;
  final double pricePerBaseUnitGtq;
  final double defaultPackageUnits;
  final double? gramsPerUnit;
  final double? gramsPerCup;
  final bool isClovePriced;
  final bool isBunchPriced;

  /// Converts a parsed recipe [quantity] into this ingredient's [baseUnit].
  double convertRecipeQuantityToBaseUnits(ParsedQuantity? quantity) {
    if (quantity == null) {
      return switch (baseUnit) {
        PriceUnit.gram => gramsPerUnit ?? 120.0,
        PriceUnit.milliliter => 30.0,
        PriceUnit.unit => 1.0,
      };
    }

    final val = quantity.value;
    switch (baseUnit) {
      case PriceUnit.gram:
        return switch (quantity.unit) {
          ParsedMeasureUnit.gram => val,
          ParsedMeasureUnit.kilogram => val * 1000.0,
          ParsedMeasureUnit.pound => val * 453.592,
          ParsedMeasureUnit.ounce => val * 28.3495,
          ParsedMeasureUnit.milliliter => val,
          ParsedMeasureUnit.liter => val * 1000.0,
          ParsedMeasureUnit.cup => val * (gramsPerCup ?? 150.0),
          ParsedMeasureUnit.tablespoon => val * 12.0,
          ParsedMeasureUnit.teaspoon => val * 4.0,
          ParsedMeasureUnit.unit => val * (gramsPerUnit ?? 150.0),
          ParsedMeasureUnit.fillet => val * (gramsPerUnit ?? 175.0),
          ParsedMeasureUnit.can => val * (gramsPerUnit ?? 170.0),
          ParsedMeasureUnit.bunch => val * (gramsPerUnit ?? 150.0),
          ParsedMeasureUnit.leaf => val * 12.0,
          ParsedMeasureUnit.sprig => val * 8.0,
          ParsedMeasureUnit.stalk => val * 40.0,
          ParsedMeasureUnit.clove => val * 5.0,
        };

      case PriceUnit.milliliter:
        return switch (quantity.unit) {
          ParsedMeasureUnit.milliliter => val,
          ParsedMeasureUnit.liter => val * 1000.0,
          ParsedMeasureUnit.cup => val * 240.0,
          ParsedMeasureUnit.tablespoon => val * 15.0,
          ParsedMeasureUnit.teaspoon => val * 5.0,
          ParsedMeasureUnit.gram => val,
          ParsedMeasureUnit.kilogram => val * 1000.0,
          ParsedMeasureUnit.pound => val * 453.592,
          ParsedMeasureUnit.ounce => val * 29.57,
          _ => val * 240.0,
        };

      case PriceUnit.unit:
        if (isClovePriced) {
          return switch (quantity.unit) {
            ParsedMeasureUnit.clove => val,
            ParsedMeasureUnit.unit => val * 10.0,
            ParsedMeasureUnit.tablespoon => val * 2.0,
            ParsedMeasureUnit.teaspoon => val,
            _ => val,
          };
        }
        if (isBunchPriced) {
          return switch (quantity.unit) {
            ParsedMeasureUnit.bunch => val,
            ParsedMeasureUnit.sprig => val * 0.1,
            ParsedMeasureUnit.leaf => val * 0.12,
            ParsedMeasureUnit.stalk => val * 0.2,
            ParsedMeasureUnit.cup => val * 0.6,
            ParsedMeasureUnit.tablespoon => val * 0.08,
            ParsedMeasureUnit.teaspoon => val * 0.03,
            _ => val,
          };
        }
        final unitGrams = gramsPerUnit ?? 130.0;
        return switch (quantity.unit) {
          ParsedMeasureUnit.unit ||
          ParsedMeasureUnit.can ||
          ParsedMeasureUnit.fillet ||
          ParsedMeasureUnit.clove ||
          ParsedMeasureUnit.sprig ||
          ParsedMeasureUnit.bunch ||
          ParsedMeasureUnit.leaf ||
          ParsedMeasureUnit.stalk =>
            val,
          ParsedMeasureUnit.gram => val / unitGrams,
          ParsedMeasureUnit.kilogram => (val * 1000.0) / unitGrams,
          ParsedMeasureUnit.pound => (val * 453.592) / unitGrams,
          ParsedMeasureUnit.ounce => (val * 28.3495) / unitGrams,
          ParsedMeasureUnit.cup => (val * (gramsPerCup ?? unitGrams)) / unitGrams,
          ParsedMeasureUnit.tablespoon => (val * 15.0) / unitGrams,
          ParsedMeasureUnit.teaspoon => (val * 5.0) / unitGrams,
          ParsedMeasureUnit.milliliter => val / unitGrams,
          ParsedMeasureUnit.liter => (val * 1000.0) / unitGrams,
        };
    }
  }

  /// Converts a retail/receipt package quantity string into this ingredient's [baseUnit].
  double convertPackageQuantityToBaseUnits(
    String quantityText, {
    String? productName,
    int unitCount = 1,
  }) {
    final safeCount = unitCount > 0 ? unitCount : 1;
    final parsed = QuantityParser.parse(quantityText) ??
        (productName != null ? QuantityParser.parse(productName) : null);
    final packMult = QuantityParser.extractPackMultiplier(
      '$quantityText ${productName ?? ''}',
    );

    if (parsed == null) {
      return defaultPackageUnits * safeCount * packMult;
    }

    // Check if parsed unit is compatible with baseUnit
    switch (baseUnit) {
      case PriceUnit.gram:
        if (parsed.unit == ParsedMeasureUnit.gram) {
          return parsed.value * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.kilogram) {
          return parsed.value * 1000.0 * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.pound) {
          return parsed.value * 453.592 * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.ounce) {
          return parsed.value * 28.3495 * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.unit && gramsPerUnit != null) {
          return parsed.value * gramsPerUnit! * safeCount;
        }
        return defaultPackageUnits * safeCount;

      case PriceUnit.milliliter:
        if (parsed.unit == ParsedMeasureUnit.milliliter) {
          return parsed.value * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.liter) {
          return parsed.value * 1000.0 * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.ounce) {
          return parsed.value * 29.57 * safeCount;
        }
        return defaultPackageUnits * safeCount * packMult;

      case PriceUnit.unit:
        if (isClovePriced) {
          // Receipt/package usually sells garlic by bulb/unit (~10 cloves each) or lb (~70 cloves)
          if (parsed.unit == ParsedMeasureUnit.pound) {
            return parsed.value * 70.0 * safeCount;
          }
          if (parsed.unit == ParsedMeasureUnit.gram) {
            return (parsed.value / 5.0) * safeCount;
          }
          if (parsed.unit == ParsedMeasureUnit.unit) {
            return parsed.value * 10.0 * safeCount;
          }
        }
        if (isBunchPriced) {
          return parsed.value * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.unit ||
            parsed.unit == ParsedMeasureUnit.can ||
            parsed.unit == ParsedMeasureUnit.fillet) {
          return parsed.value * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.gram && gramsPerUnit != null) {
          return (parsed.value / gramsPerUnit!) * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.kilogram && gramsPerUnit != null) {
          return ((parsed.value * 1000.0) / gramsPerUnit!) * safeCount;
        }
        if (parsed.unit == ParsedMeasureUnit.pound && gramsPerUnit != null) {
          return ((parsed.value * 453.592) / gramsPerUnit!) * safeCount;
        }
        return defaultPackageUnits * safeCount;
    }
  }
}

/// Curated local Guatemalan GTQ baseline price catalog for all staple ingredients
/// and typical takeout/delivery cost benchmarks.
class BaselineGtqPriceCatalog {
  BaselineGtqPriceCatalog._();

  static final Map<String, BaselineIngredientPrice> _prices = _buildPriceMap();

  /// Resolves a baseline GTQ price profile for [ingredientName], using exact
  /// normalized lookup, partial token match, or a deterministic category fallback.
  static BaselineIngredientPrice lookup(String ingredientName) {
    final norm = StringNormalizer.normalize(ingredientName);
    if (norm.isEmpty) {
      return BaselineIngredientPrice.perUnit(ingredientName, 3.00);
    }

    final exact = _prices[norm];
    if (exact != null) return exact;

    BaselineIngredientPrice? bestPartial;
    int bestLen = 0;
    for (final entry in _prices.entries) {
      if (entry.key.length > bestLen && _containsPhrase(norm, entry.key)) {
        bestPartial = entry.value;
        bestLen = entry.key.length;
      }
    }
    if (bestPartial != null) return bestPartial;

    // Deterministic category fallback for external/AI recipe ingredients
    if (_matchesAny(norm, ['salmon', 'camaron', 'robalo'])) {
      return BaselineIngredientPrice.perPound(ingredientName, 58.00, gramsPerUnit: 180);
    }
    if (_matchesAny(norm, ['pollo', 'pechuga', 'muslo', 'res', 'cerdo', 'carne', 'pescado', 'tilapia'])) {
      return BaselineIngredientPrice.perPound(ingredientName, 22.00, gramsPerUnit: 170);
    }
    if (_matchesAny(norm, ['queso', 'crema', 'yogur', 'mantequilla'])) {
      return BaselineIngredientPrice.per100g(ingredientName, 6.50, gramsPerCup: 120);
    }
    if (_matchesAny(norm, ['leche', 'aceite', 'vinagre', 'salsa'])) {
      return BaselineIngredientPrice.perLiter(ingredientName, 22.00);
    }
    if (_matchesAny(norm, ['arroz', 'frijol', 'lenteja', 'garbanzo', 'pasta', 'avena', 'harina'])) {
      return BaselineIngredientPrice.perPound(ingredientName, 9.00, gramsPerCup: 170);
    }
    if (_matchesAny(norm, ['cilantro', 'perejil', 'hierbabuena', 'epazote', 'albahaca', 'romero', 'tomillo', 'oregano'])) {
      return BaselineIngredientPrice.perUnit(ingredientName, 3.00, isBunchPriced: true);
    }

    return BaselineIngredientPrice.perUnit(
      ingredientName,
      3.00,
      gramsPerUnit: 130.0,
    );
  }

  /// Estimates typical Guatemalan fast-food or delivery cost per serving (GTQ)
  /// for an equivalent meal to [recipe].
  static double estimateTakeoutCostPerServing(Recipe recipe) {
    return resolveTakeoutBenchmark(recipe).costPerServingGtq;
  }

  /// Short Spanish descriptor of the takeout benchmark used for [recipe].
  static String takeoutReferenceLabel(Recipe recipe) {
    return resolveTakeoutBenchmark(recipe).label;
  }

  /// Resolves both the Spanish reference label and benchmark GTQ price per
  /// serving for [recipe] based on its meal category, dish style, and protein.
  static ({String label, double costPerServingGtq}) resolveTakeoutBenchmark(
    Recipe recipe,
  ) {
    final cat = StringNormalizer.normalize(recipe.category ?? '');
    final title = StringNormalizer.normalize(recipe.title);
    final ingText = recipe.ingredients
        .map((i) => StringNormalizer.normalize(i.name))
        .join(' ');

    if (cat.contains('desayuno')) {
      if (_matchesAny(title, ['avena', 'panqueque'])) {
        return (
          label: 'Desayuno de avena o panqueques a domicilio',
          costPerServingGtq: 38.00,
        );
      }
      return (
        label: 'Desayuno típico o con huevos a domicilio',
        costPerServingGtq: 48.00,
      );
    }

    if (cat.contains('ensalada')) {
      if (_matchesAny(ingText, ['camaron', 'salmon'])) {
        return (
          label: 'Ensalada con mariscos a domicilio',
          costPerServingGtq: 65.00,
        );
      }
      if (_matchesAny(ingText, ['pollo', 'pechuga', 'atun'])) {
        return (
          label: 'Ensalada con pollo o atún a domicilio',
          costPerServingGtq: 54.00,
        );
      }
      return (
        label: 'Ensalada fresca o ceviche a domicilio',
        costPerServingGtq: 45.00,
      );
    }

    if (cat.contains('sopa') || cat.contains('caldo')) {
      if (_matchesAny(ingText, ['pollo', 'pechuga', 'pescado', 'tilapia'])) {
        return (
          label: 'Caldo o sopa con proteína a domicilio',
          costPerServingGtq: 48.00,
        );
      }
      return (
        label: 'Sopa o crema casera a domicilio',
        costPerServingGtq: 38.00,
      );
    }

    // Main dishes (Almuerzo / Cena)
    if (_matchesAny(ingText, ['salmon', 'camaron', 'robalo'])) {
      return (
        label: 'Plato de mariscos o salmón a domicilio',
        costPerServingGtq: 115.00,
      );
    }
    if (_matchesAny(title, ['pasta']) ||
        _matchesAny(ingText, ['pasta', 'espagueti', 'fideos'])) {
      return (
        label: 'Plato de pasta a domicilio',
        costPerServingGtq: 75.00,
      );
    }
    if (_matchesAny(title, ['pepian', 'hilachas', 'salpicon', 'guiso']) ||
        _matchesAny(title, ['arroz con pollo', 'tortitas de ejote'])) {
      return (
        label: 'Plato típico guatemalteco a domicilio',
        costPerServingGtq: 69.00,
      );
    }
    if (_matchesAny(ingText, [
      'lomo de res',
      'posta de res',
      'carne de res',
      'carne molida',
      'lomo de cerdo',
    ])) {
      return (
        label: 'Plato de res o cerdo a domicilio',
        costPerServingGtq: 89.00,
      );
    }
    if (_matchesAny(ingText, ['filete de pescado', 'tilapia', 'atun'])) {
      return (
        label: 'Plato de pescado a domicilio',
        costPerServingGtq: 75.00,
      );
    }
    if (_matchesAny(ingText, ['pollo', 'pechuga'])) {
      return (
        label: 'Plato de pollo a domicilio',
        costPerServingGtq: 79.00,
      );
    }
    if (_matchesAny(ingText, ['frijoles', 'garbanzos', 'lentejas', 'huevo']) ||
        _matchesAny(title, ['salteado de verduras'])) {
      return (
        label: 'Plato vegetariano o tazón a domicilio',
        costPerServingGtq: 51.00,
      );
    }

    return (
      label: 'Plato similar a domicilio',
      costPerServingGtq: 60.00,
    );
  }

  static bool _containsPhrase(String haystack, String needle) {
    if (haystack == needle) return true;
    return ' $haystack '.contains(' $needle ');
  }

  static bool _matchesAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  static Map<String, BaselineIngredientPrice> _buildPriceMap() {
    final list = <BaselineIngredientPrice>[
      // Proteins & seafood (GTQ / lb or unit)
      BaselineIngredientPrice.perPound('Pollo', 18.00, gramsPerUnit: 170),
      BaselineIngredientPrice.perPound('Pechuga de pollo', 24.00, gramsPerUnit: 180),
      BaselineIngredientPrice.perPound('Pollo desmenuzado', 24.00, gramsPerCup: 140),
      BaselineIngredientPrice.perPound('Muslos de pollo', 17.50, gramsPerUnit: 150),
      BaselineIngredientPrice.perPound('Cuadriles de pollo', 17.00, gramsPerUnit: 160),
      BaselineIngredientPrice.perPound('Carne de res', 32.00, gramsPerUnit: 170),
      BaselineIngredientPrice.perPound('Posta de res', 34.00, gramsPerUnit: 170),
      BaselineIngredientPrice.perPound('Carne molida de res', 30.00, gramsPerUnit: 160),
      BaselineIngredientPrice.perPound('Lomo de res', 44.00, gramsPerUnit: 180),
      BaselineIngredientPrice.perPound('Lomo de cerdo', 28.00, gramsPerUnit: 170),
      BaselineIngredientPrice.perPound('Filete de pescado', 32.00, gramsPerUnit: 180),
      BaselineIngredientPrice.perPound('Filete de tilapia', 29.00, gramsPerUnit: 170),
      BaselineIngredientPrice.perPound('Filete de robalo', 45.00, gramsPerUnit: 180),
      BaselineIngredientPrice.perPound('Salmón', 72.00, gramsPerUnit: 170),
      BaselineIngredientPrice.perPound('Camarones', 56.00, gramsPerUnit: 150),
      BaselineIngredientPrice.perUnit('Atún en lata', 11.50, gramsPerUnit: 140),
      BaselineIngredientPrice.perUnit('Huevo', 1.75, gramsPerUnit: 55),
      BaselineIngredientPrice.perUnit('Huevos', 1.75, gramsPerUnit: 55),
      BaselineIngredientPrice.perPound('Jamón', 32.00, gramsPerUnit: 30),
      BaselineIngredientPrice.perPound('Salchicha', 22.00, gramsPerUnit: 45),
      BaselineIngredientPrice.perPound('Chorizo', 28.00, gramsPerUnit: 60),
      BaselineIngredientPrice.perPound('Longaniza', 26.00, gramsPerUnit: 75),
      BaselineIngredientPrice.perPound('Tocino', 38.00, gramsPerUnit: 25),

      // Dairy & fats
      BaselineIngredientPrice.per100g('Queso de capas', 6.80, defaultPackageGrams: 225, gramsPerUnit: 30, gramsPerCup: 115),
      BaselineIngredientPrice.per100g('Queso fresco', 5.80, defaultPackageGrams: 250, gramsPerUnit: 30, gramsPerCup: 120),
      BaselineIngredientPrice.per100g('Queso gouda', 9.50, defaultPackageGrams: 200, gramsPerUnit: 30, gramsPerCup: 115),
      BaselineIngredientPrice.per100g('Queso parmesano', 14.00, defaultPackageGrams: 120, gramsPerUnit: 20, gramsPerCup: 100),
      BaselineIngredientPrice.per100g('Queso mozzarella', 8.50, defaultPackageGrams: 225, gramsPerUnit: 30, gramsPerCup: 115),
      BaselineIngredientPrice.per100g('Queso cheddar', 9.00, defaultPackageGrams: 200, gramsPerUnit: 30, gramsPerCup: 115),
      BaselineIngredientPrice.per100g('Crema pura', 4.50, defaultPackageGrams: 235, gramsPerCup: 240),
      BaselineIngredientPrice.per100g('Crema fresca', 4.20, defaultPackageGrams: 235, gramsPerCup: 240),
      BaselineIngredientPrice.per100g('Yogur natural', 3.60, defaultPackageGrams: 200, gramsPerCup: 245),
      BaselineIngredientPrice.per100g('Yogur griego', 5.40, defaultPackageGrams: 170, gramsPerCup: 245),
      BaselineIngredientPrice.per100g('Mantequilla', 7.50, defaultPackageGrams: 200, gramsPerCup: 225),
      BaselineIngredientPrice.perLiter('Leche descremada', 16.50, defaultPackageMl: 1000),
      BaselineIngredientPrice.perLiter('Leche entera', 15.50, defaultPackageMl: 1000),
      BaselineIngredientPrice.perLiter('Leche deslactosada', 17.50, defaultPackageMl: 1000),
      BaselineIngredientPrice.perLiter('Aceite de oliva', 68.00, defaultPackageMl: 500),
      BaselineIngredientPrice.perLiter('Aceite vegetal', 22.00, defaultPackageMl: 750),
      BaselineIngredientPrice.perLiter('Aceite de maíz', 24.00, defaultPackageMl: 750),
      BaselineIngredientPrice.perLiter('Vinagre de manzana', 26.00, defaultPackageMl: 500),
      BaselineIngredientPrice.perLiter('Vinagre blanco', 14.00, defaultPackageMl: 500),

      // Grains, legumes & dry staples
      BaselineIngredientPrice.perPound('Arroz blanco', 6.50, gramsPerCup: 185),
      BaselineIngredientPrice.perPound('Arroz precocido', 7.50, gramsPerCup: 185),
      BaselineIngredientPrice.perPound('Arroz integral', 9.50, gramsPerCup: 185),
      BaselineIngredientPrice.perPound('Frijoles negros', 10.50, gramsPerCup: 180),
      BaselineIngredientPrice.perPound('Frijol negro', 10.50, gramsPerCup: 180),
      BaselineIngredientPrice.perPound('Frijoles colorados', 11.00, gramsPerCup: 180),
      BaselineIngredientPrice.perPound('Lentejas', 11.50, gramsPerCup: 185),
      BaselineIngredientPrice.perPound('Garbanzos', 12.50, gramsPerCup: 175),
      BaselineIngredientPrice.perPound('Avena en hojuelas', 9.00, gramsPerCup: 90),
      BaselineIngredientPrice.perPound('Pasta', 9.50, gramsPerCup: 110),
      BaselineIngredientPrice.perPound('Fideos', 9.00, gramsPerCup: 110),
      BaselineIngredientPrice.perPound('Espagueti', 9.50, gramsPerCup: 110),
      BaselineIngredientPrice.perPound('Harina de maíz', 7.00, gramsPerCup: 120),
      BaselineIngredientPrice.perPound('Harina de trigo', 6.50, gramsPerCup: 120),
      BaselineIngredientPrice.per100g('Maní', 4.50, defaultPackageGrams: 200, gramsPerCup: 145),
      BaselineIngredientPrice.per100g('Almendras', 12.00, defaultPackageGrams: 150, gramsPerCup: 140),
      BaselineIngredientPrice.per100g('Nueces', 14.00, defaultPackageGrams: 150, gramsPerCup: 120),
      BaselineIngredientPrice.per100g('Ajonjolí', 5.50, defaultPackageGrams: 100, gramsPerCup: 140),
      BaselineIngredientPrice.per100g('Semillas de girasol', 6.50, defaultPackageGrams: 150, gramsPerCup: 135),

      // Vegetables & fresh herbs
      BaselineIngredientPrice.perUnit('Tomate', 1.25, gramsPerUnit: 120, gramsPerCup: 180),
      BaselineIngredientPrice.perUnit('Miltomate', 0.65, gramsPerUnit: 40, gramsPerCup: 150),
      BaselineIngredientPrice.perUnit('Cebolla blanca', 2.00, gramsPerUnit: 140, gramsPerCup: 160),
      BaselineIngredientPrice.perUnit('Cebolla morada', 2.25, gramsPerUnit: 140, gramsPerCup: 160),
      BaselineIngredientPrice.perUnit('Ajo', 0.35, defaultPackageUnits: 10, isClovePriced: true),
      BaselineIngredientPrice.perUnit('Chile pimiento', 3.25, gramsPerUnit: 150, gramsPerCup: 140),
      BaselineIngredientPrice.perUnit('Chile pasa', 1.50, gramsPerUnit: 20),
      BaselineIngredientPrice.perUnit('Chile guaque', 1.50, gramsPerUnit: 20),
      BaselineIngredientPrice.perUnit('Güisquil', 3.50, gramsPerUnit: 250, gramsPerCup: 140),
      BaselineIngredientPrice.perUnit('Perulero', 3.00, gramsPerUnit: 220, gramsPerCup: 140),
      BaselineIngredientPrice.perUnit('Güicoy', 4.00, gramsPerUnit: 280, gramsPerCup: 140),
      BaselineIngredientPrice.perUnit('Ayote', 6.00, gramsPerUnit: 450, gramsPerCup: 150),
      BaselineIngredientPrice.perUnit('Papa', 2.00, gramsPerUnit: 160, gramsPerCup: 150),
      BaselineIngredientPrice.perUnit('Camote', 3.50, gramsPerUnit: 220, gramsPerCup: 150),
      BaselineIngredientPrice.perUnit('Zanahoria', 1.75, gramsPerUnit: 120, gramsPerCup: 130),
      BaselineIngredientPrice.perPound('Ejote', 8.00, gramsPerUnit: 10, gramsPerCup: 120),
      BaselineIngredientPrice.perPound('Arveja', 10.00, gramsPerCup: 140),
      BaselineIngredientPrice.perPound('Arveja china', 12.00, gramsPerCup: 120),
      BaselineIngredientPrice.perUnit('Elote', 2.50, gramsPerUnit: 220, gramsPerCup: 165),
      BaselineIngredientPrice.perUnit('Aguacate', 5.50, gramsPerUnit: 180, gramsPerCup: 150),
      BaselineIngredientPrice.perUnit('Pepino', 2.75, gramsPerUnit: 220, gramsPerCup: 120),
      BaselineIngredientPrice.perUnit('Rábano', 0.60, gramsPerUnit: 25),
      BaselineIngredientPrice.perUnit('Remolacha', 3.00, gramsPerUnit: 180, gramsPerCup: 140),
      BaselineIngredientPrice.perUnit('Repollo blanco', 7.00, gramsPerUnit: 750, gramsPerCup: 85),
      BaselineIngredientPrice.perUnit('Lechuga', 6.50, gramsPerUnit: 300, gramsPerCup: 55),
      BaselineIngredientPrice.per100g('Brócoli', 3.20, defaultPackageGrams: 350, gramsPerUnit: 320, gramsPerCup: 95),
      BaselineIngredientPrice.per100g('Coliflor', 3.20, defaultPackageGrams: 400, gramsPerUnit: 400, gramsPerCup: 100),
      BaselineIngredientPrice.per100g('Champiñones', 8.50, defaultPackageGrams: 200, gramsPerUnit: 20, gramsPerCup: 75),
      BaselineIngredientPrice.per100g('Espinaca', 4.50, defaultPackageGrams: 180, gramsPerUnit: 180, gramsPerCup: 40),
      BaselineIngredientPrice.per100g('Acelga', 3.80, defaultPackageGrams: 200, gramsPerUnit: 200, gramsPerCup: 45),
      BaselineIngredientPrice.per100g('Berro', 4.00, defaultPackageGrams: 150, gramsPerUnit: 150, gramsPerCup: 40),
      BaselineIngredientPrice.perUnit('Apio', 4.50, isBunchPriced: true),
      BaselineIngredientPrice.perUnit('Cilantro', 3.00, isBunchPriced: true),
      BaselineIngredientPrice.perUnit('Hierbabuena', 3.00, isBunchPriced: true),
      BaselineIngredientPrice.perUnit('Epazote', 3.00, isBunchPriced: true),
      BaselineIngredientPrice.perUnit('Perejil', 3.50, isBunchPriced: true),

      // Fruits
      BaselineIngredientPrice.perUnit('Limón', 0.80, gramsPerUnit: 55),
      BaselineIngredientPrice.perUnit('Naranja', 1.50, gramsPerUnit: 160),
      BaselineIngredientPrice.perUnit('Banano', 1.15, gramsPerUnit: 120),
      BaselineIngredientPrice.perUnit('Plátano maduro', 2.75, gramsPerUnit: 220),
      BaselineIngredientPrice.perUnit('Manzana', 3.00, gramsPerUnit: 160, gramsPerCup: 125),
      BaselineIngredientPrice.perUnit('Mango', 3.50, gramsPerUnit: 220, gramsPerCup: 165),
      BaselineIngredientPrice.per100g('Fresa', 5.50, defaultPackageGrams: 400, gramsPerCup: 150),

      // Spices & pantry condiments
      BaselineIngredientPrice.per100g('Curry', 12.00, defaultPackageGrams: 60),
      BaselineIngredientPrice.per100g('Comino molido', 10.00, defaultPackageGrams: 60),
      BaselineIngredientPrice.per100g('Cúrcuma', 12.00, defaultPackageGrams: 60),
      BaselineIngredientPrice.per100g('Páprika', 11.00, defaultPackageGrams: 60),
      BaselineIngredientPrice.per100g('Canela en polvo', 11.00, defaultPackageGrams: 60),
      BaselineIngredientPrice.per100g('Orégano seco', 9.50, defaultPackageGrams: 40),
      BaselineIngredientPrice.per100g('Tomillo', 9.50, defaultPackageGrams: 40),
      BaselineIngredientPrice.per100g('Romero', 9.50, defaultPackageGrams: 40),
      BaselineIngredientPrice.per100g('Jengibre', 4.50, defaultPackageGrams: 150),
      BaselineIngredientPrice.per100g('Achiote en pasta', 5.50, defaultPackageGrams: 100),
    ];

    return {
      for (final item in list) StringNormalizer.normalize(item.canonicalName): item,
    };
  }
}
