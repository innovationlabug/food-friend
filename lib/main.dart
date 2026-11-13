import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/ingredients/presentation/add_ingredient_screen.dart';
import 'features/ingredients/presentation/fridge_scanner_screen.dart';
import 'features/ingredients/presentation/receipt_scanner_screen.dart';
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
class FoodFriendApp extends StatelessWidget {
  const FoodFriendApp({super.key});

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
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Friend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
  }
}

