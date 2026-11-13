# Manual Ingredient Input (Phase 2) - US-2.1 through US-2.3 Report

This report summarizes the implementation, verification, and end-to-end testing for Phase 2 user stories (**US-2.1**, **US-2.2**, and **US-2.3**) on Git branch `feature/manual-ingredient-input`.

---

## 1. Branch Information
- **Branch:** `feature/manual-ingredient-input`
- **Scope:** Manual ingredient input (predefined Spanish catalog, auto-suggestions search, closest-match fallback, and hierarchical category browsing).

---

## 2. User Story Summary & Breakdown

### US-2.1: Predefined Spanish Ingredient Catalog & Category Taxonomy
- **Domain & Data Components:**
  - `CategoryNode` (`lib/features/ingredients/domain/category_node.dart`): Recursive tree node representing intermediate categories or selectable leaf ingredients, supporting synonyms, depth tracking, and leaf traversal.
  - `IngredientCatalog` (`lib/features/ingredients/data/ingredient_catalog.dart`): Comprehensive catalog of Guatemalan and Latin American staples with real-time suggestion search, synonym lookup, and normalized Levenshtein distance matching.
- **Granularity & Hierarchy Depth:**
  - Root categories (Level 1: `Verduras y Vegetales`, `Proteínas y Carnes`, `Granos, Cereales y Harinas`, `Lácteos y Huevos`, `Frutas`, `Hierbas, Especias y Condimentos`, `Despensa, Aceites y Salsas`).
  - Subcategories (Level 2: `Pollo`, `Res`, `Cerdo`, `Pescados y Mariscos`, `Embutidos`, `Frijoles`, etc.).
  - Selectable leaf ingredients (Level 3 or 4) with cooking granularity (e.g. `Pechuga de pollo`, `Alitas de pollo`, and generic `Pollo`; `Carne molida de res`, `Posta de res`, and generic `Carne de res`).
  - Maximum depth verified strictly $\le 4$ levels across the entire tree.
  - Includes Guatemalan staples: `Güisquil`, `Perulero`, `Miltomate`, `Chile guaque`, `Chile pasa`, `Chile cobanero`, `Samat`, `Epazote`, `Longaniza guatemalteca`, `Chorizo negro`, `Frijoles negros`, `Masa de maíz`, `Harina de maíz`, `Fécula de maíz`, `Plátano maduro`, `Queso seco`, `Queso de capas`, `Crema pura`, `Nutella`.
- **Commit:** `039c54c` - `feat(catalog): implement predefined spanish ingredient catalog and category taxonomy`

### US-2.2: Add Ingredient via Text Input with Auto-Suggestions
- **Presentation Component:**
  - `AddIngredientScreen` (`lib/features/ingredients/presentation/add_ingredient_screen.dart`): Screen with Tab 1 (`Buscar`).
  - `TextFormField` with label `Nombre del ingrediente *` and real-time filtering.
  - Case- and accent-insensitive matching (e.g. typing `pech` suggests `Pechuga de pollo`; typing `guis` suggests `Güisquil`).
  - Direct selection: Tapping a suggestion immediately creates `Ingredient(name: suggestion)`, saves it to `IngredientStorageService`, displays a confirmation SnackBar (`Ingrediente "<nombre>" agregado`), and pops back to the list.
  - Closest match fallback: If the user types text and taps `Guardar` (or submits on the keyboard) without selecting a suggestion, `IngredientCatalog.instance.getClosestMatch(query)` resolves the closest catalog item (e.g., `tomte` $\rightarrow$ `Tomate`, `pechuga de polo` $\rightarrow$ `Pechuga de pollo`).
  - Quick-add chips for high-frequency pantry staples.
- **Commit:** `022f880` - `feat(ingredients): implement add ingredient via text search with auto-suggestions and closest match`

