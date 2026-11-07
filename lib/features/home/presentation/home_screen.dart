import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// Main landing shell screen for Food Friend.
/// Presents key navigation entry points in Spanish with a clean, responsive layout.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          title: 'Lista de compras',
          description:
              'Gestiona tus ingredientes disponibles, despensa y lista de compras.',
          buttonLabel: 'Ir a lista de compras',
          onPressed: () {
            // Navigation to shopping list will be wired in US-1.3
          },
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          iconName: 'restaurant',
          title: '¿Qué cocino hoy?',
          description:
              'Descubre recetas saludables y variadas basadas en lo que tienes a mano.',
          buttonLabel: 'Ver sugerencias',
          onPressed: () {},
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          iconName: 'nutrition',
          title: 'Asistente de nutrición',
          description:
              'Evalúa el balance nutricional de tus comidas y planifica tu alimentación.',
          buttonLabel: 'Explorar nutrición',
          onPressed: () {},
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
                title: 'Lista de compras',
                description:
                    'Gestiona tus ingredientes disponibles, despensa y lista de compras.',
                buttonLabel: 'Ir a lista de compras',
                onPressed: () {},
                isPrimary: true,
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
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                iconName: 'nutrition',
                title: 'Asistente de nutrición',
                description:
                    'Evalúa el balance nutricional de tus comidas y planifica tu alimentación.',
                buttonLabel: 'Explorar nutrición',
                onPressed: () {},
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
