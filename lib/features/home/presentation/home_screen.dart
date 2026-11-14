import 'package:flutter/material.dart';
import '../../../core/navigation/app_route_observer.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/presentation/add_ingredient_screen.dart';
import '../../nutrition/data/nutrition_service.dart';
import '../../nutrition/domain/nutrition_tip.dart';
import '../../nutrition/presentation/nutrition_tips_screen.dart';
import '../../recipes/presentation/recipe_management_screen.dart';
import '../../recipes/presentation/recipe_suggestions_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';

/// Main landing shell screen for Food Friend.
/// Displays all primary navigation panels simultaneously with dynamic sizing
/// driven by whether the user already has ingredients in their pantry.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final NutritionService _nutritionService = NutritionService();
  final IngredientStorageService _ingredientStorageService =
      IngredientStorageService();

  NutritionReport? _nutritionReport;
  int _ingredientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final results = await Future.wait([
      _nutritionService.generateReport(),
      _ingredientStorageService.getIngredients(),
      SettingsController.instance.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _nutritionReport = results[0] as NutritionReport;
      _ingredientCount = (results[1] as List).length;
    });
  }

  Future<void> _openRecipeSuggestions(BuildContext context) async {
    final ingredients = await _ingredientStorageService.getIngredients();
    if (!context.mounted) return;

    await RecipeSuggestionsScreen.navigate(
      context,
      selectedIngredientNames: ingredients.map((i) => i.name).toList(),
    );
    if (mounted) {
      await _loadHomeData();
    }
  }

  Future<void> _pushAndRefresh(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) {
      await _loadHomeData();
    }
  }

  String _nutritionCardDescription() {
    final report = _nutritionReport;
    if (report == null || !report.hasCookingHistory) {
      return 'Consejos personalizados según las recetas que cocinas.';
    }
    if (report.tips.isEmpty) {
      return 'Tus comidas recientes están bien equilibradas.';
    }
    final count = report.tips.length;
    return count == 1
        ? 'Tienes 1 consejo de nutrición activo.'
        : 'Tienes $count consejos de nutrición activos.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasIngredients = _ingredientCount > 0;

    return Scaffold(
      drawer: const AppNavigationDrawer(
        currentDestination: AppDestination.home,
      ),
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Row(
          children: [
            AppSvgIcon(
              assetName: 'restaurant',
              size: 24,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Food Friend',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              final isDark = ThemeController.instance.isDarkMode;
              return IconButton(
                tooltip: isDark
                    ? 'Cambiar a modo claro'
                    : 'Cambiar a modo oscuro',
                icon: AppSvgIcon(
                  assetName: isDark ? 'sun' : 'moon',
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => ThemeController.instance.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: SettingsController.instance,
          builder: (context, _) {
            return ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 14 : 24,
                vertical: context.isMobile ? 12 : 18,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canFitInViewport = constraints.maxHeight >= 480;
                  if (canFitInViewport) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroHeader(context),
                        SizedBox(height: context.isMobile ? 12 : 18),
                        Expanded(
                          child: _buildDynamicPanelGrid(
                            context,
                            hasIngredients: hasIngredients,
                            useExpandedRows: true,
                          ),
                        ),
                      ],
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroHeader(context),
                        const SizedBox(height: 12),
                        _buildDynamicPanelGrid(
                          context,
                          hasIngredients: hasIngredients,
                          useExpandedRows: false,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = context.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bienvenido a Food Friend',
          style: (isMobile
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.headlineSmall)
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tu asistente de cocina, compras y nutrición en Guatemala.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicPanelGrid(
    BuildContext context, {
    required bool hasIngredients,
    required bool useExpandedRows,
  }) {
    final gap = context.isMobile ? 10.0 : 16.0;
    final settings = SettingsController.instance;
    final hideRecipeManagement = settings.hideRecipeManagementPanel;
    final hideNutritionTips = settings.hideNutritionTipsPanel;

    // Dynamic vertical proportions:
    // - No ingredients: emphasize Ingredients & Shopping List.
    // - Has ingredients: emphasize Recipe Suggestions ("¿Qué cocino hoy?").
    final int ingredientsRowFlex = hasIngredients ? 3 : 5;
    final int recipesRowFlex = hasIngredients ? 6 : 3;
    final int bottomRowFlex = hasIngredients ? 3 : 4;

    final int shoppingHorizontalFlex = hasIngredients ? 48 : 62;
    final int nutritionHorizontalFlex = hasIngredients ? 52 : 38;

    Widget buildRow({
      required int rowFlex,
      required double fallbackHeight,
      required Widget left,
      required int leftFlex,
      Widget? right,
      required int rightFlex,
    }) {
      final Widget rowContent = right == null
          ? left
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: leftFlex, child: left),
                SizedBox(width: gap),
                Expanded(flex: rightFlex, child: right),
              ],
            );

      if (useExpandedRows) {
        return Expanded(flex: rowFlex, child: rowContent);
      }
      return SizedBox(height: fallbackHeight, child: rowContent);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildRow(
          rowFlex: ingredientsRowFlex,
          fallbackHeight: hasIngredients ? 132 : 185,
          leftFlex: 62,
          rightFlex: 38,
          left: _buildActionPanel(
            context: context,
            iconName: 'restaurant',
            title: 'Ingredientes disponibles',
            description:
                'Gestiona tu despensa y elige qué ingredientes usar hoy.',
            onTap: () => _pushAndRefresh(
              const ShoppingListScreen(initialTab: 0),
            ),
            isPrimary: !hasIngredients,
          ),
          right: _buildActionPanel(
            context: context,
            iconName: 'plus',
            title: 'Agregar ingredientes',
            description: 'Busca, explora o escanea.',
            onTap: () => _pushAndRefresh(const AddIngredientScreen()),
            isCompact: true,
          ),
        ),
        SizedBox(height: gap),
        buildRow(
          rowFlex: recipesRowFlex,
          fallbackHeight: hasIngredients ? 210 : 132,
          leftFlex: 62,
          rightFlex: 38,
          left: _buildActionPanel(
            context: context,
            iconName: 'restaurant',
            title: '¿Qué cocino hoy?',
            description: hasIngredients
                ? 'Descubre recetas saludables con los ingredientes que ya tienes en casa.'
                : 'Explora recetas saludables y variadas para planificar tu comida.',
            onTap: () => _openRecipeSuggestions(context),
            isPrimary: hasIngredients,
          ),
          right: hideRecipeManagement
              ? null
              : _buildActionPanel(
                  context: context,
                  iconName: 'heart',
                  title: 'Gestión de recetas',
                  description: 'Historial y favoritas.',
                  onTap: () => _pushAndRefresh(const RecipeManagementScreen()),
                  isCompact: true,
                ),
        ),
        SizedBox(height: gap),
        buildRow(
          rowFlex: bottomRowFlex,
          fallbackHeight: hasIngredients ? 132 : 165,
          leftFlex: shoppingHorizontalFlex,
          rightFlex: nutritionHorizontalFlex,
          left: _buildActionPanel(
            context: context,
            iconName: 'shopping_cart',
            title: 'Lista de compras',
            description: 'Organiza lo que necesitas comprar en el súper.',
            onTap: () => _pushAndRefresh(
              const ShoppingListScreen(initialTab: 1),
            ),
            isSecondaryHighlight: !hasIngredients,
            isCompact: !hideNutritionTips && hasIngredients,
          ),
          right: hideNutritionTips
              ? null
              : _buildActionPanel(
                  context: context,
                  iconName: 'nutrition',
                  title: 'Consejos de Nutrición',
                  description: _nutritionCardDescription(),
                  onTap: () => _pushAndRefresh(const NutritionTipsScreen()),
                  isCompact: !hasIngredients,
                ),
        ),
      ],
    );
  }

  Widget _buildActionPanel({
    required BuildContext context,
    required String iconName,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isSecondaryHighlight = false,
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color cardColor;
    final Color iconBgColor;
    final Color iconColor;
    final Color borderColor;

    if (isPrimary) {
      cardColor = colorScheme.primaryContainer.withValues(alpha: 0.45);
      iconBgColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
      borderColor = colorScheme.primary.withValues(alpha: 0.45);
    } else if (isSecondaryHighlight) {
      cardColor = colorScheme.secondaryContainer.withValues(alpha: 0.45);
      iconBgColor = colorScheme.secondaryContainer;
      iconColor = colorScheme.onSecondaryContainer;
      borderColor = colorScheme.secondary.withValues(alpha: 0.4);
    } else {
      cardColor = colorScheme.surfaceContainerLow;
      iconBgColor = colorScheme.surfaceContainerHighest;
      iconColor = colorScheme.primary;
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.55);
    }

    return Semantics(
      button: true,
      label: title,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isPrimary ? 2 : 0,
        clipBehavior: Clip.antiAlias,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: isPrimary ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tightHeight = constraints.maxHeight < 155;
              final tightWidth = constraints.maxWidth < 155;
              final padding = (tightHeight || tightWidth) ? 12.0 : 16.0;
              final iconSize = (tightHeight || isCompact) ? 18.0 : 22.0;
              final iconBoxPad = (tightHeight || isCompact) ? 7.0 : 10.0;

              final titleStyle = (isCompact || tightWidth)
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    )
                  : theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    );

              final showDescription = constraints.maxHeight >= 118;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(iconBoxPad),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppSvgIcon(
                            assetName: iconName,
                            size: iconSize,
                            color: iconColor,
                          ),
                        ),
                        AppSvgIcon(
                          assetName: 'arrow_forward',
                          size: 18,
                          color: isPrimary
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: titleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showDescription) ...[
                            SizedBox(height: tightHeight ? 2 : 4),
                            Flexible(
                              child: Text(
                                description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.2,
                                ),
                                maxLines: tightHeight || isCompact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
