import '../../../core/utils/string_normalizer.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';

/// Local persistence service for the user's dedicated Shopping List ("Lista de Compras"),
/// stored independently from available home ingredients ("Mis Ingredientes").
class ShoppingListStorageService extends IngredientStorageService {
  ShoppingListStorageService({
    super.preferences,
    IngredientStorageService? pantryStorageService,
  })  : _pantryStorageService =
            pantryStorageService ?? IngredientStorageService(preferences: preferences),
        super(
          storageKey: shoppingListStorageKey,
        );

  static const String shoppingListStorageKey = 'food_friend_shopping_list';

  final IngredientStorageService _pantryStorageService;

  /// Storage service for available home ingredients ("Mis Ingredientes").
  IngredientStorageService get pantryStorageService => _pantryStorageService;

  /// Marks an item from the shopping list as bought: removes it from the shopping list
  /// and adds it to the user's available home ingredients (consolidating duplicates).
  Future<({List<Ingredient> shoppingList, List<Ingredient> availableIngredients})>
      markAsBought(String name) async {
    final currentShoppingList = await getIngredients();
    Ingredient? matchingItem;
    final remainingShoppingList = <Ingredient>[];

    for (final item in currentShoppingList) {
      if (matchingItem == null && StringNormalizer.areEquivalent(item.name, name)) {
        matchingItem = item;
      } else {
        remainingShoppingList.add(item);
      }
    }

    await saveIngredients(remainingShoppingList);

    final updatedAvailable = matchingItem != null
        ? await _pantryStorageService.addIngredient(matchingItem)
        : await _pantryStorageService.getIngredients();

    return (
      shoppingList: remainingShoppingList,
      availableIngredients: updatedAvailable,
    );
  }

  /// Dismisses an item from the shopping list without adding it to available ingredients.
  Future<List<Ingredient>> dismissItem(String name) {
    return removeIngredient(name);
  }
}
