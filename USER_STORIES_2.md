# User Stories - Iteration 2 (Week 2 Updated Plan)

This document breaks down the **Iteration 2** scope of **Food Friend** (based on `SPEC.md` — *Next week plan* and `PLANNING.md` — *Iteration 2 / Week 2 updated planning*) into small, sequential phases with specific, testable acceptance criteria, continuing directly from `USER_STORIES.md` (Phases 1–4).

---

## Phase 5: Guatemalan Ingredient Catalog & Taxonomy Expansion

### - [x] US-5.1: Guatemalan Supermarket Taxonomy & Category Naming Refinement
**As a** user in Guatemala,  
**I want** ingredient categories and subcategories to use natural, everyday Guatemalan supermarket terminology (inspired by Walmart Guatemala and La Torre),  
**So that** I can browse and find ingredients intuitively without encountering unfamiliar botanical or technical terms.

#### Acceptance Criteria
- [x] All category and subcategory names in `IngredientCatalog` are audited and updated to reflect standard Guatemalan supermarket classifications (referencing Walmart and La Torre naming conventions).
- [x] Technical or botanical group names (such as `Cucurbitáceas`) are absent; everyday terms (such as `Verduras para cocido y guisos`, `Hierbas y montes`, `Embutidos y carnes frías`, `Quesos y crema`, `Frutos secos y semillas`) are used instead.
- [x] The category tree maintains a maximum depth of 3 to 4 steps from root to selectable leaf ingredient.
- [x] Unit tests verify that no technical botanical terms appear in category labels and that all leaf nodes remain reachable within $\le 4$ steps.

---

### - [x] US-5.2: Expanded Ingredient Catalog & User-Tested Missing Staples
**As a** user,  
**I want** an expanded set of ingredients available in both autocomplete text suggestions and category browsing—including items identified during user testing,  
**So that** I can always find the exact ingredients I use in my kitchen.

#### Acceptance Criteria
- [x] The predefined catalog (`IngredientCatalog`) is expanded with additional everyday grocery items found in Walmart Guatemala and La Torre across all food groups.
- [x] All missing ingredients identified in Week 1 user testing are explicitly present as selectable leaf ingredients and searchable with synonyms/diacritic insensitivity:
  - `Nueces` (and singular/synonym `Nuez`)
  - `Maní` (with synonym `Cacahuate`)
  - `Queso gouda`
  - `Queso parmesano`
  - `Curry` (with synonym `Curry en polvo`)
- [x] Both the text-input auto-suggestion engine and the category browser immediately surface all newly added ingredients.
- [x] Unit tests verify exact and fuzzy lookup for `nueces`, `maní`, `queso gouda`, `queso parmesano`, and `curry`.

---

## Phase 6: Recipe Variations, Dataset Expansion & On-Demand AI Generation

### - [x] US-6.1: Expanded Local Recipe Dataset & Pre-Defined Recipe Variations Model
**As a** user who cooks for multiple days of the week,  
**I want** the app to include a larger collection of local Spanish recipes—including recipes using the newly added ingredients and pre-defined recipe variations that swap only one or two ingredients,  
**So that** I can enjoy varied meals throughout the week without getting bored of eating the exact same dish.

#### Acceptance Criteria
- [x] The `Recipe` domain model supports linking pre-defined variations (e.g., via `variationIds` or embedded `RecipeVariation` references pointing to related recipes that share most base ingredients while changing 1–2 ingredients or preparation style).
- [x] `LocalRecipeDataset` is expanded with new healthy Spanish recipes that incorporate the newly added catalog ingredients (including `nueces`, `maní`, `queso gouda`, `queso parmesano`, and `curry`).
- [x] Multiple recipes in `LocalRecipeDataset` include sensible pre-defined variations (for example, a base chicken/vegetable dish and variations changing the sauce/spice such as `curry` or swapping a side/topping).
- [x] Serialization (`toJson` / `fromJson`) and unit tests validate variation links and confirm that every recipe ingredient maps cleanly to `IngredientCatalog`.

---

### - [x] US-6.2: Recipe Variations Viewer in Recipe Detail Screen
**As a** user viewing a recipe,  
**I want** to see a button to explore variations when that recipe has variations available,  
**So that** I can easily switch to a similar dish using almost the same ingredients.