### US-2.3: Add Ingredient via Common Ingredient Categories
- **Presentation Component:**
  - `AddIngredientScreen` Tab 2 (`Categorías`): Hierarchical browsing view.
  - Reaching any final ingredient takes at most 3 to 4 steps:
    - Step 1: Tap Level 1 category (e.g. `Proteínas y Carnes`).
    - Step 2: Tap Level 2 subcategory (e.g. `Pollo`).
    - Step 3: Tap Level 3 leaf ingredient (e.g. `Pechuga de pollo`).
  - Intuitive back navigation:
    - Back button and interactive breadcrumb header (`Proteínas y Carnes > Pollo`).
    - Android/System back support with `PopScope` that steps back up category levels before popping the screen.
  - Clean one-tap leaf selection persisting directly to local storage with Spanish confirmation SnackBar.
  - Added clean session state action (`Borrar mis datos`) in `ShoppingListScreen` menu.
- **Commit:** `31311c6` - `feat(ingredients): implement hierarchical category browsing for adding ingredients`

---

## 3. Automated Test Verification

| Test Suite | Scope | Result |
| :--- | :--- | :--- |
| `test/unit/ingredient_model_test.dart` | Ingredient serialization, `timesUsed`, `lastUsed`, `markUsed` | **PASSED** (12 tests) |
| `test/unit/ingredient_storage_service_test.dart` | Local storage, duplicate consolidation, usage tracking | **PASSED** (10 tests) |
| `test/unit/ingredient_catalog_test.dart` | Catalog taxonomy, depth $\le 4$, cooking granularity, staples | **PASSED** (4 tests) |
| `test/features/shopping_list_screen_test.dart` | Navigation, empty state, ingredient list, delete, clear data | **PASSED** (5 tests) |
| `test/features/add_ingredient_search_test.dart` | US-2.2 text field, suggestions, selection, closest match | **PASSED** (5 tests) |
| `test/features/add_ingredient_categories_test.dart` | US-2.3 category tabs, 3-step navigation, back button, leaf add | **PASSED** (4 tests) |
| `test/integration/add_ingredients_flow_test.dart` | E2E integration: clean state, search add, closest match add, category add | **PASSED** (1 test) |
| `test/widget_test.dart` | Root shell smoke test | **PASSED** (8 tests) |

- **Total Test Count:** 49 tests passing.
- **Static Analysis:** `flutter analyze` $\rightarrow$ `No issues found!` (0 warnings, 0 errors).
- **Layout Verification:** Zero `RenderFlex` overflows, zero unhandled exceptions.

---

## 4. Git Commit History on Branch `feature/manual-ingredient-input`
```
31311c6 feat(ingredients): implement hierarchical category browsing for adding ingredients
022f880 feat(ingredients): implement add ingredient via text search with auto-suggestions and closest match
039c54c feat(catalog): implement predefined spanish ingredient catalog and category taxonomy
```

---

# Phase 5: Guatemalan Ingredient Catalog & Taxonomy Expansion - US-5.1 & US-5.2 Report

This section summarizes the implementation, verification, and end-to-end testing for Phase 5 user stories (**US-5.1** and **US-5.2**) on Git branch `feature/taxonomy-and-catalog-expansion`.

---

## 1. Branch Information
- **Branch:** `feature/taxonomy-and-catalog-expansion`
- **Scope:** Guatemalan supermarket taxonomy refinement, elimination of botanical jargon, and catalog expansion with user-tested missing staples (`nueces`, `maní`, `queso gouda`, `queso parmesano`, `curry`).

---

## 2. User Story Summary & Breakdown

### US-5.1: Guatemalan Supermarket Taxonomy & Category Naming Refinement
- **Audited and Refined Taxonomy:**
  - Audited all category and subcategory names in `IngredientCatalog` (`lib/features/ingredients/data/ingredient_catalog.dart`) to mirror everyday Guatemalan supermarket classifications (inspired by Walmart Guatemala and Supermercados La Torre).
  - Completely eliminated all academic/botanical terms: `Cucurbitáceas`, `Hortalizas de fruto`, `Hortalizas de hoja`, `Bulbos y Vainas`, `Raíces y Tubérculos`.
  - Replaced them with natural, everyday groupings:
    - `Verduras para cocido y guisos`
    - `Verduras para ensalada`
    - `Cebollas, ajos y chiles`
    - `Hierbas y montes`
    - `Ejotes y arvejas`
    - `Embutidos y carnes frías`
    - `Quesos y crema`
    - `Frutos secos y semillas`
- **Strict Tree Depth Invariant:**
  - Verified that all paths from root category to selectable leaf ingredient strictly maintain a depth $\le 4$ levels.
