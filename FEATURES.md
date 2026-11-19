# Features Backlog

This document translates the repository's open GitHub Issues (`innovationlabug/food-friend`) into structured, outcome-oriented **Features**. Each feature maps directly to a GitHub Issue and defines the product problem, scope, constraints, and acceptance criteria needed for end-to-end delivery.

> **Convention:** Mark completed acceptance criteria and features with `[x]` once implemented, verified, and committed according to `AGENTS.md`.

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

## - [ ] FEAT-2: Scoped Supermarket Price Lookup, Home Savings vs. Takeout & Practical Substitutions
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

## - [ ] FEAT-3: Public Web Deployment in README & Real-World Household Validation
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