#### Acceptance Criteria
- [x] On `RecipeDetailScreen`, if the selected recipe has one or more pre-defined variations, a clear button in Spanish (e.g., `"Ver variaciones"`) with an SVG icon is displayed.
- [x] If a recipe has no variations defined, the variations button is not shown.
- [x] Tapping `"Ver variaciones"` presents the linked variation recipes (showing how the variation differs in ingredients/preparation) and allows the user to open any variation's full Recipe Detail view.
- [x] Widget tests verify that the button appears only when variations exist and navigates cleanly to the selected variation.

---

### - [x] US-6.3: On-Demand AI Recipe Generation Button in Suggestions List
**As a** user browsing recipe suggestions,  
**I want** a button at the bottom of the recipe suggestion list to generate additional recipes using AI,  
**So that** I can request fresh recipe ideas beyond the local dataset whenever I want more options.

#### Acceptance Criteria
- [x] At the bottom of the recipe list on `RecipeSuggestionsScreen`, a button in Spanish (e.g., `"Generar más recetas con IA"`) is displayed even when local recipes are already listed.
- [x] Tapping the button calls the backend serverless proxy (`POST /api/recipes`) with the user's selected ingredients and appends the newly generated Spanish recipes to the list without removing existing local matches.
- [x] A clear Spanish loading state is shown on the button while awaiting the response, preventing duplicate concurrent requests.
- [x] If the LLM proxy call fails or the device is offline, a friendly Spanish message is displayed (and fallback recipes are provided if available) without crashing or clearing existing results.
- [x] Widget and unit tests verify the button's presence, loading state, appending of AI recipes, and error resilience.

---

## Phase 7: Recipe History, Preferences & Suggestion Ranking

### - [x] US-7.1: Recipe History Log ("Lo cociné") with Daily Idempotency Check
**As a** user,  
**I want** a `"Lo cociné"` button on each recipe that records the date I cooked it and increments its cooked count at most once per day,  
**So that** the app accurately tracks my cooking history even if I tap the button multiple times on the same day.

#### Acceptance Criteria
- [x] A local `RecipeHistoryService` (persisted locally on Web and Android) tracks per-recipe cooking records containing:
  - `timesCooked` (`int`, default `0`)
  - `cookedDates` (`List<DateTime>` storing the dates when the recipe was cooked)
- [x] Each recipe on `RecipeDetailScreen` (and/or recipe card) displays a `"Lo cociné"` button in Spanish with a clean SVG icon.
- [x] When the user taps `"Lo cociné"` for a recipe not yet logged today:
  - The current date is added to `cookedDates` and `timesCooked` increases by `1`.
  - Matching available ingredients have their internal `timesUsed` incremented and `lastUsed` updated.
  - A Spanish confirmation feedback is shown.
- [x] **Sanity check (same-day idempotency):** If the user taps `"Lo cociné"` multiple times on the same calendar day for the same recipe, it registers only once for that calendar day (`timesCooked` does not increment again on the same day, and the UI reflects that it was already logged today).
- [x] Unit and widget tests verify first-tap registration and same-day duplicate prevention.

---

### - [x] US-7.2: Recipe Preference Marks (`Favorita`, `Me gustó`, `No me gustó`, `Nunca`)
**As a** user,  
**I want** four preference options on each recipe (`Favorita`, `Me gustó`, `No me gustó`, `Nunca`),  
**So that** I can tell the app which recipes I want suggested more often, less often, or never again.

#### Acceptance Criteria
- [x] A `RecipePreference` enum is defined with four selectable states (plus `none` when unmarked):
  - `favorite` (`Favorita`): Suggested more often.
  - `liked` (`Me gustó`): Suggested again normally/positively.
  - `disliked` (`No me gustó`): Suggested only as a last option alongside other disliked recipes.
  - `never` (`Nunca`): Permanently hidden from recipe suggestions (never deleted from local storage).
- [x] Each recipe presents four clear Spanish preference buttons/icons allowing the user to set or toggle their preference mark, persisted locally via `RecipeHistoryService`.
- [x] Marking a recipe as `Nunca` immediately excludes it from future recipe suggestion lists while keeping the recipe record intact in storage.
- [x] Unit and widget tests verify saving, toggling, and persisting all four preference states.

