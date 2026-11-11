import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../data/recipe_history_service.dart';
import '../domain/recipe.dart';
import '../domain/recipe_history_record.dart';
import '../domain/recipe_preference.dart';
import 'recipe_detail_screen.dart';

/// Screen allowing users to view, manage, and filter all recipes,
/// review cooking history frequency, and modify preference marks (including unhiding 'Nunca' recipes).
class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({
    super.key,
    this.historyService,
  });

  final RecipeHistoryService? historyService;

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

enum _ManagementFilter {
  todas,
  favoritas,
  cocinadas,
  ocultas;

  String get label {
    switch (this) {
      case _ManagementFilter.todas:
        return 'Todas';
      case _ManagementFilter.favoritas:
        return 'Favoritas';
      case _ManagementFilter.cocinadas:
        return 'Cocinadas';
      case _ManagementFilter.ocultas:
        return 'Ocultas (Nunca)';
    }
  }
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  late final RecipeHistoryService _historyService;
  bool _isLoading = true;
  List<Recipe> _allRecipes = [];
  Map<String, RecipeHistoryRecord> _history = {};
  _ManagementFilter _activeFilter = _ManagementFilter.todas;

  @override
  void initState() {
    super.initState();
    _historyService = widget.historyService ?? RecipeHistoryService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final recipes = await _historyService.getAllKnownRecipes();
    final history = await _historyService.getHistory();

    if (!mounted) return;
    setState(() {
      _allRecipes = recipes;
      _history = history;
      _isLoading = false;
    });
  }

  List<Recipe> get _filteredRecipes {
    return _allRecipes.where((recipe) {
      final record = _history[recipe.id] ?? RecipeHistoryRecord(recipeId: recipe.id);

      // Tab filter
      switch (_activeFilter) {
        case _ManagementFilter.todas:
          return true;
        case _ManagementFilter.favoritas:
          return record.preference == RecipePreference.favorite;
        case _ManagementFilter.cocinadas:
          return record.timesCooked > 0;
        case _ManagementFilter.ocultas:
          return record.preference == RecipePreference.never;
      }
    }).toList();
  }

  int _countForFilter(_ManagementFilter filter) {
    return _allRecipes.where((recipe) {
      final record = _history[recipe.id] ?? RecipeHistoryRecord(recipeId: recipe.id);
      switch (filter) {
        case _ManagementFilter.todas:
          return true;
        case _ManagementFilter.favoritas:
          return record.preference == RecipePreference.favorite;
        case _ManagementFilter.cocinadas:
          return record.timesCooked > 0;
        case _ManagementFilter.ocultas:
          return record.preference == RecipePreference.never;
      }
    }).length;
  }

  Future<void> _updatePreference(Recipe recipe, RecipePreference target) async {
    final currentPref = _history[recipe.id]?.preference ?? RecipePreference.none;
    final newPref = currentPref == target ? RecipePreference.none : target;

    final updatedRecord = await _historyService.setPreference(
      recipe.id,
      newPref,
      recipe: recipe,
    );

    if (!mounted) return;
    setState(() {
      _history[recipe.id] = updatedRecord;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    String message;
    if (currentPref == RecipePreference.never && newPref != RecipePreference.never) {
      message = 'Receta restablecida para sugerencias';
    } else if (newPref == RecipePreference.none) {
      message = 'Preferencia eliminada';
    } else if (newPref == RecipePreference.never) {
      message = 'Marcada como Nunca (oculta de sugerencias)';
    } else {
      message = 'Marcada como ${newPref.label}';
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Recetas'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildFilterTabs(context),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildRecipeList(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administra tu recetario',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Consulta tu frecuencia de cocina y modifica marcas de preferencia o recetas ocultas.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ManagementFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          final count = _countForFilter(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text('${filter.label} ($count)'),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
              selectedColor: colorScheme.primaryContainer,
              backgroundColor: colorScheme.surface,
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              ),
              onSelected: (_) {
                setState(() {
                  _activeFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipeList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      String emptyMessage;
      switch (_activeFilter) {
        case _ManagementFilter.todas:
          emptyMessage = 'No se encontraron recetas en el catálogo.';
          break;
        case _ManagementFilter.favoritas:
          emptyMessage = 'Aún no has marcado ninguna receta como Favorita.';
          break;
        case _ManagementFilter.cocinadas:
          emptyMessage = 'Aún no has registrado ninguna receta cocinada.';
          break;
        case _ManagementFilter.ocultas:
          emptyMessage = 'No tienes recetas ocultas (Nunca).';
          break;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetName: 'restaurant',
                size: 40,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final record = _history[recipe.id] ?? RecipeHistoryRecord(recipeId: recipe.id);
        return _buildRecipeCard(context, recipe, record);
      },
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe,
    RecipeHistoryRecord record,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cookedText = record.timesCooked == 0
        ? 'Sin cocinar aún'
        : (record.timesCooked == 1 ? 'Cocinada 1 vez' : 'Cocinada ${record.timesCooked} veces');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RecipeDetailScreen(
                recipe: recipe,
                historyService: _historyService,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (recipe.category != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            recipe.category!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.timesCooked > 0
                          ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cookedText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: record.timesCooked > 0
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Preference selector row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildSmallPreferenceChip(
                    context,
                    recipe: recipe,
                    preference: RecipePreference.favorite,
                    iconName: 'heart',
                    label: 'Favorita',
                    isSelected: record.preference == RecipePreference.favorite,
                    activeColor: Colors.red.shade600,
                  ),
                  _buildSmallPreferenceChip(
                    context,
                    recipe: recipe,
                    preference: RecipePreference.liked,
                    iconName: 'thumb_up',
                    label: 'Me gustó',
                    isSelected: record.preference == RecipePreference.liked,
                    activeColor: Colors.green.shade700,
                  ),
                  _buildSmallPreferenceChip(
                    context,
                    recipe: recipe,
                    preference: RecipePreference.disliked,
                    iconName: 'thumb_down',
                    label: 'No me gustó',
                    isSelected: record.preference == RecipePreference.disliked,
                    activeColor: Colors.orange.shade800,
                  ),
                  _buildSmallPreferenceChip(
                    context,
                    recipe: recipe,
                    preference: RecipePreference.never,
                    iconName: 'block',
                    label: 'Nunca',
                    isSelected: record.preference == RecipePreference.never,
                    activeColor: colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallPreferenceChip(
    BuildContext context, {
    required Recipe recipe,
    required RecipePreference preference,
    required String iconName,
    required String label,
    required bool isSelected,
    required Color activeColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _updatePreference(recipe, preference),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetName: iconName,
              size: 14,
              color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
