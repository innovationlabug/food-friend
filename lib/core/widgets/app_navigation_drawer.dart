import 'package:flutter/material.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/ingredients/data/ingredient_storage_service.dart';
import '../../features/ingredients/presentation/add_ingredient_screen.dart';
import '../../features/nutrition/presentation/nutrition_tips_screen.dart';
import '../../features/recipes/presentation/multi_day_planner_screen.dart';
import '../../features/recipes/presentation/recipe_management_screen.dart';
import '../../features/recipes/presentation/recipe_suggestions_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shopping_list/presentation/shopping_list_screen.dart';
import '../settings/settings_controller.dart';
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
  multiDayPlanner,
  recipeManagement,
  nutritionTips,
}

/// Width reserved for [AppBar.leading] when displaying both [BackButton] and
/// [AppMenuButton] side-by-side on the left edge of pushed screens.
const double kAppBarLeadingWidthWithBack = 96.0;

/// Returns whether the current route is stacked above a previous route.
/// Using [ModalRoute.isFirst] keeps the leading width and buttons aligned
/// throughout pop transitions instead of shrinking mid-animation.
bool _canPopRoute(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route != null) {
    return !route.isFirst;
  }
  return Navigator.of(context).canPop();
}

/// Returns the appropriate [AppBar.leadingWidth] for [AppBarLeading] based on
/// whether the current route can pop.
double? appBarLeadingWidth(BuildContext context) {
  return _canPopRoute(context) ? kAppBarLeadingWidthWithBack : null;
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
    final canPop = _canPopRoute(context);
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
    this.settingsSection,
    this.isSettingsScreen = false,
  });

  /// Currently active logical destination, or `null` when inside a sub-screen.
  final AppDestination? currentDestination;

  /// Optional override indicating which settings section is most relevant to
  /// the current screen. Inferred from [currentDestination] when omitted.
  final SettingsSection? settingsSection;

  /// Whether the drawer is currently displayed on [SettingsScreen].
  final bool isSettingsScreen;

  List<AppDestination> _visibleDestinations(SettingsController settings) {
    return [
      AppDestination.home,
      AppDestination.availableIngredients,
      AppDestination.shoppingList,
      AppDestination.addIngredients,
      AppDestination.recipeSuggestions,
      if (settings.enableMultiDayPlanner) AppDestination.multiDayPlanner,
      if (settings.enableRecipeManagement) AppDestination.recipeManagement,
      if (settings.enableNutritionAndGoals) AppDestination.nutritionTips,
    ];
  }

  int? _selectedIndexFor(List<AppDestination> visibleDestinations) {
    final current = currentDestination;
    if (current == null) return null;
    final idx = visibleDestinations.indexOf(current);
    return idx >= 0 ? idx : null;
  }

  SettingsSection get _effectiveSettingsSection {
    if (settingsSection != null) return settingsSection!;
    return switch (currentDestination) {
      AppDestination.availableIngredients ||
      AppDestination.shoppingList ||
      AppDestination.addIngredients =>
        SettingsSection.ingredients,
      _ => SettingsSection.home,
    };
  }

  Future<void> _openSettings(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (isSettingsScreen) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          initialSection: _effectiveSettingsSection,
        ),
      ),
    );
  }

  Future<void> _navigateTo(
    BuildContext context,
    AppDestination destination,
  ) async {
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
    } else if (destination == AppDestination.multiDayPlanner) {
      final ingredients = await IngredientStorageService().getIngredients();
      targetScreen = MultiDayPlannerScreen(
        initialIngredientNames: ingredients.map((i) => i.name).toList(),
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
        AppDestination.multiDayPlanner => const MultiDayPlannerScreen(),
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

  ({String iconName, String label}) _destinationMeta(AppDestination destination) {
    return switch (destination) {
      AppDestination.home => (iconName: 'home', label: 'Inicio'),
      AppDestination.availableIngredients => (
          iconName: 'restaurant',
          label: 'Ingredientes disponibles',
        ),
      AppDestination.shoppingList => (
          iconName: 'shopping_cart',
          label: 'Lista de compras',
        ),
      AppDestination.addIngredients => (
          iconName: 'plus',
          label: 'Agregar ingredientes',
        ),
      AppDestination.recipeSuggestions => (
          iconName: 'sparkles',
          label: '¿Qué cocino hoy?',
        ),
      AppDestination.multiDayPlanner => (
          iconName: 'calendar',
          label: 'Planificador de comidas',
        ),
      AppDestination.recipeManagement => (
          iconName: 'book',
          label: 'Gestión de recetas',
        ),
      AppDestination.nutritionTips => (
          iconName: 'nutrition',
          label: 'Consejos de Nutrición',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: SettingsController.instance,
      builder: (context, _) {
        final visibleDestinations =
            _visibleDestinations(SettingsController.instance);

        return NavigationDrawerTheme(
          data: theme.navigationDrawerTheme.copyWith(
            tileHeight: 44,
          ),
          child: NavigationDrawer(
            selectedIndex: _selectedIndexFor(visibleDestinations),
            onDestinationSelected: (index) =>
                _navigateTo(context, visibleDestinations[index]),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppSvgIcon(
                        assetName: 'restaurant',
                        size: 20,
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
              const Divider(height: 1, indent: 24, endIndent: 24),
              for (final destination in visibleDestinations)
                () {
                  final meta = _destinationMeta(destination);
                  return NavigationDrawerDestination(
                    icon: AppSvgIcon(
                      assetName: meta.iconName,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    selectedIcon: AppSvgIcon(
                      assetName: meta.iconName,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    label: _drawerLabel(meta.label),
                  );
                }(),
        const Divider(height: 1, indent: 24, endIndent: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            selected: isSettingsScreen,
            leading: AppSvgIcon(
              assetName: 'settings',
              size: 20,
              color: isSettingsScreen
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            title: _drawerLabel('Configuración'),
            trailing: AppSvgIcon(
              assetName: 'chevron_right',
              size: 18,
              color: isSettingsScreen
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            onTap: () => _openSettings(context),
          ),
        ),
        const Divider(height: 1, indent: 24, endIndent: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
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
                  const SizedBox(height: 4),
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
    ),
    );
      },
    );
  }
}

