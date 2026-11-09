# User Stories - Iteration 1 (Week 1 Updated Plan)

This document breaks down the **Iteration 1** scope of **Food Friend** (based on `SPEC.md` and `PLANNING.md` — *Week 1 updated planning*) into small, sequential phases with specific, testable acceptance criteria.

---

## Phase 1: Project Initialization & Core Foundation

### - [x] US-1.1: Project Initialization & Workspace Setup
**As a** developer,  
**I want** the Flutter application (Web and Android) and Vercel Serverless Functions project structure initialized with Material 3 theming and Spanish localization defaults,  
**So that** all features can be built on a consistent, responsive, and secure foundation.

#### Acceptance Criteria
- [x] A Flutter project is initialized supporting both **Web** and **Android** targets, with version-pinned dependencies in `pubspec.yaml` and a committed `pubspec.lock`.
- [x] `flutter_svg` is installed and configured for rendering clean SVG icons (no emojis or non-standard characters in the UI).
- [x] A centralized Material 3 theme (`useMaterial3: true`) is configured in the app entry point with responsive layout utilities (`LayoutBuilder` / `MediaQuery`) adapting cleanly between mobile and desktop viewports.
- [x] A Vercel Serverless Functions setup (`/api` directory and `package.json` with `@google/genai` and TypeScript configurations) is initialized at the project root without exposing any API keys to the client.
- [x] All visible UI text, titles, and labels are in Spanish, while all code comments and documentation are in English.
- [x] `flutter analyze` passes with zero errors and the app builds and renders its initial shell on Web and Android.

---

### - [x] US-1.2: Ingredient Data Model & Local Persistence
**As a** user,  
**I want** my available ingredients to be saved locally on my phone or browser using a structured ingredient model,  
**So that** my ingredient list persists across app restarts without requiring an account or external database.

#### Acceptance Criteria
- [x] An `Ingredient` model is implemented with the following fields:
  - `name` (`String`, required): Primary identifier used for recipe matching.
  - `brand` (`String?`, optional): Product brand name.
  - `amountValue` (`double?`, optional) and `amountUnit` (`String?` / enum, optional): Supports units such as `liters`, `milliliters`, `grams`, `pieces`, `units` for future iterations.
  - `expirationDate` (`DateTime?`, optional) and `isBestBefore` (`bool?`, optional): Single date field plus boolean indicator distinguishing expiration date vs. best-before date for future iterations.
  - `timesUsed` (`int`, default `0`): Internal counter tracking how many times the ingredient has been used in recipes.
  - `lastUsed` (`DateTime?`, optional): Internal timestamp indicating when the ingredient was last used.
  > **Note on internal fields**: `timesUsed` and `lastUsed` are internal tracking fields used by the app's heuristics (e.g., identifying user favorite ingredients and cooking frequency). The user will almost never interact directly with this information.
- [x] Serialization (`toJson` / `fromJson`) is implemented and covered by unit tests.
- [x] A local storage service persists and retrieves the list of ingredients locally on both Flutter Web and Android.
- [x] Duplicate ingredient names are handled cleanly (preventing redundant entries or consolidating them).

---

### - [x] US-1.3: Main Screen & Shopping List Navigation
**As a** user,  
**I want** to navigate from the main screen to the shopping list feature, view my available ingredients, and access the add-ingredient flow,  
**So that** I can easily manage the ingredients I have on hand.

#### Acceptance Criteria
- [x] The Main Screen displays a clean, modern Spanish interface with a primary button to enter the Shopping List feature.
- [x] The Shopping List screen provides:
  - A button/action to add new ingredients.
  - A button/view to check the current list of available ingredients.
- [x] The Available Ingredients view displays all locally stored ingredients by their Spanish name, with an option to remove individual items.
- [x] An empty-state message in Spanish is shown when no ingredients have been added yet.
- [x] No pseudo-metadata badges, technical state chips, or input-method tags are displayed on ingredient items.

---

## Phase 2: Manual Ingredient Input (Text Search & Category Browsing)

### - [ ] US-2.1: Predefined Spanish Ingredient Catalog & Category Taxonomy
**As a** user,  
**I want** the app to include a comprehensive catalog of cooking ingredients in Spanish organized both for search and by food categories,  
**So that** I can quickly find specific cuts or general ingredients relevant to cooking in Guatemala.

