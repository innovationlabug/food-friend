import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// Application customization screen accessible from the hamburger menu.
/// Orders setting sections dynamically so options relevant to the screen
/// from which the user opened settings appear at the top.
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
              final orderedSections = widget.initialSection == SettingsSection.ingredients
                  ? [
                      _buildIngredientsSection(context),
                      const SizedBox(height: 20),
                      _buildHomeSection(context),
                    ]
                  : [
                      _buildHomeSection(context),
                      const SizedBox(height: 20),
                      _buildIngredientsSection(context),
                    ];

              return ListView(
                children: [
                  ...orderedSections,
                  const SizedBox(height: 20),
                  _buildAppearanceSection(context),
                  const SizedBox(height: 16),
                ],
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

  Widget _buildHomeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context,
          iconName: 'home',
          title: 'Pantalla principal',
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  'Ocultar paneles',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SwitchListTile(
                secondary: AppSvgIcon(
                  assetName: 'nutrition',
                  size: 20,
                  color: colorScheme.primary,
                ),
                title: const Text('Ocultar Consejos de Nutrición'),
                subtitle: const Text(
                  'Oculta el panel de Consejos de Nutrición en la pantalla principal.',
                ),
                value: _controller.hideNutritionTipsPanel,
                onChanged: (value) {
                  _controller.setHideNutritionTipsPanel(value);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: AppSvgIcon(
                  assetName: 'heart',
                  size: 20,
                  color: colorScheme.primary,
                ),
                title: const Text('Ocultar Gestión de recetas'),
                subtitle: const Text(
                  'Oculta el panel de Gestión de recetas en la pantalla principal.',
                ),
                value: _controller.hideRecipeManagementPanel,
                onChanged: (value) {
                  _controller.setHideRecipeManagementPanel(value);
                },
              ),
            ],
          ),
        ),
      ],
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
