import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
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

enum _CookedFilter {
  todas,
  cocinadas,
  noCocinadas;

  String get label {
    switch (this) {
      case _CookedFilter.todas:
        return 'Todas';
      case _CookedFilter.cocinadas:
        return 'Cocinadas';
      case _CookedFilter.noCocinadas:
        return 'No cocinadas';
    }
  }
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  late final RecipeHistoryService _historyService;
  bool _isLoading = true;
  List<Recipe> _allRecipes = [];
  Map<String, RecipeHistoryRecord> _history = {};
  _CookedFilter _activeCookedFilter = _CookedFilter.todas;
  RecipePreference? _activePreferenceFilter;
  String? _selectedCategory;

  static const List<({RecipePreference pref, String label})> _preferenceFilterOptions = [
    (pref: RecipePreference.favorite, label: 'Favoritas'),
    (pref: RecipePreference.liked, label: 'Me gustó'),
    (pref: RecipePreference.disliked, label: 'No me gustó'),
    (pref: RecipePreference.never, label: 'Ocultas'),
    (pref: RecipePreference.none, label: 'Sin marcar'),
  ];

  static const List<String> _baseMealCategories = [
    'Desayuno',
    'Almuerzo',
    'Cena',
    'Sopas y Caldos',
    'Ensaladas',
  ];

  List<String> get _availableCategories {
    final list = <String>[..._baseMealCategories];
    for (final recipe in _allRecipes) {
      final cat = recipe.category?.trim();
      if (cat != null && cat.isNotEmpty) {
        final norm = cat[0].toUpperCase() + cat.substring(1);
        if (!list.any((existing) => existing.toLowerCase() == norm.toLowerCase())) {
          list.add(norm);
        }
      }
    }
    return list;
  }

  bool _matchesCategory(Recipe recipe, String? category) {
    if (category == null) return true;
    final rCat = recipe.category?.trim().toLowerCase();
    if (rCat == null) return false;
    final fCat = category.trim().toLowerCase();
    return rCat == fCat || rCat.contains(fCat) || fCat.contains(rCat);
  }

  bool _matchesCookedFilter(Recipe recipe, _CookedFilter filter) {
    final record = _history[recipe.id] ?? RecipeHistoryRecord(recipeId: recipe.id);
    switch (filter) {
      case _CookedFilter.todas:
        return true;
      case _CookedFilter.cocinadas:
        return record.timesCooked > 0;
      case _CookedFilter.noCocinadas:
        return record.timesCooked == 0;
    }
  }