---

### - [x] US-7.3: Preference- & History-Aware Recipe Suggestion Ranking
**As a** user,  
**I want** recipe suggestions to prioritize my favorite and liked recipes, demote disliked recipes to the bottom, and hide recipes marked as `Nunca`,  
**So that** suggested meals match my tastes and cooking history.

#### Acceptance Criteria
- [x] `RecipeSearchService` incorporates user preference marks and cooking history from `RecipeHistoryService` when filtering and ranking recipes:
  1. Recipes marked `Nunca` (`never`) are strictly filtered out of suggestion results.
  2. Active recipes (`favorite`, `liked`, or unmarked) are ranked ahead of any `disliked` (`No me gustó`) recipes.
  3. Among recipes with comparable ingredient match scores, `favorite` (`Favorita`) recipes receive a ranking boost, followed by `liked` (`Me gustó`), while recently cooked recipes are balanced to encourage variety.
  4. Recipes marked `disliked` (`No me gustó`) appear at the very end of the suggestion list as a last option.
- [x] Unit tests verify the exact ordering behavior across `favorite`, `liked`, unmarked, `disliked`, and `never` recipes.

---

### - [x] US-7.4: Recipe Management & History View (`Gestión de Recetas`)
**As a** user,  
**I want** a dedicated view to see and manage all recipes—including those marked as `Nunca`—and review my cooking history,  
**So that** I can amend any preference mark if I clicked `Nunca` by accident.

#### Acceptance Criteria
- [x] A **Gestión de Recetas** screen is accessible from the main navigation / Home Screen.
- [x] The view lists all known recipes (all local dataset recipes plus any saved AI/external recipes in history), including recipes marked with `Nunca` (`never`), with filter tabs or sections (e.g., `Todas`, `Favoritas`, `Cocinadas`, `Ocultas (Nunca)`).
- [x] For each recipe, the user can see how many times they cooked it (`timesCooked`), its current preference state, and can directly change or clear the preference mark (`Favorita`, `Me gustó`, `No me gustó`, `Nunca`) or open its detail view.
- [x] Changing a recipe from `Nunca` to another state immediately restores it to normal recipe suggestion eligibility.
- [x] Widget tests verify viewing hidden (`Nunca`) recipes and restoring them via preference changes.

---

## Phase 8: Dedicated Shopping List ("Lista de Compras" vs. "Mis Ingredientes")

### - [x] US-8.1: Separate Shopping List Storage & Input via Text Search and Categories
**As a** user,  
**I want** a dedicated Shopping List (`Lista de Compras`) separate from my available home ingredients (`Mis Ingredientes`), where I can add items to buy via text search or category browsing,  
**So that** I can keep track of what I need to purchase at the supermarket versus what I already have at home.

#### Acceptance Criteria
- [x] Local storage maintains two distinct lists:
  - **Mis Ingredientes (Disponibles en casa):** Used as the source for recipe generation and populated via manual add, fridge/receipt scan, or moving bought items from the shopping list.
  - **Lista de Compras (Por comprar):** Items the user plans to buy.
- [x] Users can add items to the **Lista de Compras** using the same Spanish autocomplete text field (with closest-match fallback) and hierarchical category browser from `IngredientCatalog`, as well as quick-adding missing ingredients from `RecipeDetailScreen`.
- [x] Duplicate items added to the Shopping List are consolidated cleanly without creating duplicate rows.
- [x] Unit and widget tests verify independent persistence of both lists and adding items to the Shopping List.

---

### - [ ] US-8.2: Shopping List Item Actions (`Comprado` & `Descartar`)
**As a** user at the supermarket,  
**I want** each item in my Shopping List to have `"Comprado"` and `"Descartar"` buttons,  
**So that** bought items move directly into my available home ingredients while unneeded items are removed.

#### Acceptance Criteria
- [ ] In the **Lista de Compras** view, every shopping list item displays two explicit action buttons (using clean SVG icons and Spanish labels/tooltips):
  - **`Comprado` (`Bought`):** Removes the item from the Shopping List and automatically adds it to the user's available **Mis Ingredientes** list (consolidating if already present).
  - **`Descartar` (`Dismiss`):** Removes the item from the Shopping List without adding it to the available ingredients list.
