import 'ingredient_price_entry.dart';

/// Cost breakdown for a single recipe ingredient in GTQ.
class RecipeCostBreakdownItem {
  const RecipeCostBreakdownItem({
    required this.ingredientName,
    required this.displayAmount,
    required this.estimatedCostGtq,
    required this.source,
  });

  final String ingredientName;
  final String displayAmount;
  final double estimatedCostGtq;
  final PriceSource source;
}

/// Economic (GTQ) and nutritional comparison between preparing a recipe at home
/// and ordering an equivalent fast-food or delivery dish in Guatemala.
class RecipeHomeVsTakeoutComparison {
  const RecipeHomeVsTakeoutComparison({
    required this.recipeId,
    required this.servings,
    required this.homeTotalCostGtq,
    required this.homeCostPerServingGtq,
    required this.takeoutCostPerServingGtq,
    required this.savingsPerServingGtq,
    required this.savingsTotalGtq,
    required this.savingsPercent,
    required this.takeoutReferenceLabel,
    required this.nutritionHighlights,
    required this.usedReceiptPricesCount,
    required this.usedDealPricesCount,
    this.ingredientBreakdown = const [],
  });

  final String recipeId;
  final int servings;
  final double homeTotalCostGtq;
  final double homeCostPerServingGtq;
  final double takeoutCostPerServingGtq;
  final double savingsPerServingGtq;
  final double savingsTotalGtq;
  final int savingsPercent;
  final String takeoutReferenceLabel;
  final List<String> nutritionHighlights;
  final int usedReceiptPricesCount;
  final int usedDealPricesCount;
  final List<RecipeCostBreakdownItem> ingredientBreakdown;

  bool get hasSavings => savingsPerServingGtq > 0.05;

  String get formattedHomePerServing =>
      'Q ${homeCostPerServingGtq.toStringAsFixed(2)}';

  String get formattedHomeTotal => 'Q ${homeTotalCostGtq.toStringAsFixed(2)}';

  String get formattedTakeoutPerServing =>
      'Q ${takeoutCostPerServingGtq.toStringAsFixed(2)}';

  String get formattedSavingsPerServing =>
      'Q ${savingsPerServingGtq.toStringAsFixed(2)}';

  String get formattedSavingsTotal => 'Q ${savingsTotalGtq.toStringAsFixed(2)}';
}