#### Acceptance Criteria
- [ ] A local predefined dataset of common ingredients in Spanish is created.
- [ ] The catalog includes cooking-specific granularity as well as general options (e.g., `Pechuga de pollo`, `Alitas de pollo`, and generic `Pollo`).
- [ ] The catalog organizes ingredients into a hierarchical tree of at most 3 to 4 levels deep (e.g., Level 1: `Frutas`, `Verduras`, `Proteínas`, `Lácteos`, `Granos y Cereales` &rarr; Level 2 under `Proteínas`: `Res`, `Cerdo`, `Pollo`, `Pescado` &rarr; Level 3 under `Pollo`: `Pechuga de pollo`, `Alitas de pollo`, `Pollo`).

---

### - [ ] US-2.2: Add Ingredient via Text Input with Auto-Suggestions
**As a** user,  
**I want** to type an ingredient name and receive real-time suggestions from the predefined list,  
**So that** my ingredients are added using standardized names that match recipes accurately.

#### Acceptance Criteria
- [ ] The Add Ingredient screen presents a text field in Spanish where the user can type an ingredient name.
- [ ] While typing, matching suggestions from the predefined catalog are displayed in real time (case- and accent-insensitive matching in Spanish).
- [ ] Tapping a suggestion immediately selects and adds that ingredient name to the user's available ingredients list.
- [ ] If the user submits text without tapping a suggestion, the app automatically selects and applies the closest available match from the predefined catalog.
- [ ] Only the ingredient name is required and saved in this iteration.

---

### - [ ] US-2.3: Add Ingredient via Common Ingredient Categories
**As a** user,  
**I want** to browse categorized lists of common ingredients,  
**So that** I can add an ingredient in a few taps without typing.

#### Acceptance Criteria
- [ ] The Add Ingredient screen provides an option to browse ingredients by category.
- [ ] Selecting a top-level category (e.g., `Proteínas`) reveals its subcategories (e.g., `Res`, `Cerdo`, `Pollo`, `Pescado`), and selecting a subcategory reveals specific selectable ingredients (e.g., `Pechuga de pollo`, `Alitas de pollo`, `Pollo`).
- [ ] Reaching and selecting any final ingredient takes at most 3 to 4 steps.
- [ ] Users can navigate back up category levels easily, and tapping a leaf ingredient adds its name to the available ingredients list with visual confirmation in Spanish.

---

## Phase 3: Multi-Ingredient Photo Input (Fridge & Receipt Scanning)

### - [ ] US-3.1: Backend Proxy & Fridge Photo Detection Endpoint
**As a** developer,  
**I want** a Vercel Serverless Function that analyzes refrigerator or pantry photos using Gemini and returns structured ingredient data in Spanish,  
**So that** users can detect multiple ingredients from a photo without exposing API keys on the client.

#### Acceptance Criteria
- [ ] A serverless endpoint (`/api/detect-fridge`) is implemented in TypeScript using `@google/genai` and `process.env.GEMINI_API_KEY`.
- [ ] The endpoint validates and sanitizes the incoming image payload (enforcing size/mime-type limits).
- [ ] The model prompt instructs Gemini to identify food items and Guatemalan brands, returning structured JSON with standardized Spanish ingredient names, optional brand/quantity metadata, and confidence levels (`high`, `medium`, `low`).
- [ ] If the LLM call fails or times out, the endpoint returns a structured Spanish error response so the client fallback can trigger cleanly.

---

### - [ ] US-3.2: Fridge/Pantry Photo Upload & Confirmation UI
**As a** user,  
**I want** to upload or capture a photo of my refrigerator or pantry and review the detected ingredients before saving,  
**So that** I can add multiple available ingredients at once while filtering out inaccurate detections.

#### Acceptance Criteria
- [ ] In the Add Ingredient flow, the user can select or capture a photo of their refrigerator or pantry (supporting both Web file picker and Android camera/gallery).
- [ ] A clean loading state in Spanish is shown while the image is processed by `/api/detect-fridge`.
- [ ] The app displays a confirmation list of detected ingredients:
  - Items with `high` confidence are pre-selected (checked) by default.
  - Items with `medium` or `low` confidence are unselected (unchecked) by default.
- [ ] The user can manually check or uncheck any item and confirm to batch-add the selected ingredient names to their available ingredients list.
- [ ] If the API request fails, a client-side fallback notifies the user in Spanish and directs them smoothly to manual text/category entry.

---

