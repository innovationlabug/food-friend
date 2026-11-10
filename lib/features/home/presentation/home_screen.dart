import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/presentation/add_ingredient_screen.dart';
import '../../recipes/presentation/recipe_suggestions_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';

/// Main landing shell screen for Food Friend.
/// Presents key navigation entry points in Spanish with a clean, responsive layout.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openRecipeSuggestions(BuildContext context) async {
    final storageService = IngredientStorageService();
    final ingredients = await storageService.getIngredients();
    if (!context.mounted) return;

    RecipeSuggestionsScreen.navigate(
      context,
      selectedIngredientNames: ingredients.map((i) => i.name).toList(),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroHeader(context),
        const SizedBox(height: 24),
        _buildFeatureCard(
          context: context,
          iconName: 'shopping_cart',
          title: 'Ingredientes disponibles',
          description:
              'Gestiona tus ingredientes disponibles y despensa.',
          buttonLabel: 'Ir a ingredientes disponibles',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ShoppingListScreen(),
              ),
            );
          },
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          iconName: 'plus',
          title: 'Agregar ingredientes',
          description:
              'Busca o explora ingredientes por categoría para añadirlos rápidamente a tu despensa o lista.',
          buttonLabel: 'Añadir ingredientes',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AddIngredientScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          iconName: 'restaurant',
          title: '¿Qué cocino hoy?',
          description:
              'Descubre recetas saludables y variadas basadas en lo que tienes a mano.',
          buttonLabel: 'Ver sugerencias',
          onPressed: () => _openRecipeSuggestions(context),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(context),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFeatureCard(
                context: context,
                iconName: 'shopping_cart',
                title: 'Ingredientes disponibles',
                description:
                    'Gestiona tus ingredientes disponibles y despensa.',
                buttonLabel: 'Ir a ingredientes disponibles',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShoppingListScreen(),
                    ),
                  );
                },
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                iconName: 'plus',
                title: 'Agregar ingredientes',
                description:
                    'Busca o explora ingredientes por categoría para añadirlos rápidamente a tu despensa.',
                buttonLabel: 'Añadir ingredientes',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddIngredientScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                iconName: 'restaurant',
                title: '¿Qué cocino hoy?',
                description:
                    'Descubre recetas saludables y variadas basadas en lo que tienes a mano.',
                buttonLabel: 'Ver sugerencias',
                onPressed: () => _openRecipeSuggestions(context),
              ),
            ),
          ],
        ),
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
