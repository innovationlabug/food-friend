import 'package:flutter/material.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/ingredients/data/ingredient_storage_service.dart';
import '../../features/ingredients/presentation/add_ingredient_screen.dart';
import '../../features/nutrition/presentation/nutrition_tips_screen.dart';
import '../../features/recipes/presentation/recipe_management_screen.dart';
import '../../features/recipes/presentation/recipe_suggestions_screen.dart';
import '../../features/shopping_list/presentation/shopping_list_screen.dart';
import '../theme/theme_controller.dart';
import 'app_svg_icon.dart';

/// Logical top-level destinations exposed in the burger navigation menu.
/// Deliberately excludes granular sub-screens (such as fridge/receipt scanners
/// or recipe details) while keeping navigation accessible from every screen.
enum AppDestination {
  home,
  availableIngredients,
  shoppingList,
  addIngredients,
  recipeSuggestions,
  recipeManagement,
  nutritionTips,
}

/// Width reserved for [AppBar.leading] when displaying both [BackButton] and
/// [AppMenuButton] side-by-side on the left edge of pushed screens.
const double kAppBarLeadingWidthWithBack = 96.0;

/// Returns the appropriate [AppBar.leadingWidth] for [AppBarLeading] based on
/// whether the current route can pop.
double? appBarLeadingWidth(BuildContext context) {
  return Navigator.of(context).canPop() ? kAppBarLeadingWidthWithBack : null;
}

/// AppBar button that opens the left navigation [Scaffold.drawer] burger menu.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    super.key,
    this.compact = false,
  });

  /// Uses slightly tighter horizontal padding when paired next to [BackButton].
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        icon: const AppSvgIcon(assetName: 'menu', size: 22),
        tooltip: 'Menú de navegación',
        padding: compact ? const EdgeInsets.all(6) : null,
        constraints: compact
            ? const BoxConstraints(minWidth: 40, minHeight: 44)
            : null,
        onPressed: () {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold == null) return;
          if (scaffold.hasDrawer) {
            scaffold.openDrawer();
          } else if (scaffold.hasEndDrawer) {
            scaffold.openEndDrawer();
          }
        },
      ),
    );
  }
}

/// Standardized left-aligned AppBar leading widget.
/// Renders [BackButton] + left [AppMenuButton] when the route can pop, or
/// only [AppMenuButton] on root screens so the burger menu is always on the left.
class AppBarLeading extends StatelessWidget {
  const AppBarLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop) {
      return const AppMenuButton();
    }
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BackButton(),
        AppMenuButton(compact: true),
      ],
    );
  }
}

/// Material 3 navigation drawer allowing navigation between all logical screens
/// and toggling between light and dark theme modes.
class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    this.currentDestination,
  });

  /// Currently active logical destination, or `null` when inside a sub-screen.
  final AppDestination? currentDestination;

  int? get _selectedIndex => currentDestination?.index;

  Future<void> _navigateTo(BuildContext context, int index) async {
    final destination = AppDestination.values[index];
    final navigator = Navigator.of(context);
    // Close the drawer first
    navigator.pop();

    if (destination == currentDestination) {
      return;
    }

    if (destination == AppDestination.home) {
      if (navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      } else {
        await navigator.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    Widget targetScreen;
    if (destination == AppDestination.recipeSuggestions) {
      final ingredients = await IngredientStorageService().getIngredients();
      targetScreen = RecipeSuggestionsScreen(
        selectedIngredientNames: ingredients.map((i) => i.name).toList(),
      );
    } else {
      targetScreen = switch (destination) {
        AppDestination.home => const HomeScreen(),
        AppDestination.availableIngredients => const ShoppingListScreen(initialTab: 0),
        AppDestination.shoppingList => const ShoppingListScreen(initialTab: 1),
        AppDestination.addIngredients => const AddIngredientScreen(),
        AppDestination.recipeSuggestions => const RecipeSuggestionsScreen(
            selectedIngredientNames: [],
          ),
        AppDestination.recipeManagement => const RecipeManagementScreen(),
        AppDestination.nutritionTips => const NutritionTipsScreen(),
      };
    }

    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => targetScreen),
    );
  }

  Widget _drawerLabel(String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => _navigateTo(context, index),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppSvgIcon(
                  assetName: 'restaurant',
                  size: 22,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Friend',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Menú principal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 24, endIndent: 24),
        const SizedBox(height: 4),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'home',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'home',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('Inicio'),
        ),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'restaurant',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'restaurant',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('Ingredientes disponibles'),
        ),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'shopping_cart',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'shopping_cart',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('Lista de compras'),
        ),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'plus',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'plus',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('Agregar ingredientes'),
        ),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'sparkles',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'sparkles',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('¿Qué cocino hoy?'),
        ),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'book',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'book',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('Gestión de recetas'),
        ),
        NavigationDrawerDestination(
          icon: AppSvgIcon(
            assetName: 'nutrition',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: AppSvgIcon(
            assetName: 'nutrition',
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          label: _drawerLabel('Consejos de Nutrición'),
        ),
        const Divider(indent: 24, endIndent: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              final currentMode = ThemeController.instance.themeMode;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tema de la aplicación',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: AppSvgIcon(assetName: 'sun', size: 16),
                        label: Text('Claro'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: AppSvgIcon(assetName: 'moon', size: 16),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {currentMode},
                    onSelectionChanged: (selected) {
                      if (selected.isNotEmpty) {
                        ThemeController.instance.setThemeMode(selected.first);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