### - [ ] US-3.3: Backend Supermarket Receipt Parser Endpoint
**As a** developer,  
**I want** a Vercel Serverless Function that extracts food ingredients from Guatemalan supermarket receipts using Gemini and a POS abbreviation dictionary,  
**So that** abbreviated receipt lines are accurately converted into standard Spanish ingredient names while ignoring non-food items.

#### Acceptance Criteria
- [ ] A serverless endpoint (`/api/parse-receipt`) is implemented in TypeScript using `@google/genai` and `process.env.GEMINI_API_KEY`.
- [ ] The endpoint includes a maintainable list of common Guatemalan POS abbreviations (e.g., `AR/BLA` &rarr; `Arroz blanco`, `FJOL/NG` &rarr; `Frijol negro`) injected into the prompt context.
- [ ] Non-food household items (cleaning products, toiletries, etc.) are filtered out, and duplicate receipt lines are consolidated.
- [ ] The response returns structured JSON with Spanish ingredient names, optional extracted prices in GTQ (`Q`), and confidence levels (`high`, `medium`, `low`).
- [ ] Proper input sanitization and server-side error handling are enforced.

---

### - [ ] US-3.4: Supermarket Receipt Upload & Confirmation UI
**As a** user,  
**I want** to upload or capture a photo of a supermarket receipt and confirm the extracted food items,  
**So that** I can quickly populate my available ingredients after grocery shopping.

#### Acceptance Criteria
- [ ] In the Add Ingredient flow, the user can upload or capture a photo of a supermarket receipt.
- [ ] A loading state in Spanish is displayed while `/api/parse-receipt` processes the image.
- [ ] Extracted food items are presented in a checklist where `high` confidence items are pre-selected and `medium`/`low` confidence items are unselected.
- [ ] The user can select/unselect items and confirm to save the chosen ingredient names into their local ingredient list.
- [ ] If parsing fails or no food items are detected, a fallback message in Spanish allows the user to retry or switch to manual ingredient entry.

---

## Phase 4: Recipe Generation & Discovery

### - [ ] US-4.1: Local Spanish Recipe Dataset & Model
**As a** user,  
**I want** the app to come preloaded with a diverse set of local recipes in Spanish,  
**So that** I can find meal ideas immediately even when offline or without calling external services.

#### Acceptance Criteria
- [ ] A `Recipe` model is defined containing `id`, `title` (in Spanish), `ingredients` (normalized Spanish ingredient names + display quantities), and `instructions` (ordered preparation steps in Spanish).
- [ ] A static local JSON/Dart dataset is populated with multiple varied, healthy recipes suited to Guatemalan kitchens and matched against the predefined ingredient catalog names.
- [ ] A local recipe search service queries the static dataset by comparing user-selected ingredient names against recipe ingredients and ranks recipes by match count/percentage.

---

### - [ ] US-4.2: Ingredient Selection & Recipe Generation UI
**As a** user,  
**I want** to select one or more ingredients from my available ingredients list and generate matching recipes,  
**So that** I can decide what to cook with what I already have at home.

#### Acceptance Criteria
- [ ] On the Available Ingredients screen, the user can select one or more ingredients (with quick actions to select/deselect) and tap a button in Spanish to search/generate recipes.
- [ ] The app searches the local recipe dataset first and displays matching recipes in a clean, responsive list.
- [ ] Selecting a recipe opens a Recipe Detail view showing:
  - Recipe title in Spanish.
  - Required ingredients (highlighting which ones the user already has vs. any additional ingredients needed).
  - Step-by-step cooking instructions in Spanish.
- [ ] UI remains clutter-free without internal technical badges or source chips.

---

### - [ ] US-4.3: External Recipe API Investigation & Fallback Integration
**As a** user,  
**I want** the app to query an external recipe API when no suitable local recipe matches my selected ingredients,  
**So that** I still receive relevant cooking suggestions without relying on an LLM call.

#### Acceptance Criteria
- [ ] A traditional (non-LLM) recipe API is investigated, documented, and integrated (routed via a backend serverless proxy `/api/recipes` if API keys or Spanish normalization are required).
- [ ] When the local recipe search returns zero suitable matches for the selected ingredients, the app automatically queries the external recipe API.
- [ ] Recipes returned from the external source are mapped to the app's `Recipe` model with titles, ingredients, and instructions presented in Spanish.
- [ ] If the user is offline or the external API request fails, the app gracefully falls back to showing the closest partial matches from the local dataset with an informative Spanish message.

