import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:food_friend/core/widgets/app_navigation_drawer.dart';
import 'package:food_friend/features/home/presentation/home_screen.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/onboarding/presentation/mode_selection_screen.dart';
import 'package:food_friend/features/recipes/data/external_recipe_service.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/data/recipe_search_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_history_record.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/domain/recipe_search_result.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/recipes/presentation/widgets/home_vs_takeout_card.dart';
import 'package:food_friend/features/sales/data/fallback_sales_data.dart';
import 'package:food_friend/features/sales/data/sales_matcher_service.dart';
import 'package:food_friend/features/sales/data/sales_service.dart';
import 'package:food_friend/features/sales/presentation/widgets/sales_alert_banner.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/widgets/smart_shopping_suggestions_section.dart';
import 'package:food_friend/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsController.instance.resetToDefaults();
  });

  group('ModeSelectionScreen onboarding', () {
    testWidgets('selecting Simple mode disables all optional features and hides them on Home and Drawer',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const FoodFriendApp());
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectionScreen), findsOneWidget);
      await tester.tap(find.text('Simple'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(SettingsController.instance.experienceMode, ExperienceMode.simple);
      expect(find.text('Ingredientes disponibles'), findsOneWidget);
      expect(find.text('Agregar ingredientes'), findsOneWidget);
      expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Gestión de recetas'), findsNothing);
      expect(find.text('Consejos de Nutrición'), findsNothing);
      expect(find.byType(SalesAlertBanner), findsNothing);

      // Drawer hides optional destinations in Simple mode
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(find.byType(AppNavigationDrawer), findsOneWidget);
      expect(find.text('Planificador de comidas'), findsNothing);
      expect(find.text('Gestión de recetas'), findsNothing);
      expect(find.text('Consejos de Nutrición'), findsNothing);
    });

    testWidgets('selecting Custom mode enables only chosen categories',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const FoodFriendApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Personalizada'));
      await tester.pumpAndSettle();

      final healthSwitch = find.text('Salud y nutrición');
      await tester.ensureVisible(healthSwitch);
      await tester.tap(healthSwitch);
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(FilledButton, 'Continuar');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(SettingsController.instance.experienceMode, ExperienceMode.custom);
      expect(SettingsController.instance.enableNutritionAndGoals, isTrue);
      expect(SettingsController.instance.enableFridgeScanner, isFalse);
      expect(SettingsController.instance.enableRecipeManagement, isFalse);
      expect(SettingsController.instance.enableSupermarketDeals, isFalse);

      expect(find.text('Consejos de Nutrición'), findsOneWidget);
      expect(find.text('Gestión de recetas'), findsNothing);
    });
  });

  group('AddIngredientScreen AI scanner gating', () {
    testWidgets('hides Foto tab when both Fridge and Receipt scanners are disabled',
        (tester) async {
      await SettingsController.instance.applyExperienceMode(ExperienceMode.simple);

      await tester.pumpWidget(const MaterialApp(home: AddIngredientScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Foto'), findsNothing);
    });

    testWidgets('shows only Receipt card when Fridge is disabled and Receipt is enabled',
        (tester) async {
      await SettingsController.instance.applyExperienceMode(ExperienceMode.simple);
      await SettingsController.instance
          .setFeatureEnabled(OptionalFeature.receiptScanner, true);

      await tester.pumpWidget(const MaterialApp(home: AddIngredientScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Foto'), findsOneWidget);
      await tester.tap(find.text('Foto'));
      await tester.pumpAndSettle();

      expect(find.text('Escanear refrigerador'), findsNothing);
      expect(find.text('Escanear recibo'), findsNWidgets(2));
    });
  });

  group('Cross-feature interaction gating', () {
    testWidgets(
        'RecipeDetailScreen keeps Lo cociné for pantry depletion when Recipe Management is off while hiding preferences and GTQ card when Pricing is off',
        (tester) async {
      await SettingsController.instance.applyExperienceMode(ExperienceMode.simple);

      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      final history = RecipeHistoryService(
        preferences: prefs,
        ingredientStorageService: pantry,
      );

      await pantry.addIngredients([
        Ingredient(name: 'Huevos'),
        Ingredient(name: 'Tomate'),
      ]);

      const recipe = Recipe(
        id: 'test_huevos',
        title: 'Huevos con tomate',
        ingredients: [
          RecipeIngredient(name: 'Huevos', displayAmount: '2 unidades'),
          RecipeIngredient(name: 'Tomate', displayAmount: '1 unidad'),
          RecipeIngredient(name: 'Sal', displayAmount: '1 pizca'),
        ],
        instructions: ['Cocinar todo junto.'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeDetailScreen(
            recipe: recipe,
            matchedIngredients: const [
              RecipeIngredient(name: 'Huevos', displayAmount: '2 unidades'),
              RecipeIngredient(name: 'Tomate', displayAmount: '1 unidad'),
            ],
            missingIngredients: const [
              RecipeIngredient(name: 'Sal', displayAmount: '1 pizca'),
            ],
            historyService: history,
            shoppingListService: shopping,
            ingredientStorageService: pantry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preferences and HomeVsTakeoutCard are hidden
      expect(find.text('Favorita'), findsNothing);
      expect(find.text('Nunca'), findsNothing);
      expect(find.byType(HomeVsTakeoutCard), findsNothing);

      // Core "Lo cociné" stays enabled and opens PantryDepletionSheet
      final cookedBtn = find.text('Lo cociné');
      expect(cookedBtn, findsOneWidget);
      await tester.tap(cookedBtn);
      await tester.pumpAndSettle();

      expect(find.text('¿Qué se te acabó?'), findsOneWidget);
      await tester.tap(find.text('Huevos').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solo quitar de Mis ingredientes'));
      await tester.pumpAndSettle();

      // Pantry depleted, while cooking history was not recorded
      final remainingPantry = await pantry.getIngredients();
      expect(remainingPantry.map((e) => e.name), isNot(contains('Huevos')));
      final record = await history.getRecord('test_huevos');
      expect(record.timesCooked, 0);
    });

    testWidgets(
        'RecipeSuggestionsScreen hides AI button, planner, pricing, and goal tooltips when disabled, and skips external API calls',
        (tester) async {
      await SettingsController.instance.applyExperienceMode(ExperienceMode.simple);

      final prefs = await SharedPreferences.getInstance();
      final healthStorage = HealthGoalStorageService(preferences: prefs);
      await healthStorage.saveSelectedGoals({HealthGoal.gainMuscle});

      final historyService = RecipeHistoryService(preferences: prefs);
      // Mark local omelet recipe as "Nunca" — when Recipe Management is OFF, it must NOT be hidden
      await historyService.setPreference('huevos_revueltos', RecipePreference.never);

      var externalCalled = false;
      final mockClient = MockClient((_) async {
        externalCalled = true;
        return http.Response('{"recipes":[]}', 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeSuggestionsScreen(
            selectedIngredientNames: const ['IngredienteInexistenteXYZ'],
            externalService: ExternalRecipeService(client: mockClient),
            historyService: historyService,
            healthGoalStorageService: healthStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(externalCalled, isFalse);
      expect(find.text('Generar más recetas con IA'), findsNothing);
      expect(
        find.byKey(const ValueKey('open_multi_day_planner_button')),
        findsNothing,
      );
      expect(find.textContaining('Metas activas:'), findsNothing);
      expect(find.textContaining('/ porción'), findsNothing);
    });

    testWidgets(
        'Ingredient Replacements ON + Health OFF shows pantry swaps without health swaps',
        (tester) async {
      await SettingsController.instance.applyExperienceMode(ExperienceMode.simple);
      await SettingsController.instance.setFeatureEnabled(
        OptionalFeature.ingredientReplacements,
        true,
      );

      final prefs = await SharedPreferences.getInstance();
      final healthStorage = HealthGoalStorageService(preferences: prefs);
      await healthStorage.saveSelectedGoals({HealthGoal.reduceSodiumAndProcessed});

      const testRecipe = Recipe(
        id: 'swap_test',
        title: 'Pollo en crema con aceite',
        ingredients: [
          RecipeIngredient(name: 'Pollo', displayAmount: '1 pechuga'),
          RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
          RecipeIngredient(name: 'Crema pura', displayAmount: '2 cdas'),
          RecipeIngredient(name: 'Salsa de soya', displayAmount: '1 cda'),
        ],
        instructions: ['Preparar.'],
      );

      final searchService = _FixedPoolSearchService([testRecipe]);

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeSuggestionsScreen(
            selectedIngredientNames: const [
              'Pollo',
              'Aceite vegetal',
              'Yogur natural',
            ],
            searchService: searchService,
            healthGoalStorageService: healthStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Availability replacement appears (Limón -> Naranja, Crema -> Yogur natural)
      expect(
        find.byKey(const ValueKey('availability_swap_swap_test')),
        findsOneWidget,
      );
      // Health goal tooltip and health swaps remain disabled
      expect(
        find.byKey(const ValueKey('goal_tooltip_swap_test')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('health_swap_swap_test')),
        findsNothing,
      );
    });

    testWidgets(
        'ShoppingListScreen hides SmartShoppingSuggestionsSection and SalesAlertBanner when disabled',
        (tester) async {
      await SettingsController.instance.applyExperienceMode(ExperienceMode.simple);

      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      await pantry.addIngredient(Ingredient(name: 'Pollo'));
      await shopping.addIngredient(Ingredient(name: 'Tomate'));

      final salesMatcher = SalesMatcherService(
        salesService: SalesService(
          client: MockClient((_) async => http.Response('{"deals":[]}', 500)),
        ),
        ingredientStorageService: pantry,
        shoppingListService: shopping,
      );
      expect(FallbackSalesData.deals, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScreen(
            initialTab: 1,
            storageService: pantry,
            shoppingListService: shopping,
            salesMatcherService: salesMatcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SalesAlertBanner), findsNothing);
      expect(find.byType(SmartShoppingSuggestionsSection), findsNothing);
      expect(find.text('Explorar ofertas del supermercado'), findsNothing);
    });
  });
}

class _FixedPoolSearchService extends RecipeSearchService {
  _FixedPoolSearchService(this._pool);

  final List<Recipe> _pool;

  @override
  List<Recipe> getAllRecipes() => _pool;

  @override
  List<RecipeSearchResult> searchRecipes({
    required List<String> selectedIngredientNames,
    List<Recipe>? recipePool,
    int minMatchCount = 1,
    Map<String, RecipeHistoryRecord>? history,
    int? maxTotalTimeMinutes,
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
    bool includeAvailabilityReplacements = true,
    bool includeHealthGoalReplacements = true,
  }) {
    return super.searchRecipes(
      selectedIngredientNames: selectedIngredientNames,
      recipePool: recipePool ?? _pool,
      minMatchCount: minMatchCount,
      history: history,
      maxTotalTimeMinutes: maxTotalTimeMinutes,
      activeHealthGoals: activeHealthGoals,
      includeAvailabilityReplacements: includeAvailabilityReplacements,
      includeHealthGoalReplacements: includeHealthGoalReplacements,
    );
  }
}