- **Commit:** `ed0ccc4` - `feat(catalog): refine category taxonomy to natural guatemalan supermarket terminology`

### US-5.2: Expanded Ingredient Catalog & User-Tested Missing Staples
- **Catalog Expansion:**
  - Expanded `IngredientCatalog` across all major food groups with everyday grocery staples found in Walmart Guatemala and La Torre.
  - Explicitly integrated the 5 user-tested missing staples as selectable leaf nodes:
    - `Nueces` (with synonyms `nuez`, `nueces de nogal`, `nuez de castilla`)
    - `Maní` (with synonyms `cacahuate`, `cacahuates`, `mani tostado`, `manies`)
    - `Queso gouda` (with synonym `gouda`)
    - `Queso parmesano` (with synonyms `parmesano`, `queso parmesano rallado`)
    - `Curry` (with synonym `curry en polvo`)
  - Added additional staples: `Champiñones` (synonyms `hongos`, `setas`), `Brócoli`, `Coliflor`, `Lentejas`, `Garbanzos`, `Almendras`, `Semillas de marañón`, `Pasas`, `Semillas de girasol`, `Queso cheddar`, `Páprika`, `Jengibre`, `Cúrcuma`, `Jamón de pavo`, `Salami`, `Mortadela`, `Yogur de fresa`.
- **Search, Synonyms & UI Integration:**
  - Normalized diacritic- and case-insensitive resolution in `getClosestMatch` and `searchSuggestions`.
  - Category browser hierarchy renders all newly added staples in their respective category leaves without exceeding 4 navigation steps.
- **Commit:** `4329bad` - `feat(catalog): expand ingredient catalog with user-tested missing staples`

---

## 3. Automated Test Verification

| Test Suite | Scope | Result |
| :--- | :--- | :--- |
| `test/unit/ingredient_catalog_test.dart` | US-5.1 botanical term absence, supermarket naming presence, depth $\le 4$, US-5.2 staples in catalog, exact & fuzzy lookup, synonyms, category leaves | **PASSED** (14 tests) |
| `test/features/add_ingredient_search_test.dart` | Real-time text suggestions surfacing newly added staples (`gouda`, `nuez`, `cacahuate`, `parmesano`, `curry`) | **PASSED** (9 tests) |
| `test/features/add_ingredient_categories_test.dart` | Category browser navigation down to newly added staples and persistent addition to storage | **PASSED** (5 tests) |
| `test/integration/add_ingredients_flow_test.dart` | Full E2E flow: clean state, add staples (`Queso gouda`, `Nueces`, `Curry`) via search synonyms and category browsing, verify display in available ingredients | **PASSED** (2 tests) |
| Entire Project Test Suite | All unit, feature, and integration tests across the codebase | **PASSED** (130/130 tests) |

- **Static Analysis:** `flutter analyze` $\rightarrow$ `No issues found!` (0 warnings, 0 errors).
- **Layout & Accessibility Verification:** Zero `RenderFlex` overflows, zero unhandled exceptions.

---

## 4. Git Commit History on Branch `feature/taxonomy-and-catalog-expansion`
```
4329bad feat(catalog): expand ingredient catalog with user-tested missing staples
ed0ccc4 feat(catalog): refine category taxonomy to natural guatemalan supermarket terminology
```

---

# Phase 8 Report: Dedicated Shopping List ("Lista de Compras" vs. "Mis Ingredientes")

**Branch:** `feature/shopping-list`  
**User Stories Covered:** `US-8.1`, `US-8.2`  
**Date:** 2026-11-13  

---

## 1. Phase 8 Summary & Implemented Stories

### US-8.1: Separate Shopping List Storage & Input via Text Search and Categories
- **Independent Local Persistence:**
  - Parameterized `IngredientStorageService` with an optional `_storageKey` and added `containsIngredient(String name)` in `lib/features/ingredients/data/ingredient_storage_service.dart`.
  - Created `ShoppingListStorageService` in `lib/features/shopping_list/data/shopping_list_storage_service.dart` backed by its own `SharedPreferences` key (`food_friend_shopping_list`), completely separate from `Mis Ingredientes` (`food_friend_ingredients`).
  - Duplicates added to the shopping list are consolidated case- and accent-insensitively without duplicate rows.
