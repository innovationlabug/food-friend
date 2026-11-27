# Implemented Features — Food Friend

This list is derived directly from the current implementation in `lib/` and `api/`. Features are divided into **Core** (always active, forming the `Simple` mode) and **Optional** (enabled in `Full` mode, disabled in `Simple` mode, and individually toggleable in `Custom` mode / `Settings`).

---

## Core Features (Always Enabled — `Simple` Mode)

1. **Home Dashboard (`HomeScreen`)**
   Provides the main landing screen with responsive action panels for Pantry, Adding Ingredients, Recipe Suggestions, and Shopping List, dynamically adjusting panel sizes based on whether the pantry has items.

2. **Pantry / Available Ingredients (`ShoppingListScreen` — "Mis ingredientes" tab)**
   Stores and displays the user's available home ingredients with selection checkboxes, item removal, and direct navigation to discover recipes from selected items.

3. **Shopping List (`ShoppingListScreen` — "Por comprar" tab)**
   Manages items to buy with quick add, check-off, deletion, and one-tap transfer of purchased items into the available pantry.

4. **Manual Search & Category Ingredient Entry (`AddIngredientScreen`)**
   Allows adding ingredients to the pantry or shopping list via real-time catalog search with auto-suggestions or hierarchical category browsing.

5. **Local Recipe Discovery & Filtering (`RecipeSuggestionsScreen`)**
   Matches local dataset recipes against selected pantry ingredients (with closest partial-match fallback) and filters results by meal category and preparation time.

6. **Recipe Detail, Missing-Item Sync & Cooking Flow (`RecipeDetailScreen`, `PantryDepletionSheet`)**
   Displays full recipe instructions, available vs. missing ingredients, one-tap addition of missing items to the shopping list, recipe variations, and a "mark as cooked" flow with optional pantry depletion.

7. **Theme & Basic App Settings (`SettingsScreen`, `ThemeController`, `AppNavigationDrawer`)**
   Provides light/dark Material 3 theme switching, top-level drawer navigation, and core usability preferences (auto-return after adding an ingredient and resetting helper tips).

---

## Optional Features (Toggleable in `Settings` / `Custom` Mode)

### AI
1. **AI Fridge & Pantry Photo Scanner (`FridgeScannerScreen`, `/api/detect-fridge`)**
   Lets users photograph or upload a fridge/pantry image to detect ingredients using Gemini Vision and batch-add them to the pantry.
   *When off:* Hide the fridge scan option from `AddIngredientScreen`.

2. **AI Supermarket Receipt Scanner (`ReceiptScannerScreen`, `/api/parse-receipt`)**
   Extracts food items, quantities, and GTQ prices from supermarket receipt photos to populate the pantry and update local price records.
   *When off:* Hide the receipt scan option from `AddIngredientScreen` (and stop saving receipt-derived prices).

3. **AI External Recipe Generation (`ExternalRecipeService`, `/api/recipes`)**
   Generates additional recipes via the backend Gemini proxy when local dataset matches are scarce or when the user requests AI suggestions.
   *When off:* Disable external AI recipe calls and rely strictly on the local recipe dataset.

### Planning & Assistance
4. **Multi-Day Meal Planner (`MultiDayPlannerScreen`, `MultiDayPlannerService`)**
   Builds a 2–7 day meal schedule prioritizing shared pantry ingredients, rotating variations without consecutive repeats, and batch-adding missing items to the shopping list.
   *When off:* Hide from `AppNavigationDrawer` and remove planner shortcuts from `RecipeSuggestionsScreen`.

5. **Recipe Management, Cooking History & Preferences (`RecipeManagementScreen`, `RecipeHistoryService`)**
   Tracks cooked counts and recipe preferences (Favorite, Liked, Disliked, Hidden/"Nunca"), provides a dedicated management screen to filter or unhide recipes, and adjusts recipe suggestion rankings.
   *When off:* Hide "Gestión de recetas" from `HomeScreen` and `AppNavigationDrawer`, hide preference buttons/cooked counts in `RecipeDetailScreen`, and stop filtering or re-ranking by preferences.

6. **Smart Shopping Suggestions (`ShoppingSuggestionService`, `SmartShoppingSuggestionsSection`)**
   Analyzes pantry gaps, cooking history, and active health goals to recommend ingredients to add inside the "Por comprar" tab.
   *When off:* Hide the smart suggestions section in `ShoppingListScreen`.

7. **Ingredient Replacements & Health Swaps (`IngredientReplacementService`)**
   Suggests pantry-available substitutes for missing ingredients and healthier ingredient swaps aligned with active health goals on `RecipeDetailScreen`.
   *When off:* Hide the ingredient replacement and health-swap sections in `RecipeDetailScreen`.

### Health & Nutrition
8. **Nutrition Tips & Health Goals (`NutritionTipsScreen`, `HealthGoalStorageService`, `GoalTooltipBanner`)**
   Allows selecting health goals, generates personalized nutrition tips from cooking history, boosts goal-aligned recipes, and displays nutritional tooltips on recipe cards, details, and the planner.
   *When off:* Hide "Consejos de Nutrición" from `HomeScreen` and `AppNavigationDrawer`, hide goal tooltips/badges across recipe screens and planner, and disable goal-based ranking.

### Prices & Sales
9. **Supermarket Deals & Sales Alerts (`SupermarketDealsScreen`, `SalesMatcherService`, `SalesAlertBanner`, `/api/sales`)**
   Shows Guatemalan supermarket offers in GTQ, supports setting a favorite store, displays matching deal alerts on Home and Shopping List, and lets users add deal items to the shopping list.
   *When off:* Hide `SalesAlertBanner` on `HomeScreen` and `ShoppingListScreen`, and hide access to `SupermarketDealsScreen`.

10. **GTQ Pricing & Home vs. Takeout Cost Comparison (`RecipeCostCalculator`, `HomeVsTakeoutCard`, `IngredientPriceStorageService`)**
    Estimates recipe costs in Guatemalan Quetzales (GTQ) using baseline prices, scanned receipts, and deals, and displays homemade vs. takeout savings on recipes.
    *When off:* Hide cost estimates and `HomeVsTakeoutCard` in `RecipeSuggestionsScreen`, `RecipeDetailScreen`, and `MultiDayPlannerScreen`.
