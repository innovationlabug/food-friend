# Pending Work Checklist

A consolidated checklist of remaining items across [SPEC.md](file:///c:/Users/luisr/food-friend/SPEC.md), [PLANNING.md](file:///c:/Users/luisr/food-friend/PLANNING.md), [FEATURES.md](file:///c:/Users/luisr/food-friend/FEATURES.md), and open GitHub Issues (`innovationlabug/food-friend`) to help decide what to implement next.

---

## 1. Open GitHub Issues & Active Features

### Issue #2 / FEAT-7 — Home Savings vs. Takeout & Spec Alignment
*(Note: Supermarket deals lookup via `/api/sales` and practical ingredient substitutions on `RecipeDetailScreen` are already implemented.)*

- [x] **Home cooking cost & nutrition vs. takeout/delivery comparison (`GTQ` + nutrition):**
  - [x] Persist `GTQ` prices from scanned receipts (`ReceiptScannerScreen`) and/or supermarket deals, backed by a local baseline `GTQ` price table for staples.
  - [x] Compute estimated cost per serving (`Q / porción`) for recipes and display a comparison against typical fast-food/delivery costs and nutritional quality on `RecipeDetailScreen` (see `FEAT-7`).
  - [x] Add unit and widget tests for `GTQ` cost calculations, nutritional comparison, and UI display.
- [x] **Update `SPEC.md` for scope alignment:**
  - [x] Document the scoped supermarket price/deals implementation and reflect that GPS proximity alerts are out of scope (per Issue #2).

### Issue #3 / FEAT-8 — Public Web Deploy Cleanup & Household Validation
*(Note: The live Vercel link is already at the top of `README.md`.)*

- [x] **Clean up `README.md`:**
  - [x] Update `git clone` URL from `luiscu/food-friend.git` to `innovationlabug/food-friend.git`.
  - [x] Update outdated entries in the `README.md` status table (mark cooking time filter as implemented and GPS proximity as dropped).
- [x] **Verify production Vercel deployment:**
  - [x] Confirm web client routes (`/`, `/recetas`, `/compras`, `/nutricion`) and all `/api/*` endpoints (`/api/health`, `/api/detect-fridge`, `/api/parse-receipt`, `/api/recipes`, `/api/sales`) work end-to-end in production without CORS or env errors.
- [ ] **Real-world validation with $\ge 5$ Guatemalan households:**
  - [ ] Have $\ge 5$ users test the live web app on their phones with photos of their own fridge/pantry (reused containers, unlabeled market items), a real supermarket receipt, and selecting a recipe to cook.
  - [ ] Document findings in `docs/feedback/` (recognition accuracy, failures, UX feedback) and apply follow-up fixes before December 9.

---

## 2. Unimplemented Items from `SPEC.md` & `PLANNING.md`

### Features & Scope Decisions
- ~~**FEAT-6 — GPS proximity notifications near markets/supermarkets:**~~ **No se implementará (Dropped / Out of Scope).**
  - Marked as out of scope in `SPEC.md`, `FEATURES.md`, `PLANNING.md`, and `README.md` (per Issue #2).
- [ ] **Slowly consumed ingredients — amount & expiration tracking (`SPEC.md` `[PENDING]`):**
  - [ ] Add UI and logic to view/edit `amountValue`, `amountUnit`, `expirationDate`, and `isBestBefore` (fields already exist in `Ingredient` model) for spices, sauces, and pantry staples, plus low-stock / expiration alerts.
- [x] **Multi-day cooking planner (`SPEC.md` / `FEAT-9`):**
  - [x] Allow the user to indicate how many days they want to cook for and suggest a multi-day meal/variation plan (implemented in `FEATURES.md` under `FEAT-9`).
- [ ] **Real Android device testing (`SPEC.md` *Next week plan*):**
  - [ ] Build and test camera, gallery, local storage, and responsive layouts on physical Android phones.

### Future / Backlog Ideas (`PLANNING.md` Iteration 0 & Technical Improvements)
- *(Moved to `FEAT-7`)* **Nutritional comparison vs. takeout:** Extend the home-vs-takeout comparison beyond `GTQ` cost to include nutrition quality.
- [ ] **Classic OCR spike for receipts (`SPEC.md`):** Evaluate using a classic OCR step before or instead of an LLM call on `/api/parse-receipt`.
- [ ] **Spanish-native external recipe API (`SPEC.md`):** Replace or supplement TheMealDB fallback with a Spanish-language recipe API.
- [ ] **Detailed cooking instructions (`PLANNING.md`):** Explore *Cooking for Engineers*-style tabular/structured step-by-step preparation views.
- [ ] **UI/UX polish pass (`PLANNING.md` Week 4):** Refine interface details based on household validation feedback.
