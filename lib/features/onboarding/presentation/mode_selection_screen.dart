import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/app_svg_icon.dart';

/// First-launch onboarding screen asking the user to choose their preferred
/// experience mode (`Simple`, `Completa`, or `Personalizada`).
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({
    super.key,
    this.controller,
    this.onCompleted,
  });

  /// Optional controller override for testing.
  final SettingsController? controller;

  /// Optional callback invoked after the selected mode has been persisted.
  final VoidCallback? onCompleted;

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late final SettingsController _controller;
  ExperienceMode? _selectedMode;
  final Set<FeatureCategory> _selectedCategories = <FeatureCategory>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsController.instance;
  }

  Future<void> _confirmSelection() async {
    final mode = _selectedMode;
    if (mode == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    await _controller.applyExperienceMode(
      mode,
      customCategories: mode == ExperienceMode.custom
          ? _selectedCategories
          : null,
      markOnboardingComplete: true,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    widget.onCompleted?.call();
  }

  String _modeIcon(ExperienceMode mode) => switch (mode) {
        ExperienceMode.simple => 'restaurant',
        ExperienceMode.full => 'sparkles',
        ExperienceMode.custom => 'settings',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 16 : 24,
            vertical: context.isMobile ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: AppSvgIcon(
                              assetName: 'restaurant',
                              size: 24,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Food Friend',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Elige cómo quieres usar la aplicación',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selecciona un modo inicial. Podrás activar o desactivar cualquier función cuando quieras en Configuración.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final mode in ExperienceMode.values) ...[
                        _buildModeCard(context, mode),
                        const SizedBox(height: 12),
                      ],
                      if (_selectedMode == ExperienceMode.custom) ...[
                        const SizedBox(height: 4),
                        _buildCustomCategoriesCard(context),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    _selectedMode == null || _isSaving ? null : _confirmSelection,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, ExperienceMode mode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedMode == mode;

    return Card(
      margin: EdgeInsets.zero,
      elevation: isSelected ? 1 : 0,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppSvgIcon(
                  assetName: _modeIcon(mode),
                  size: 22,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppSvgIcon(
                assetName: isSelected ? 'check_circle' : 'circle',
                size: 22,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCategoriesCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Categorías opcionales',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (int i = 0; i < FeatureCategory.values.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              _buildCategoryTile(context, FeatureCategory.values[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, FeatureCategory category) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = _selectedCategories.contains(category);

    return SwitchListTile(
      secondary: AppSvgIcon(
        assetName: category.iconName,
        size: 20,
        color: colorScheme.primary,
      ),
      title: Text(category.label),
      subtitle: Text(category.description),
      value: isEnabled,
      onChanged: (value) {
        setState(() {
          if (value) {
            _selectedCategories.add(category);
          } else {
            _selectedCategories.remove(category);
          }
        });
      },
    );
  }
}
