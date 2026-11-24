import 'supermarket_deal.dart';

/// Category explaining why a supermarket deal is relevant to the user.
enum SaleMatchReasonType {
  shoppingList,
  favoriteRecipe,
  frequentIngredient,
}

/// Spanish explanation linking a supermarket deal to a user need.
class SaleMatchReason {
  const SaleMatchReason({
    required this.type,
    required this.ingredientName,
    required this.label,
    this.recipeTitle,
    this.timesUsed,
  });

  final SaleMatchReasonType type;
  final String ingredientName;
  final String label;
  final String? recipeTitle;
  final int? timesUsed;
}

/// A [SupermarketDeal] annotated with user-specific match reasons and ranking.
class MatchedSaleDeal {
  const MatchedSaleDeal({
    required this.deal,
    required this.reasons,
    required this.matchScore,
    required this.isInShoppingList,
    required this.suggestedShoppingItemName,
    this.isFavoriteSupermarket = false,
  });

  final SupermarketDeal deal;
  final List<SaleMatchReason> reasons;
  final int matchScore;
  final bool isInShoppingList;
  final String suggestedShoppingItemName;
  final bool isFavoriteSupermarket;

  bool get isMatched => reasons.isNotEmpty;
}
