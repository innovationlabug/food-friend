import '../../../core/utils/string_normalizer.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../recipes/data/recipe_history_service.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_history_record.dart';
import '../../recipes/domain/recipe_preference.dart';
import '../../shopping_list/data/shopping_list_storage_service.dart';
import '../domain/matched_sale_deal.dart';
import '../domain/supermarket_deal.dart';
import 'sales_service.dart';

/// Summary of personalized supermarket sales matched against the user's
/// shopping list, favorite recipes, and frequently used pantry ingredients.
class SalesMatchReport {
  const SalesMatchReport({
    required this.matchedDeals,
    required this.allDeals,
    required this.totalPotentialSavingsGtq,
    required this.shoppingListMatchesCount,
    this.favoriteSupermarketId,
  });

  final List<MatchedSaleDeal> matchedDeals;
  final List<MatchedSaleDeal> allDeals;
  final double totalPotentialSavingsGtq;
  final int shoppingListMatchesCount;
  final String? favoriteSupermarketId;

  bool get hasMatches => matchedDeals.isNotEmpty;

  String get formattedTotalSavings =>
      'Q ${totalPotentialSavingsGtq.toStringAsFixed(2)}';
}

/// Deterministic on-device engine that cross-references supermarket deals
/// against `"Por comprar"`, `Favorita` recipes, and frequent pantry ingredients
/// (`timesUsed > 0`) with zero LLM calls.
class SalesMatcherService {
  SalesMatcherService({
    SalesService? salesService,
    IngredientStorageService? ingredientStorageService,
    ShoppingListStorageService? shoppingListService,
    RecipeHistoryService? historyService,
  })  : _salesService = salesService ?? SalesService(),
        _ingredientStorageService =
            ingredientStorageService ?? IngredientStorageService(),
        _shoppingListService = shoppingListService ??
            ShoppingListStorageService(
              pantryStorageService:
                  ingredientStorageService ?? IngredientStorageService(),
            ),
        _historyService = historyService ??
            RecipeHistoryService(
              ingredientStorageService:
                  ingredientStorageService ?? IngredientStorageService(),
            );

  final SalesService _salesService;
  final IngredientStorageService _ingredientStorageService;
  final ShoppingListStorageService _shoppingListService;
  final RecipeHistoryService _historyService;

  static const Set<String> _stopWords = {
    'de',
    'del',
    'la',
    'el',
    'los',
    'las',
    'en',
    'con',
    'sin',
    'para',
    'por',
    'y',
    'o',
    'a',
    'extra',
    'virgen',
    'blanco',
    'blancos',
    'negro',
    'negros',
    'fresco',
    'natural',
    'molido',
    'entero',
    'pelado',
  };

  /// Loads current pantry, shopping list, favorite recipes, and deals, then
  /// computes [SalesMatchReport].
  Future<SalesMatchReport> loadAndMatch({
    bool forceRefresh = false,
    bool includeHistory = true,
  }) async {
    final results = await Future.wait<dynamic>([
      _salesService.fetchDeals(forceRefresh: forceRefresh),
      _ingredientStorageService.getIngredients(),
      _shoppingListService.getIngredients(),
      if (includeHistory)
        _historyService.getAllKnownRecipes()
      else
        Future<List<Recipe>>.value(const <Recipe>[]),
      if (includeHistory)
        _historyService.getHistory()
      else
        Future<Map<String, RecipeHistoryRecord>>.value(
          const <String, RecipeHistoryRecord>{},
        ),
      _salesService.getFavoriteSupermarketId(),
    ]);

    final fetchResult = results[0] as SalesFetchResult;
    final pantry = results[1] as List<Ingredient>;
    final shoppingList = results[2] as List<Ingredient>;
    final recipes = results[3] as List<Recipe>;
    final history = results[4] as Map<String, RecipeHistoryRecord>;
    final favoriteSupermarketId = results[5] as String?;

    return matchDeals(
      deals: fetchResult.deals,
      pantryIngredients: pantry,
      shoppingListIngredients: shoppingList,
      recipes: recipes,
      history: history,
      favoriteSupermarketId: favoriteSupermarketId,
    );
  }

