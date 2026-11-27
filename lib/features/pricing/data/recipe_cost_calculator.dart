import '../../../core/utils/string_normalizer.dart';
import '../../nutrition/data/nutrition_catalog.dart';
import '../../nutrition/domain/nutrition_metadata.dart';
import '../../recipes/data/recipe_search_service.dart';
import '../../recipes/domain/recipe.dart';
import '../../sales/domain/supermarket_deal.dart';
import '../domain/ingredient_price_entry.dart';
import '../domain/recipe_comparison.dart';
import 'baseline_gtq_price_catalog.dart';
import 'ingredient_price_storage_service.dart';
import 'quantity_parser.dart';

/// Deterministic calculator estimating home cooking costs in GTQ (`Q / porción`)
/// and nutritional quality differences versus typical takeout/delivery meals.
/// Runs 100% locally on device with zero extra LLM calls.
class RecipeCostCalculator {
  RecipeCostCalculator._();

  /// Computes a full economic (GTQ) and nutritional home-vs-takeout comparison
  /// for [recipe] using persisted receipt prices first, then supermarket deals,
  /// then [BaselineGtqPriceCatalog].
  static RecipeHomeVsTakeoutComparison compareRecipe(
    Recipe recipe, {
    Map<String, IngredientPriceEntry> savedPrices = const {},
    List<SupermarketDeal> deals = const [],
  }) {
    final servings =
        (recipe.servings != null && recipe.servings! > 0) ? recipe.servings! : 2;

    double totalCost = 0.0;
    int receiptCount = 0;
    int dealCount = 0;
    final breakdown = <RecipeCostBreakdownItem>[];

    for (final ing in recipe.ingredients) {
      final baseline = BaselineGtqPriceCatalog.lookup(ing.name);
      final parsedQty = QuantityParser.parse(ing.displayAmount);
      final amountInBase = baseline.convertRecipeQuantityToBaseUnits(parsedQty);

      double unitPrice = baseline.pricePerBaseUnitGtq;
      PriceSource source = PriceSource.baseline;

      // 1. Persisted receipt (or previously saved deal) price matching ingredient
      final saved = _findSavedPrice(ing.name, savedPrices);
      if (saved != null &&
          saved.baseUnit == baseline.baseUnit &&
          saved.pricePerBaseUnitGtq > 0) {
        unitPrice = saved.pricePerBaseUnitGtq;
        source = saved.source;
      } else {
        // 2. Active/cached supermarket deal matching ingredient
        for (final deal in deals) {
          final dealUnitPrice = IngredientPriceStorageService.dealPricePerBaseUnit(
            deal,
            ing.name,
            baseline,
          );
          if (dealUnitPrice != null && dealUnitPrice > 0) {
            unitPrice = dealUnitPrice;
            source = PriceSource.supermarketDeal;
            break;
          }
        }
      }

      if (source == PriceSource.receipt) {
        receiptCount++;
      } else if (source == PriceSource.supermarketDeal) {
        dealCount++;
      }

      final lineCost = _roundGtq((amountInBase * unitPrice).clamp(0.15, 250.0));
      totalCost += lineCost;

      breakdown.add(
        RecipeCostBreakdownItem(
          ingredientName: ing.name,
          displayAmount: ing.displayAmount,
          estimatedCostGtq: lineCost,
          source: source,
        ),
      );
    }

    // Add minor staple allowance (salt/water/cooking energy) if recipe has ingredients
    if (recipe.ingredients.isNotEmpty) {
      totalCost += 0.75;
    }

    final roundedTotal = _roundGtq(totalCost);
    final perServing = _roundGtq(roundedTotal / servings);
    final takeoutPerServing =
        BaselineGtqPriceCatalog.estimateTakeoutCostPerServing(recipe);
    final savingsPerServing = _roundGtq(takeoutPerServing - perServing);
    final savingsTotal = _roundGtq(savingsPerServing * servings);
    final savingsPercent = takeoutPerServing > 0 && savingsPerServing > 0
        ? ((savingsPerServing / takeoutPerServing) * 100).round().clamp(1, 99)
        : 0;

    final nutritionHighlights = buildNutritionComparison(recipe);

    return RecipeHomeVsTakeoutComparison(
      recipeId: recipe.id,
      servings: servings,
      homeTotalCostGtq: roundedTotal,
      homeCostPerServingGtq: perServing,
      takeoutCostPerServingGtq: takeoutPerServing,
      savingsPerServingGtq: savingsPerServing,
      savingsTotalGtq: savingsTotal,
      savingsPercent: savingsPercent,
      takeoutReferenceLabel:
          BaselineGtqPriceCatalog.takeoutReferenceLabel(recipe),
      nutritionHighlights: nutritionHighlights,
      usedReceiptPricesCount: receiptCount,
      usedDealPricesCount: dealCount,
      ingredientBreakdown: breakdown,
    );
  }

