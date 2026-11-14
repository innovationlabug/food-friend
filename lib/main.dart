import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/ingredients/presentation/add_ingredient_screen.dart';
import 'features/ingredients/presentation/fridge_scanner_screen.dart';
import 'features/ingredients/presentation/receipt_scanner_screen.dart';
import 'features/nutrition/presentation/nutrition_tips_screen.dart';
import 'features/recipes/data/local_recipe_dataset.dart';
import 'features/recipes/presentation/recipe_detail_screen.dart';
import 'features/recipes/presentation/recipe_suggestions_screen.dart';
import 'features/shopping_list/presentation/shopping_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodFriendApp());
}

/// Food Friend root application widget.
/// Configures Material 3 theming, Spanish localization, and the main home shell.
class FoodFriendApp extends StatefulWidget {
  const FoodFriendApp({super.key});

  @override
  State<FoodFriendApp> createState() => _FoodFriendAppState();
}

class _FoodFriendAppState extends State<FoodFriendApp> {
  final ThemeController _themeController = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.load();
    SettingsController.instance.load();
  }

  Widget _getInitialScreen() {
    final route = Uri.base.queryParameters['route'];
    switch (route) {
      case 'available_ingredients':
        return const ShoppingListScreen(initialTab: 0);
      case 'shopping_list':
        return const ShoppingListScreen(initialTab: 1);
      case 'add_ingredient':
        return const AddIngredientScreen();
      case 'fridge':
        return const FridgeScannerScreen();
      case 'receipt':
        return const ReceiptScannerScreen();
      case 'recipes':
        return const RecipeSuggestionsScreen(selectedIngredientNames: ['Pollo', 'Tomate', 'Cebolla']);
      case 'detail':
        return RecipeDetailScreen(recipe: LocalRecipeDataset.instance.recipes.first);
      case 'nutrition':
        return const NutritionTipsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Food Friend',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,
          navigatorObservers: [appRouteObserver],
          locale: const Locale('es', 'GT'),
          supportedLocales: const [
            Locale('es', 'GT'),
            Locale('es'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _getInitialScreen(),
        );
      },
    );
  }
}

