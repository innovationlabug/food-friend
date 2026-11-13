import '../../ingredients/data/ingredient_storage_service.dart';

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
}