- **Shopping List Input & Two-Tab Navigation:**
  - Updated `AddIngredientScreen` (`lib/features/ingredients/presentation/add_ingredient_screen.dart`) with `isShoppingList` mode (displaying only `Buscar` and `Categorías` tabs, with `'Agregar a lista de compras'` title and shopping-list feedback).
  - Updated `ShoppingListScreen` (`lib/features/shopping_list/presentation/shopping_list_screen.dart`) to host two independent tabs (`Mis ingredientes` and `Por comprar`), keeping `Lista de compras` completely excluded from recipe generation.
  - Updated `HomeScreen` (`lib/features/home/presentation/home_screen.dart`) and `lib/main.dart` with distinct navigation entries for `Ingredientes disponibles` and `Lista de compras`.
  - Added quick-add missing ingredient buttons (per-row and `'Agregar todos'`) directly inside `RecipeDetailScreen` (`lib/features/recipes/presentation/recipe_detail_screen.dart`).
- **Commit:** `9905331` - `feat(shopping-list): implement separate shopping list storage and input flows`

### US-8.2: Shopping List Item Actions (`Comprado` & `Descartar`)
- **Transfer & Dismissal Service Logic:**
  - Added `markAsBought(String name)` to `ShoppingListStorageService`, removing the matched item from `Lista de Compras` and consolidating it into `Mis Ingredientes` (`pantryStorageService`).
  - Added `dismissItem(String name)` to `ShoppingListStorageService`, removing the item from `Lista de Compras` without touching `Mis Ingredientes`.
- **Interactive UI Actions & Immediate Recipe Readiness:**
  - Updated `_buildShoppingListItemCard` in `ShoppingListScreen` to display explicit `Comprado` (`check` SVG, tooltip `'Marcar como comprado'`) and `Descartar` (`delete` SVG, tooltip `'Descartar de la lista'`) buttons inside a responsive `Wrap` layout.
  - Marking an item as `Comprado` transfers it to `Mis ingredientes`, pre-selects it immediately for `Buscar recetas`, and confirms the action with a clear Spanish `SnackBar`; `Descartar` removes it completely with Spanish `SnackBar` confirmation.
- **Commit:** `aa9dc34` - `feat(shopping-list): add bought and dismiss actions to shopping list items`

---

## 2. Automated Test Verification (Phase 8)

| Test Suite | Scope | Result |
| :--- | :--- | :--- |
| `test/unit/shopping_list_storage_service_test.dart` | US-8.1 & US-8.2 independent persistence, duplicate consolidation, `markAsBought`, `dismissItem` | **PASSED** (5 tests) |
| `test/features/shopping_list_screen_test.dart` | `Por comprar` tab, adding via search/closest-match/categories, `Comprado` transfer, `Descartar` dismissal | **PASSED** (9 tests) |
| `test/features/home_screen_test.dart` | Home screen navigation cards for `Ingredientes disponibles` and `Lista de compras` | **PASSED** |
| `test/features/recipe_detail_screen_test.dart` | Quick-adding single and all missing recipe ingredients to `Lista de Compras` | **PASSED** |
| `test/integration/shopping_list_flow_test.dart` | E2E UI flows for US-8.1 and US-8.2 (`Comprado` unlocking recipe generation vs. `Descartar`) | **PASSED** (2 tests) |
| `integration_test/app_test.dart` (`-d flutter-tester`) | Full end-to-end integration tests across all phases including US-8.1 and US-8.2 | **PASSED** (7/7 tests) |
| Entire Project Test Suite (`flutter test`) | All unit, feature, and integration tests across the codebase | **PASSED** (187/187 tests) |

- **Static Analysis:** `flutter analyze` $\rightarrow$ `No issues found!` (0 warnings, 0 errors).
- **Layout & Accessibility Verification:** Zero `RenderFlex` overflows, zero unhandled exceptions.

---

## 3. Git Commit History on Branch `feature/shopping-list`
```
aa9dc34 feat(shopping-list): add bought and dismiss actions to shopping list items
9905331 feat(shopping-list): implement separate shopping list storage and input flows
```