- [ ] Brief Spanish feedback (SnackBar) confirms when an item is moved to **Mis Ingredientes** or dismissed.
- [ ] Widget and integration tests verify that tapping `Comprado` transfers the ingredient to available ingredients and makes it immediately selectable for recipe generation, while `Descartar` removes it completely.

---

## Phase 9: Nutrition Tips Based on Recipe History

### - [ ] US-9.1: Nutritional Metadata & Deterministic Nutrition Heuristics Engine
**As a** user striving for a healthier diet,  
**I want** the app to analyze my cooked recipe history locally and generate simple nutrition alerts and suggestions,  
**So that** I learn about long-term dietary risks, missing vitamins, and complete protein pairings without needing complex calorie tracking or LLM calls.

#### Acceptance Criteria
- [ ] Ingredients in `IngredientCatalog` (or a dedicated nutrition mapping table) include lightweight nutritional tags:
  - **Processed / harmful-in-excess category:** Flags processed meats and high-sodium cured items (e.g., `Salchicha`, `Jamón`, `Chorizo`, `Longaniza`, `Tocino`, `Mortadela`, `Salami`).
  - **Vitamin contributions:** Maps fruits and vegetables to key vitamins/micronutrients (e.g., `Vitamina A`, `Vitamina C`, `Vitamina K / Folato`, `Hierro`, `Potasio`) along with recommended Spanish food sources from the catalog.
  - **Incomplete protein groups:** Distinguishes plant grain/cereal proteins (e.g., `Arroz blanco`, `Arroz integral`, `Masa de maíz`, `Tortillas de maíz`, `Avena`) from legume/seed proteins (e.g., `Frijoles negros`, `Frijoles rojos`, `Lentejas`, `Garbanzos`, `Maní`) to detect unpaired vs. paired plant proteins.
- [ ] A deterministic `NutritionService` evaluates the user's logged cooking history (`RecipeHistoryService`) and outputs structured Spanish nutrition tips across three rules:
  1. **Long-term health alert:** Triggers a warning if the user's recent cooked recipes frequently include processed meats (e.g., $\ge 2$ cooked meals with processed meats in the last 7 days or $\ge 30\%$ of recent logged meals).
  2. **Missing vitamin suggestion:** Checks which vitamins have been covered by fruits and vegetables in recent cooked recipes; for any untracked/missing vitamin, suggests specific fruits or vegetables from the catalog rich in that vitamin.
  3. **Incomplete protein pairing tip:** Detects when recent cooked recipes include grains (like rice or corn) or legumes (like beans or lentils) without a complementary protein source in the same meal, and provides a clear Spanish tip explaining how pairing them (e.g., `Arroz` + `Frijoles`) forms a complete protein with all essential amino acids.
- [ ] Unit tests cover all three heuristic rules (processed meat alert threshold, missing vitamin detection, and incomplete protein pairing recommendation).

---

### - [ ] US-9.2: Nutrition Tips Screen & Home Summary Card
**As a** user,  
**I want** to view my personalized nutrition tips on a dedicated screen and via a summary card on the Home Screen,  
**So that** I can easily apply healthy adjustments to my next meals and grocery shopping.

#### Acceptance Criteria
- [ ] The **Home Screen** includes entry navigation and/or a summary card for **Consejos de Nutrición**, alongside clear navigation to **Mis Ingredientes**, **Lista de Compras**, and **Gestión de Recetas**.
- [ ] The **Consejos de Nutrición** screen displays the active tips in Spanish using clean SVG icons (distinguishing health alerts, vitamin suggestions, and protein pairing tips) with zero emojis or technical pseudo-metadata badges.
- [ ] When a vitamin suggestion recommends specific fruits or vegetables, the user can tap an action to add the suggested ingredient directly to their **Lista de Compras**.
- [ ] If the user has not logged any cooked recipes yet, an encouraging Spanish empty-state message explains that logging meals with `"Lo cociné"` unlocks personalized nutrition tips, while showing foundational healthy eating tips (such as complete protein pairing with rice and beans).
- [ ] Widget and integration tests verify rendering of all three tip categories, adding a recommended vitamin-rich ingredient to the Shopping List, and `flutter analyze` passing with zero issues.
