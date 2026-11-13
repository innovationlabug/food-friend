import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
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
/// Presents key navigation entry points and nutrition summary in Spanish.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NutritionService _nutritionService = NutritionService();
  NutritionReport? _nutritionReport;

  @override
  void initState() {
    super.initState();
    _loadNutritionSummary();
  }

  Future<void> _loadNutritionSummary() async {
    final report = await _nutritionService.generateReport();
    if (mounted) {
      setState(() {
        _nutritionReport = report;
      });
    }
  }

  Future<void> _openRecipeSuggestions(BuildContext context) async {
    final storageService = IngredientStorageService();
    final ingredients = await storageService.getIngredients();
    if (!context.mounted) return;

    await RecipeSuggestionsScreen.navigate(
      context,
      selectedIngredientNames: ingredients.map((i) => i.name).toList(),
    );
    if (mounted) {
      await _loadNutritionSummary();
    }
  }

  Future<void> _pushAndRefresh(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) {
      await _loadNutritionSummary();
    }
  }

  String _nutritionCardDescription() {
    final report = _nutritionReport;
    if (report == null || !report.hasCookingHistory) {
      return 'Descubre consejos de nutrición personalizados según las recetas que cocinas.';
    }
    if (report.tips.isEmpty) {
      return 'Tus comidas recientes están bien equilibradas. Revisa el detalle nutricional.';
    }
    final count = report.tips.length;
    return count == 1
        ? 'Tienes 1 consejo de nutrición activo según tus comidas recientes.'
        : 'Tienes $count consejos de nutrición activos según tus comidas recientes.';
  }

  List<Widget> _buildCards(BuildContext context) {
    return [
      _buildFeatureCard(
        context: context,
        iconName: 'restaurant',
        title: 'Ingredientes disponibles',
        description:
            'Gestiona tus ingredientes disponibles en casa y selecciona qué usar para cocinar.',
        buttonLabel: 'Ir a ingredientes disponibles',
        onPressed: () => _pushAndRefresh(const ShoppingListScreen(initialTab: 0)),
        isPrimary: true,
      ),
      _buildFeatureCard(
        context: context,
        iconName: 'shopping_cart',
        title: 'Lista de compras',
        description:
            'Organiza los productos que necesitas comprar en el supermercado.',
        buttonLabel: 'Ir a lista de compras',
        onPressed: () => _pushAndRefresh(const ShoppingListScreen(initialTab: 1)),
      ),
      _buildFeatureCard(
        context: context,
        iconName: 'plus',
        title: 'Agregar ingredientes',
        description:
            'Busca o explora ingredientes por categoría para añadirlos rápidamente a tu despensa.',
        buttonLabel: 'Añadir ingredientes',
        onPressed: () => _pushAndRefresh(const AddIngredientScreen()),
      ),
      _buildFeatureCard(
        context: context,
        iconName: 'restaurant',
        title: '¿Qué cocino hoy?',
        description:
            'Descubre recetas saludables y variadas basadas en lo que tienes a mano.',
        buttonLabel: 'Ver sugerencias',
        onPressed: () => _openRecipeSuggestions(context),
      ),
      _buildFeatureCard(
        context: context,
        iconName: 'restaurant',
        title: 'Gestión de recetas',
        description:
            'Revisa tu historial de cocina, recetas favoritas y administra recetas ocultas.',
        buttonLabel: 'Gestionar recetas',
        onPressed: () => _pushAndRefresh(const RecipeManagementScreen()),
      ),
      _buildFeatureCard(
        context: context,
        iconName: 'nutrition',
        title: 'Consejos de Nutrición',
        description: _nutritionCardDescription(),
        buttonLabel: 'Ver consejos de nutrición',
        onPressed: () => _pushAndRefresh(const NutritionTipsScreen()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppSvgIcon(
              assetName: 'restaurant',
              size: 24,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Food Friend'),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: ResponsiveLayout(
              mobile: (context) => _buildMobileLayout(context),
              desktop: (context) => _buildDesktopLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final cards = _buildCards(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroHeader(context),
        const SizedBox(height: 24),
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i < cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final cards = _buildCards(context);
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      final hasSecond = i + 1 < cards.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 20),
            Expanded(
              child: hasSecond ? cards[i + 1] : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < cards.length) {
        rows.add(const SizedBox(height: 20));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(context),
        const SizedBox(height: 32),
        ...rows,
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido a Food Friend',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu asistente de cocina, compras y nutrición en Guatemala.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String iconName,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isPrimary ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppSvgIcon(
                assetName: iconName,
                size: 28,
                color: isPrimary
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (isPrimary)
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              )
            else
              OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
          ],
        ),
      ),
    );
  }
}