  /// Pure synchronous matching helper for unit tests and instant UI recomputes.
  SalesMatchReport matchDeals({
    required List<SupermarketDeal> deals,
    required List<Ingredient> pantryIngredients,
    required List<Ingredient> shoppingListIngredients,
    required List<Recipe> recipes,
    required Map<String, RecipeHistoryRecord> history,
    String? favoriteSupermarketId,
  }) {
    final favoriteRecipes = recipes.where((r) {
      return history[r.id]?.preference == RecipePreference.favorite;
    }).toList();

    final frequentIngredients =
        pantryIngredients.where((i) => i.timesUsed > 0).toList();

    final annotated = <MatchedSaleDeal>[];

    for (final deal in deals) {
      final reasons = <SaleMatchReason>[];
      final seenLabels = <String>{};
      int score = 0;
      String? primaryIngredient;

      void addReason(SaleMatchReason reason, int points) {
        if (seenLabels.add(reason.label)) {
          reasons.add(reason);
          score += points;
          primaryIngredient ??= reason.ingredientName;
        }
      }

      // 1. Pending items in "Por comprar"
      bool inShoppingList = false;
      for (final item in shoppingListIngredients) {
        if (matchesDeal(deal, item.name)) {
          inShoppingList = true;
          addReason(
            SaleMatchReason(
              type: SaleMatchReasonType.shoppingList,
              ingredientName: item.name,
              label: 'En tu lista "Por comprar": ${item.name}',
            ),
            100,
          );
        }
      }

      // 2. Ingredients from "Favorita" recipes
      for (final recipe in favoriteRecipes) {
        for (final ing in recipe.ingredients) {
          if (matchesDeal(deal, ing.name)) {
            addReason(
              SaleMatchReason(
                type: SaleMatchReasonType.favoriteRecipe,
                ingredientName: ing.name,
                recipeTitle: recipe.title,
                label: 'Receta favorita: ${recipe.title}',
              ),
              50,
            );
          }
        }
      }

      // 3. Frequently used pantry ingredients (timesUsed > 0)
      for (final freq in frequentIngredients) {
        if (matchesDeal(deal, freq.name)) {
          addReason(
            SaleMatchReason(
              type: SaleMatchReasonType.frequentIngredient,
              ingredientName: freq.name,
              timesUsed: freq.timesUsed,
              label: 'Ingrediente frecuente (${freq.timesUsed} usos)',
            ),
            20 + (freq.timesUsed > 15 ? 15 : freq.timesUsed),
          );
        }
      }

      final isFavStore = favoriteSupermarketId != null &&
          favoriteSupermarketId == deal.supermarketId;
      if (isFavStore && reasons.isNotEmpty) {
        score += 10;
      }

      final suggestedName = primaryIngredient ??
          (deal.queryTerm.isNotEmpty
              ? _capitalize(deal.queryTerm)
              : deal.productName);

      annotated.add(
        MatchedSaleDeal(
          deal: deal,
          reasons: reasons,
          matchScore: reasons.isEmpty ? deal.discountPercent : score + deal.discountPercent,
          isInShoppingList: inShoppingList,
          suggestedShoppingItemName: suggestedName,
          isFavoriteSupermarket: isFavStore,
        ),
      );
    }

    annotated.sort((a, b) {
      if (a.isMatched != b.isMatched) return a.isMatched ? -1 : 1;
      final scoreCmp = b.matchScore.compareTo(a.matchScore);
      if (scoreCmp != 0) return scoreCmp;
      return b.deal.discountPercent.compareTo(a.deal.discountPercent);
    });

    final matchedDeals = annotated.where((d) => d.isMatched).toList();
    final shoppingMatchesCount = matchedDeals
        .where(
          (d) => d.reasons.any((r) => r.type == SaleMatchReasonType.shoppingList),
        )
        .length;

    final totalSavings = matchedDeals.fold<double>(
      0.0,
      (sum, item) => sum + item.deal.savingsGtq,
    );

    return SalesMatchReport(
      matchedDeals: matchedDeals,
      allDeals: annotated,
      totalPotentialSavingsGtq: (totalSavings * 100).roundToDouble() / 100,
      shoppingListMatchesCount: shoppingMatchesCount,
      favoriteSupermarketId: favoriteSupermarketId,
    );
  }

  /// Determines whether [deal] matches an [ingredientName] using Spanish
  /// diacritic normalization and singular/plural token matching.
  static bool matchesDeal(SupermarketDeal deal, String ingredientName) {
    final normIng = StringNormalizer.normalize(ingredientName);
    if (normIng.isEmpty) return false;

    final productText = StringNormalizer.normalize(
      '${deal.productName} ${deal.category}',
    );
    if (productText.contains(normIng)) {
      return true;
    }

    final productWords = productText
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toSet();
    final queryNorm = StringNormalizer.normalize(deal.queryTerm);
    final tokens = _buildTokens(normIng);
    if (tokens.isEmpty) return false;

    int matchedCount = 0;
    for (final tok in tokens) {
      final directHit = productWords.contains(tok) ||
          productWords.contains('${tok}s') ||
          productWords.contains('${tok}es') ||
          (tok.length >= 4 && productWords.any((w) => w.startsWith(tok))) ||
          queryNorm == tok;
      if (directHit) {
        matchedCount++;
      }
    }

    return matchedCount == tokens.length;
  }

  static List<String> _buildTokens(String normalizedText) {
    final raw = normalizedText
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 3 && !_stopWords.contains(w));
    final result = <String>{};
    for (final token in raw) {
      if (token.endsWith('es') && token.length > 4) {
        result.add(token.substring(0, token.length - 2));
      } else if (token.endsWith('s') && token.length > 3) {
        result.add(token.substring(0, token.length - 1));
      } else {
        result.add(token);
      }
    }
    return result.toList();
  }

  static String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