  bool _matchesPreferenceFilter(Recipe recipe, RecipePreference? pref) {
    if (pref == null) return true;
    final record = _history[recipe.id] ?? RecipeHistoryRecord(recipeId: recipe.id);
    return record.preference == pref;
  }

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
    return _allRecipes
        .where(
          (recipe) =>
              _matchesCookedFilter(recipe, _activeCookedFilter) &&
              _matchesPreferenceFilter(recipe, _activePreferenceFilter) &&
              _matchesCategory(recipe, _selectedCategory),
        )
        .toList();
  }

  int _countForCookedFilter(_CookedFilter filter) {
    if (filter == _CookedFilter.todas) {
      return _allRecipes.length;
    }
    return _allRecipes
        .where(
          (recipe) =>
              _matchesCookedFilter(recipe, filter) &&
              _matchesPreferenceFilter(recipe, _activePreferenceFilter) &&
              _matchesCategory(recipe, _selectedCategory),
        )
        .length;
  }

  int _countForPreferenceFilter(RecipePreference pref) {
    return _allRecipes
        .where(
          (recipe) =>
              _matchesCookedFilter(recipe, _activeCookedFilter) &&
              _matchesPreferenceFilter(recipe, pref) &&
              _matchesCategory(recipe, _selectedCategory),
        )
        .length;
  }

  int _countForCategory(String category) {
    return _allRecipes
        .where(
          (recipe) =>
              _matchesCookedFilter(recipe, _activeCookedFilter) &&
              _matchesPreferenceFilter(recipe, _activePreferenceFilter) &&
              _matchesCategory(recipe, category),
        )
        .length;
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
      message = 'Receta oculta de sugerencias';
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
      endDrawer: const AppNavigationDrawer(
        currentDestination: AppDestination.recipeManagement,
      ),
      appBar: AppBar(
        title: const Text('Gestión de Recetas'),
        actions: const [AppMenuButton()],
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
                    _buildCookedFilterRow(context),
                    const SizedBox(height: 8),
                    _buildPreferenceFilterRow(context),
                    const SizedBox(height: 8),
                    _buildCategoryFilterRow(context),
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

    return Row(
      children: [
        Flexible(
          child: Text(
            'Administra tu recetario',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message:
              'Aquí puedes ver todas las recetas, consultar cuántas veces las has cocinado y marcarlas fácilmente como Favorita, Me gustó, No me gustó u ocultarlas.',
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: true,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            Icons.info_outline,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        label: Text(label),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
        selectedColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.surface,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _buildCookedFilterRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _CookedFilter.values.map((filter) {
          final isSelected = filter == _CookedFilter.todas
              ? (_activeCookedFilter == _CookedFilter.todas &&
                  _activePreferenceFilter == null &&
                  _selectedCategory == null)
              : _activeCookedFilter == filter;
          final count = _countForCookedFilter(filter);

          return _buildStyledFilterChip(
            context,
            label: '${filter.label} ($count)',
            isSelected: isSelected,
            onSelected: () {
              setState(() {
                if (filter == _CookedFilter.todas) {
                  _activeCookedFilter = _CookedFilter.todas;
                  _activePreferenceFilter = null;
                  _selectedCategory = null;
                } else {
                  _activeCookedFilter =
                      _activeCookedFilter == filter ? _CookedFilter.todas : filter;
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferenceFilterRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _preferenceFilterOptions.map((option) {
          final isSelected = _activePreferenceFilter == option.pref;
          final count = _countForPreferenceFilter(option.pref);

          return _buildStyledFilterChip(
            context,
            label: '${option.label} ($count)',
            isSelected: isSelected,
            onSelected: () {
              setState(() {
                _activePreferenceFilter =
                    _activePreferenceFilter == option.pref ? null : option.pref;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilterRow(BuildContext context) {
    final categories = _availableCategories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final count = _countForCategory(cat);

          return _buildStyledFilterChip(
            context,
            label: '$cat ($count)',
            isSelected: isSelected,
            onSelected: () {
              setState(() {
                _selectedCategory = _selectedCategory == cat ? null : cat;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  String _emptyMessageForActiveFilters() {
    switch (_activePreferenceFilter) {
      case RecipePreference.favorite:
        return 'Aún no has marcado ninguna receta como Favorita.';
      case RecipePreference.liked:
        return 'Aún no has marcado ninguna receta con Me gustó.';
      case RecipePreference.disliked:
        return 'No tienes recetas marcadas con No me gustó.';
      case RecipePreference.never:
        return 'No tienes recetas ocultas.';
      case RecipePreference.none:
        return 'No hay recetas sin preferencia marcada en esta vista.';
      case null:
        switch (_activeCookedFilter) {
          case _CookedFilter.todas:
            return 'No se encontraron recetas en el catálogo.';
          case _CookedFilter.cocinadas:
            return 'Aún no has registrado ninguna receta cocinada.';
          case _CookedFilter.noCocinadas:
            return 'Todas las recetas del catálogo ya han sido cocinadas.';
        }
    }
  }

  Widget _buildRecipeList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      if (_selectedCategory != null) {
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
                  'No se encontraron recetas de tipo "$_selectedCategory" en esta vista.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Mostrar todas las categorías'),
                ),
              ],
            ),
          ),
        );
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
                _emptyMessageForActiveFilters(),
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
                    label: record.preference == RecipePreference.never
                        ? 'Oculta'
                        : 'Ocultar',
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
