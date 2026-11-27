import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// Application customization screen accessible from the hamburger menu.
/// Allows switching experience modes (`Simple`, `Completa`, `Personalizada`),
/// toggling individual optional features by category, and configuring core
/// ingredient/appearance preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.initialSection = SettingsSection.home,
    this.controller,
  });

  /// Determines which settings section should be prioritized at the top.
  final SettingsSection initialSection;

  /// Optional controller override for testing.
  final SettingsController? controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsController.instance;
    _controller.load();
  }

  Future<void> _handleResetTooltips() async {
    await _controller.resetTooltips();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Consejos restablecidos. Se mostrarán nuevamente.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(
        isSettingsScreen: true,
      ),
      appBar: AppBar(
        leadingWidth: appBarLeadingWidth(context),
        leading: const AppBarLeading(),
        title: const Text('Configuración'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: Listenable.merge([_controller, ThemeController.instance]),
            builder: (context, _) {
              final orderedSections =
                  widget.initialSection == SettingsSection.ingredients
                      ? [
                          _buildIngredientsSection(context),
                          const SizedBox(height: 20),
                          _buildExperienceAndFeaturesSection(context),
                        ]
                      : [
                          _buildExperienceAndFeaturesSection(context),
                          const SizedBox(height: 20),
                          _buildIngredientsSection(context),
                        ];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...orderedSections,
                    const SizedBox(height: 20),
                    _buildAppearanceSection(context),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String iconName,
    required String title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          AppSvgIcon(
            assetName: iconName,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceAndFeaturesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeMode = _controller.experienceMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context,
          iconName: 'settings',
          title: 'Modo y funciones',
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Modo de uso',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeMode.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ExperienceMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<ExperienceMode>(
                      value: ExperienceMode.simple,
                      label: Text('Simple'),
                    ),
                    ButtonSegment<ExperienceMode>(
                      value: ExperienceMode.full,
                      label: Text('Completa'),
                    ),
                    ButtonSegment<ExperienceMode>(
                      value: ExperienceMode.custom,
                      label: Text('Personalizada'),
                    ),
                  ],
                  selected: {activeMode},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      _controller.applyExperienceMode(selected.first);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < FeatureCategory.values.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildFeatureCategoryCard(context, FeatureCategory.values[i]),
        ],
      ],
    );
  }

  Widget _buildFeatureCategoryCard(
    BuildContext context,
    FeatureCategory category,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final features = category.features;
    final allEnabled = _controller.isCategoryEnabled(category);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                AppSvgIcon(
                  assetName: category.iconName,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (features.length > 1)
                  Switch(
                    value: allEnabled,
                    onChanged: (value) {
                      _controller.setCategoryEnabled(category, value);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          for (int i = 0; i < features.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _buildFeatureSwitchTile(context, features[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureSwitchTile(
    BuildContext context,
    OptionalFeature feature,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = _controller.isFeatureEnabled(feature);

    return SwitchListTile(
      secondary: AppSvgIcon(
        assetName: feature.iconName,
        size: 20,
        color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(feature.title),
      subtitle: Text(feature.description),
      value: enabled,
      onChanged: (value) {
        _controller.setFeatureEnabled(feature, value);
      },
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context,
          iconName: 'restaurant',
          title: 'Lista y registro de ingredientes',
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                secondary: AppSvgIcon(
                  assetName: 'arrow_back',
                  size: 20,
                  color: colorScheme.primary,
                ),
                title: const Text('Volver automáticamente a la lista'),
                subtitle: const Text(
                  'Regresa a la lista de ingredientes después de agregar un solo ingrediente.',
                ),
                value: _controller.autoReturnAfterAddingIngredient,
                onChanged: (value) {
                  _controller.setAutoReturnAfterAddingIngredient(value);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: AppSvgIcon(
                            assetName: 'info',
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consejos de ayuda',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vuelve a mostrar consejos cerrados anteriormente, como el aviso de presionar Enter para agregar un ingrediente.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _handleResetTooltips,
                        icon: AppSvgIcon(
                          assetName: 'refresh',
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        label: const Text('Restablecer consejos'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMode = ThemeController.instance.themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context,
          iconName: ThemeController.instance.isDarkMode ? 'moon' : 'sun',
          title: 'Apariencia',
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tema de la aplicación',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige entre tema claro u oscuro.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
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
            ),
          ),
        ),
      ],
    );
  }
}
