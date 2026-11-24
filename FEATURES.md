# Features Backlog

This document defines the structured, outcome-oriented **Features** for **Food Friend**, combining the **Iteration 3** roadmap from [SPEC.md](file:///c:/Users/luisr/food-friend/SPEC.md) (*Next week plan*) and [PLANNING.md](file:///c:/Users/luisr/food-friend/PLANNING.md) (*Iteration 3 / Week 3 updated planning*) along with repository GitHub Issues (`innovationlabug/food-friend`). Every feature defines the product problem, scope and deliverables, and testable acceptance criteria.

> **Convention:** Mark completed acceptance criteria and features with `[x]` once implemented, verified, and committed according to [AGENTS.md](file:///c:/Users/luisr/food-friend/AGENTS.md).

---

## - [x] FEAT-1: Post-Cooking Pantry Deduction & Total Cooking Time Filter
- **Source Issue:** [#1 — Cerrar el ciclo diario al cocinar ("¿Qué se te acabó?") y filtrar recetas por tiempo disponible](https://github.com/innovationlabug/food-friend/issues/1)
- **Status:** Completed (`enhancement`)
- **Suggested Branch:** `feat/cooking-cycle-and-time-filter`

### Product Problem
The daily cooking loop currently breaks in two places after the first few days of use:
1. **Stale pantry after cooking:** Tapping `"Lo cociné"` in the recipe detail screen logs the meal in history, but does not deduct depleted items from `"Mis ingredientes"`, update `timesUsed` / `lastUsed`, or move missing items to `"Por comprar"`. As a result, the app keeps recommending recipes using ingredients the user already ran out of.
2. **Missing cooking-time filter:** On weekdays, available time is the primary constraint when deciding what to cook. Although recipes already store `prepTimeMinutes` and `cookTimeMinutes` (and `SPEC.md` includes time filtering), *Sugerencias de Recetas* currently only filters by meal category (`"Desayuno"`, `"Almuerzo"`, `"Cena"`).

### Scope & Deliverables
1. **Quick Pantry Deduction Sheet on `"Lo cociné"`:**
   - When the user taps `"Lo cociné"`, open a quick bottom sheet / modal (`"¿Qué se te acabó?"`) listing the recipe's ingredients currently present in `"Mis ingredientes"`.
   - Allow one-tap selection of ingredients that ran out.
   - Remove marked ingredients from `"Mis ingredientes"`, offer a direct action to send them to `"Por comprar"`, and update `timesUsed` and `lastUsed` on the ingredients used in the recipe.
2. **Total Cooking Time Filter in Recipe Suggestions:**
   - Add time-limit filter chips or a selector (`"≤ 20 min"`, `"≤ 40 min"`, `"≤ 60 min"`, `"Todos"`) based on total time (`prepTimeMinutes + cookTimeMinutes`).
   - Ensure the time filter composes cleanly with the existing meal category filter (`"Desayuno"`, `"Almuerzo"`, `"Cena"`) across both mobile and web viewports.

### Acceptance Criteria (Definition of Done)
- [x] Tapping `"Lo cociné"` opens the quick depletion sheet showing matching pantry ingredients, allowing depleted items to be deducted from `"Mis ingredientes"` and optionally added to `"Por comprar"` in seconds without manual item-by-item editing.
- [x] `timesUsed` and `lastUsed` are updated accurately for used ingredients (while respecting daily idempotency rules for `"Lo cociné"`).
- [x] Users can filter suggested recipes by total time (`prepTimeMinutes + cookTimeMinutes`) alongside meal category on both mobile and web layouts without layout overflows.
- [x] All UI labels and messages are in Spanish, follow Material 3 + SVG icon rules (no emojis or pseudo-metadata badges), and are covered by unit, widget, and integration tests.

---

## - [x] FEAT-2: Health Goal Selection & Goal-Driven Recipe Tooltips
- **Source:** `PLANNING.md` (*Iteration 3 — Nutrition tips*) & `SPEC.md` (*Next week plan*)
- **Status:** Completed (`iteration-3`)
- **Suggested Branch:** `feat/health-goals-and-nutrition-tooltips`

### Product Problem
Current nutrition tips are generic and disconnected from a user's personal health objectives (such as losing weight or gaining muscle). Furthermore, when users browse recipe suggestions, they lack immediate, specific feedback explaining *why* a suggested recipe or its ingredients align with their dietary goals.

### Scope & Deliverables
1. **Health Goal Selection & Local Persistence:**
   - Allow users to select one or more health goals from a predefined Spanish list:
     - `Perder peso / Bajar calorías`
     - `Ganar masa muscular / Más proteína`
     - `Reducir sodio y alimentos procesados`
     - `Aumentar vitaminas y fibra`
   - Persist selected health goals locally on device (Web and Android) without requiring user accounts.
2. **Goal-Driven Nutrition Guidance (Replacing Generic Static Tips):**
   - Replace generic static nutrition tips with dynamic, goal-oriented recommendations and recipe prioritization tailored to the user's active health goals and cooking history.
3. **Specific Goal Tooltips on Recipe Suggestions:**
   - Annotate recipes and ingredients with structured nutritional attributes (high-protein sources, low-calorie density, high-fiber/vitamin sources, low-sodium/whole-food tags).
   - When suggesting a recipe that matches the user's active health goal, render a concise, specific Spanish tooltip stating why it is recommended (e.g., `"La pechuga de pollo es una excelente fuente de proteína"`, `"El güisquil contiene pocas calorías y aporta fibra"`).

### Acceptance Criteria (Definition of Done)
- [x] Users can select, update, and persist their health goals locally in Spanish from the Nutrition / Goals interface, replacing the previous generic static tips.
- [x] Recipe suggestions prioritize dishes aligned with the user's active health goals alongside ingredient availability and user preferences.
- [x] Each goal-matched recipe displays an interactive or inline Spanish tooltip with short, specific nutritional reasoning (e.g., `"X es una excelente fuente de proteína"`, `"X contiene pocas calorías"`).
- [x] Zero LLM calls are required for goal filtering and tooltip generation, and unit/widget tests verify goal persistence, recipe ranking by goal, and tooltip rendering.

---

## - [x] FEAT-3: Smart Shopping List Suggestions from Favorites, History & Health Goals
- **Source:** `PLANNING.md` (*Iteration 3 — Shopping list functionality*) & `SPEC.md` (*Next week plan*)
- **Status:** Completed (`iteration-3`)
- **Suggested Branch:** `feat/smart-shopping-suggestions`

### Product Problem
Users currently build their `"Por comprar"` list entirely from scratch or right after running out of an ingredient. They have no visibility into when buying just 1 or 2 missing ingredients would unlock one of their `Favorita` / `Me gustó` recipes or a dish that directly supports their active health goals.

### Scope & Deliverables
1. **History & Favorite Recipe Gap Engine:**
   - Analyze recipes marked as `Favorita` or `Me gustó` (as well as frequently cooked dishes in `RecipeHistoryService`) against the user's current `"Mis ingredientes"` and `"Por comprar"` lists.
   - Identify "almost-ready" recipes where most ingredients are already available at home and only 1 to 2 key ingredients are missing.
   - Surface actionable Spanish suggestions in the Shopping List view: `"Si compras [Ingrediente X] puedes cocinar [Receta Y] de tus recetas favoritas"`.
2. **Nutrition & Health-Goal Shopping Suggestions:**
   - Evaluate recipes aligned with the user's active health goals and nutrition tips that are missing only a small subset of ingredients.
   - Surface goal-aligned shopping suggestions (e.g., `"Si compras [Ingrediente X] puedes preparar [Receta saludable Y] para tu meta de [Meta]"`).
3. **One-Tap Addition to `"Por comprar"`:**
   - Allow users to add suggested missing ingredients directly into `"Por comprar"` with a single tap, automatically updating or dismissing the suggestion once added.

### Acceptance Criteria (Definition of Done)
- [x] The `"Por comprar"` screen displays a dedicated, clutter-free suggestions section in Spanish when favorite/liked or health-goal recipes are missing only 1–2 ingredients.
- [x] Suggestions explicitly follow the format `"Si compras X puedes cocinar Y de tus recetas favoritas"` (or corresponding health-goal message) using clean SVG icons.
- [x] Tapping a suggested ingredient immediately adds it to `"Por comprar"` without duplicates and refreshes the suggestion list.
- [x] Unit and widget tests verify gap calculation across available pantry items, favorite/liked recipes, and health-goal recipes.

---

## - [ ] FEAT-4: Intelligent Ingredient Replacements for Availability & Health Goals
- **Source:** `PLANNING.md` (*Iteration 3 — Recipe suggestions*) & `SPEC.md` (*Next week plan*)
- **Status:** Open (`iteration-3`)
- **Suggested Branch:** `feat/ingredient-replacements`

### Product Problem
1. **Strict ingredient matching hides cookable meals:** If a recipe calls for an ingredient the user lacks, the user may skip the recipe even though they already have an equivalent substitute in `"Mis ingredientes"` (e.g., having `aceite vegetal` instead of `aceite de oliva`, or `queso de capas` instead of `queso mozzarella`).
2. **Lack of actionable healthier swaps:** Users pursuing health goals need concrete suggestions on which ingredients in a recipe can be swapped for healthier alternatives without ruining the dish.

### Scope & Deliverables
1. **Availability-Driven Ingredient Replacements:**
   - Build a local culinary substitution map linking compatible ingredients in `IngredientCatalog`.
   - When searching recipes, detect when a missing recipe ingredient can be satisfied by a logical substitute currently present in `"Mis ingredientes"`.
   - Highlight in the recipe suggestion and detail screen which recipes can be cooked right away by making that replacement (e.g., `"Puedes usar [Ingrediente disponible A] en lugar de [Ingrediente faltante B]"`).
2. **Health-Goal Ingredient Replacements:**
   - Map healthier ingredient alternatives tailored to the user's selected health goals (e.g., swapping `crema` for `yogur natural` or `aguacate`, `arroz blanco` for `arroz integral`, or `embutidos` for `pechuga de pollo`, `huevo`, or `frijoles`).
   - Display non-intrusive healthier replacement suggestions inside the Recipe Detail view and recipe cards when aligned with the user's health goals.

### Acceptance Criteria (Definition of Done)
- [ ] `RecipeSearchService` identifies recipes that can be cooked by replacing a missing ingredient with a compatible available ingredient from `"Mis ingredientes"`, ranking and labeling the suggested swap clearly in Spanish.
- [ ] `RecipeDetailScreen` displays specific, practical ingredient replacement suggestions both for missing ingredients (using available pantry items) and for active health goals (using healthier alternatives).
- [ ] All substitution rules run deterministically on device with zero extra LLM calls.
- [ ] Unit and widget tests verify availability-based substitution matching and health-goal replacement suggestions.

---

## - [x] FEAT-5: Feasibility Validation & Notifications for Local Supermarket Ingredient Sales
- **Source:** `PLANNING.md` (*Iteration 3 — Ingredient sales notifications*) & `SPEC.md` (*Next week plan*)
- **Status:** Completed (`iteration-3`)
- **Suggested Branch:** `feat/supermarket-sales-notifications`

### Product Problem
Users in Guatemala want to optimize their food budget by knowing when ingredients they regularly use are on sale at local supermarkets. However, scraping supermarket websites directly from the client on every app open is slow, fragile, and subject to anti-bot or CORS restrictions.

### Scope & Deliverables
1. **Feasibility Spike & Scheduled Server-Side Fetch Architecture:**
   - Validate fetching promotional/sale data from local Guatemalan supermarket web pages (such as Walmart Guatemala and/or La Torre).
   - Implement the data retrieval on the backend (`/api/sales`) designed for scheduled execution / server-side caching (e.g., Vercel Cron or cached snapshot refreshed periodically) rather than live scraping on every client request, with a curated fallback sales snapshot in `GTQ` (`Q`).
2. **Frequent-Ingredient & Shopping-List Sale Matching:**
   - Match active supermarket sales against the user's frequently used ingredients (`timesUsed > 0`), ingredients in `Favorita` recipes, and items pending in `"Por comprar"`.
3. **In-App Sales Alerts & Deals View:**
   - Notify the user in Spanish via an in-app notification banner/badge and deals list when frequently used or needed ingredients are on sale, showing the supermarket name, discounted price in Quetzales (`Q`), and an option to add the item to `"Por comprar"`.
   - Structure the supermarket model so future iterations can track the user's favorite market or supermarket.

### Acceptance Criteria (Definition of Done)
- [x] Technical feasibility of fetching local supermarket sales is documented, and `/api/sales` serves cached/scheduled sale data in `GTQ` (`Q`) without triggering live scraping on every client request.
- [x] The client app cross-references `/api/sales` (or offline fallback data) with the user's frequently used ingredients (`timesUsed`) and `"Por comprar"` list.
- [x] Users receive clear Spanish sale notifications/banners for relevant ingredients with prices formatted in Guatemalan Quetzales (`Q`).
- [x] Unit, widget, and backend endpoint tests verify server-side caching/fallback behavior and personalized sale matching.

---

## - [ ] FEAT-6: Feasibility Validation & GPS Proximity Notifications for Markets and Supermarkets
- **Source:** `PLANNING.md` (*Iteration 3 — Market and supermarket notifications*) & `SPEC.md` (*Next week plan*)
- **Status:** Open (`iteration-3`)
- **Suggested Branch:** `feat/market-proximity-notifications`

### Product Problem
Users frequently forget they have pending items on their shopping list (`"Por comprar"`) when passing near a municipal market or supermarket, resulting in missed shopping trips or unplanned expenses.

### Scope & Deliverables
1. **Flutter Location & Notification Feasibility Validation:**
   - Validate obtaining foreground device GPS coordinates in Flutter across Web and Android while strictly keeping all GPS data local on the user's device (never transmitting user coordinates to external servers or LLMs, in accordance with `AGENTS.md` and `SPEC.md`).
2. **Local Dataset of Guatemalan Markets & Supermarkets:**
   - Bundle a local, extensible directory of major Guatemalan supermarkets and municipal markets (name, type, latitude, longitude, and zone/municipality) structured to support favorite store recognition in future iterations.
3. **Proximity Detection & Pending Shopping List Alert:**
   - When the user has pending items in `"Por comprar"` and opts into location checks while using the app (plus a simulation/test trigger for indoor demonstration and testing), calculate Haversine distance locally against the stored markets/supermarkets.
   - When within proximity threshold (e.g., $\le 500\text{ m}$), notify the user in Spanish indicating which market/supermarket is nearby and how many pending items they have in `"Por comprar"`, linking directly to their Shopping List.

### Acceptance Criteria (Definition of Done)
- [ ] GPS location retrieval and proximity calculation run 100% locally on the user's device with graceful permission handling and opt-in privacy controls in Spanish.
- [ ] The app includes a local dataset of Guatemalan markets and supermarkets and detects when the user is near a store while having pending items in `"Por comprar"`.
- [ ] A Spanish notification/alert banner is triggered when near a market/supermarket with pending shopping items (and stays silent when `"Por comprar"` is empty), with a manual simulation mode available for testing/demos.
- [ ] Unit and widget tests verify Haversine distance calculations, empty vs. non-empty shopping list conditions, and permission denial fallbacks.

---

## - [ ] FEAT-7: Scoped Supermarket Price Lookup, Home Savings vs. Takeout & Practical Substitutions
- **Source Issue:** [#2 — Acotar scraping parcial de supermercados y sumar ahorro vs. pedir comida + sustituciones prácticas](https://github.com/innovationlabug/food-friend/issues/2)
- **Status:** Open (`enhancement`)
- **Suggested Branch:** `feat/scoped-prices-savings-substitutions`

### Product Problem
Previous planning included broad supermarket scraping and GPS proximity alerts near markets. Covering every supermarket chain and adding background location permissions will not fit before the December 9 milestone and works poorly on Web. Instead, the scope should be narrowed to a realistic partial price lookup and connected to two high-value daily decisions: estimating money saved cooking at home versus ordering takeout/delivery, and resolving missing or less-healthy ingredients locally.

### Scope & Deliverables
1. **Scoped Partial Supermarket Price / Deals Lookup:**
   - Implement price/deal lookup for **a single Guatemalan supermarket chain** (e.g., La Torre or Walmart Guatemala) covering a focused subset of staple ingredients or items currently in `"Por comprar"`.
   - Route external requests cleanly (via `/api/*` if needed) with a resilient local fallback if the external site changes or fails to respond.
   - **Out of Scope:** GPS proximity notifications and multi-chain full-catalog scraping.
2. **Home Cooking Cost vs. Takeout/Delivery Comparison (`GTQ`):**
   - Use prices in Guatemalan Quetzales (`GTQ` / `Q`) sourced from parsed receipts, partial scraping, or a local baseline price table.
   - Display a simple estimated cost per serving prepared at home compared against typical fast-food or delivery costs on recipes.
3. **Local Practical Ingredient Substitutions:**
   - In the recipe detail screen, display direct replacement options when the user is missing 1 ingredient or when a dish includes a processed/high-fat ingredient (e.g., substituting `crema` with `yogur natural` or `aguacate`, or `embutidos` with `huevo` or `frijol`).
   - Resolve substitutions locally using deterministic rules/mappings without extra LLM calls.
4. **Specification Alignment:**
   - Update `SPEC.md` to reflect the reduced scope (removing GPS alerts and documenting single-chain partial scraping).

### Acceptance Criteria (Definition of Done)
- [ ] `SPEC.md` is updated to reflect the scoped-down supermarket lookup and removal of GPS proximity alerts.
- [ ] Users can view real or fallback `GTQ` prices/deals for items in `"Por comprar"` or basic staples from the single scoped supermarket without the app crashing or blocking if the external source fails.
- [ ] Recipes display a clear, clutter-free `GTQ` cost-per-serving estimate vs. ordering food/delivery.
- [ ] Recipe detail surfaces practical local substitutions for single missing ingredients or healthier swaps without making LLM calls.
- [ ] Unit, widget, and backend/proxy tests verify fallback behavior, `GTQ` calculations, and substitution matching.

---

## - [ ] FEAT-8: Public Web Deployment in README & Real-World Household Validation
- **Source Issue:** [#3 — Publicar deploy web funcional en el README y validar el producto con al menos 5 hogares reales](https://github.com/innovationlabug/food-friend/issues/3)
- **Status:** Open (`enhancement`)
- **Suggested Branch:** `feat/public-deploy-and-field-validation`

### Product Problem
Although `SPEC.md` notes that the app has been deployed to Vercel, `README.md` has no public app URL and still references `git clone https://github.com/luiscu/food-friend.git`. Furthermore, `SURVEY.md` is currently an empty template focused on minor UI details, leaving the core product hypothesis untested: how accurately fridge and receipt scanning perform in real Guatemalan households with reused containers (yogurt/ice cream tubs), unlabeled market bags, and folded or wrinkled receipts.

### Scope & Deliverables
1. **One-Click Public Web Deployment & README Cleanup *(Automatable / Engineering)*:**
   - Ensure the latest web build and Vercel Serverless API proxy (`/api/*`) work end-to-end in production.
   - Add the prominent live web app link at the top of `README.md` and update all repository clone/reference links to `innovationlabug/food-friend`. *(An APK is not required if the mobile web experience works smoothly on phones.)*
2. **Real-World Validation with ≥ 5 Guatemalan Households *(Human / Field Task)*:**
   - Have at least 5 real users open the public link on their phones and complete the full flow using **photos of their own fridge/pantry**, **a real supermarket receipt**, and **selecting a recipe to cook**.
3. **Findings Report & Product Adjustments *(Mixed: Documentation + Follow-up Fixes)*:**
   - Document in `docs/feedback/` which ingredients were recognized accurately, where detection failed (recycled containers, unlabeled market produce, POS receipt abbreviations), user feedback on recipes/shopping, and concrete product fixes applied before **December 9**.

### Acceptance Criteria (Definition of Done)
- [ ] Any user can open the working app directly from the main link at the top of `README.md` on both desktop and mobile browsers, and all repo URLs point to `innovationlabug/food-friend`.
- [ ] Production Vercel deployment handles client routes and `/api/*` endpoints end-to-end without CORS, environment, or proxy errors.
- [ ] `docs/feedback/` contains documented evidence from at least 5 real household tests (real kitchens + real receipts) along with concrete product improvements applied as a result.