  /// Generates 2 to 3 deterministic Spanish nutritional quality bullets comparing
  /// [recipe] made at home against typical fast food or delivery equivalents.
  static List<String> buildNutritionComparison(Recipe recipe) {
    final profiles = recipe.ingredients
        .map((ing) => NutritionCatalog.evaluateIngredient(ing.name))
        .toList();

    final hasProcessedMeat = profiles.any((p) => p.isProcessedMeat);
    final hasHighSodium = profiles.any((p) => p.isHighSodiumOrProcessed);
    final hasCalorieDense = profiles.any((p) => p.isCalorieDense) ||
        recipe.nutritionAttributes.contains(NutritionalAttribute.calorieDense);

    final produceProfiles = profiles
        .where((p) => p.isHighFiberOrVitamins || p.nutrients.isNotEmpty)
        .toList();
    final cleanProteinProfiles = profiles
        .where((p) => p.isHighProtein && !p.isProcessedMeat)
        .toList();

    final trackedNutrients = <TrackedNutrient>{};
    for (final p in profiles) {
      trackedNutrients.addAll(p.nutrients);
    }

    final usesHealthyFat = recipe.ingredients.any((ing) {
      final norm = ing.normalizedName;
      return norm.contains('aguacate') || norm.contains('aceite de oliva');
    });

    final highlights = <String>[];

    // 1. Sodium & ultraprocessed fat comparison
    if (!hasProcessedMeat && !hasHighSodium) {
      highlights.add(
        'Menos sodio y sin ultraprocesados frente a comida rápida, controlando la sal y el aceite.',
      );
    } else if (!hasProcessedMeat) {
      highlights.add(
        'Menos aditivos y aceites reutilizados que el domicilio; puedes moderar la sal al cocinar.',
      );
    } else {
      highlights.add(
        'Controlas el aceite y el tamaño de la porción frente al domicilio; evita exceso de embutidos para reducir sodio.',
      );
    }

    // 2. Fiber & vitamins comparison
    if (produceProfiles.isNotEmpty ||
        recipe.nutritionAttributes
            .contains(NutritionalAttribute.highFiberOrVitamins)) {
      if (trackedNutrients.isNotEmpty) {
        final topLabels =
            trackedNutrients.take(2).map((n) => n.label).join(' y ');
        highlights.add(
          'Aporta más fibra natural y micronutrientes ($topLabels) que un combo típico a domicilio.',
        );
      } else {
        highlights.add(
          'Mayor aporte de fibra y vegetales frescos frente a acompañamientos fritos de entrega.',
        );
      }
    }

    // 3. Protein quality or calorie density / healthy fats
    if (cleanProteinProfiles.isNotEmpty) {
      final proteinName = cleanProteinProfiles.first.canonicalName.toLowerCase();
      highlights.add(
        'Proteína de mejor calidad ($proteinName) sin empanizados ni frituras industriales.',
      );
    } else if (usesHealthyFat) {
      highlights.add(
        'Incluye grasas saludables naturales en lugar de aceites refinados de restaurante.',
      );
    } else if (recipe.nutritionAttributes
            .contains(NutritionalAttribute.lowCalorieDensity) &&
        !hasCalorieDense) {
      highlights.add(
        'Menor densidad calórica al prepararse en casa sin salsas pesadas ni frituras.',
      );
    }

    if (highlights.length < 2) {
      highlights.add(
        'Preparación casera con ingredientes frescos y control real de porciones.',
      );
    }

    return highlights.take(3).toList();
  }

  static IngredientPriceEntry? _findSavedPrice(
    String ingredientName,
    Map<String, IngredientPriceEntry> savedPrices,
  ) {
    if (savedPrices.isEmpty) return null;
    final norm = StringNormalizer.normalize(ingredientName);
    if (norm.isEmpty) return null;

    final exact = savedPrices[norm];
    if (exact != null) return exact;

    for (final entry in savedPrices.entries) {
      if (RecipeSearchService.isIngredientMatch(entry.key, norm)) {
        return entry.value;
      }
    }
    return null;
  }

  static double _roundGtq(double value) => (value * 100).roundToDouble() / 100;
}
