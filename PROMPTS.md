# TASK: Standalone Feasibility Demos (Pre-Implementation Spike)

## Operating Mode: Override AGENTS.md for Demos Only
For this session, you are building quick, isolated proof-of-concept (POC) demos. 
- You are explicitly authorized to bypass standard `AGENTS.md` architectural constraints (e.g., commit conventions, backend architecture, multi-platform setup, strict styling rules).
- Prioritize speed, rapid validation, and whatever local scripts or direct API tooling are easiest to prove the concept.
- Place all demo code in a dedicated sandbox directory: `/demos/` (do not alter any existing project scaffolding).

---

## Goal
Implement two fast, standalone vision demos to evaluate whether Gemini can reliably parse local Guatemalan products and receipts.

### Demo 1: Refrigerator Product Recognition (`/demos/fridge-detector/`)
- **Objective:** Accept or upload an image of a refrigerator/pantry and detect items, specifically testing recognition of Guatemalan consumer goods (e.g., Trebolac, Malher, Incaparina, Tortrix, Sula, local produce).
- **Output:** A simple UI showing identified items, confidence/descriptions, and estimated quantities.

### Demo 2: Supermarket Receipt / Invoice Parser (`/demos/receipt-parser/`)
- This demo will be implemented at a later time. Ignore it by now.

---

## Technical Guidance for Demos
- Use the simplest possible stack to get a working interface right away (e.g., a lightweight single-page HTML/JS app calling the Gemini API with the key in `.env.local`).
- Use Gemini Pro / Flash Vision via `@google/genai` or direct REST calls.
- Include 1–2 sample mock image tests to verify output accuracy immediately.

## General Rules
- Before starting implementation, ask questions if you need any clarification.
- If you need reference photos to test the demos, you can request them.



-----



# TASK: Standalone Feasibility Demos (Pre-Implementation Spike)

## Operating Mode: Override AGENTS.md for Demos Only
For this session, you are building quick, isolated proof-of-concept (POC) demos. 
- You are explicitly authorized to bypass standard `AGENTS.md` architectural constraints (e.g., commit conventions, backend architecture, multi-platform setup, strict styling rules).
- Prioritize speed, rapid validation, and whatever local scripts or direct API tooling are easiest to prove the concept.
- Place all demo code in a dedicated sandbox directory: `/demos/` (do not alter any existing project scaffolding).

---

## Goal
Implement two fast, standalone vision demos to evaluate whether Gemini can reliably parse local Guatemalan products and receipts.

### Demo 1: Refrigerator Product Recognition (`/demos/fridge-detector/`)
- This demo was already implemented. The next demo is independent.

### Demo 2: Supermarket Receipt / Invoice Parser (`/demos/receipt-parser/`)
- **Objective:** Accept or upload a photo of a local supermarket bill (e.g., La Torre, Paiz, Walmart Guatemala).
- **Extraction Targets:**
  - Item name & mapped standard ingredient name.
  - Quantity / Weight.
  - Price in GTQ (Q).
- **Output:** A clean list of available ingredients ready to be tracked into a kitchen pantry state.

---

## Technical Guidance for Demos
- Use the simplest possible stack to get a working interface right away (e.g., a lightweight single-page HTML/JS app calling the Gemini API with the key in `.env.local`).
- Use Gemini Pro / Flash Vision via `@google/genai` or direct REST calls.
- Include 1–2 sample mock image tests to verify output accuracy immediately.

## General Rules
- Before starting implementation, ask questions if you need any clarification.
- You can find some reference images in `demos/receipt-parser/samples`.



---



Use the information from `PLANNING.md`, section `Week 1 updated planning` to fill in the `Data flow and user interface` section in `SPEC.md`. Fill it with short specific interactions. Do not add detailed information in that file. We will continue populating that file as we plan and develop the next features in the app.



---



Use `SPEC.md` and `PLANNING.md` to create `USER_STORIES.md`.

Read `SPEC.md` and `PLANNING.md`. Ask clarifying questions if needed befor proceeding. Based on all these sources, generate a comprehensive `USER_STORIES.md` file. Break the project down into small, sequential phases. `

Make the project initialization the first User Story. Every user story must include specific, testable acceptance criteria.



---



Execute User Story US-1.1 from `USER_STORIES.md`.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`. Run all necessary terminal commands to scaffold the project, set up the directory structure, install dependencies, and remove boilerplate code.

Work autonomously end-to-end:

    Make sure nothing from our base files gets deleted or changed when initializing the project. The only valid change for our base files is appending information.

    Complete each step required by the story's acceptance criteria without asking for intermediate approvals.

    Build and verify there are zero build or type errors. If you hit any errors, debug and resolve them independently.

    Once all acceptance criteria pass, stage and commit the changes using the Conventional Commits format specified in `AGENTS.md`.

Only stop when User Story US-1.1 is fully verified, then report what was done. Wait for user approval before commiting changes.



---



Execute User Story US-1.3 from `USER_STORIES.md`. Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end:

    Complete each step required by the story's acceptance criteria without asking for intermediate approvals.

    Build and verify there are zero build or type errors. If you hit any errors, debug and resolve them independently.

    Once all acceptance criteria pass, stage and commit the changes using the Conventional Commits format specified in `AGENTS.md`.

Only stop when User Story US-1.3 is fully verified, then report what was done.



---



Before proceding we need to implement an important change to the ingredients data model, add these:
- `timesUsed` - starts at zero and will help us track the user favorite ingredients
- `lastUsed` - will help us track when something was last used

The user will almost never interact with this information, it will be mostly used internally by the app

Make these modifications, then make a note in the `US-1.2` user story and any other relevant doc to add these fields



---



Execute the following User Stories from `USER_STORIES.md` sequentially: US-2.1 through US-2.3. These stories implement the functionality to add ingredients.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, create and switch to a new Git branch named appropriately for the task. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Start with a clean session state (if local data persists, trigger the `Borrar mis datos` routine first).
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(ingredients): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize it in `ADD_INGREDIENTS.md`.

After completing the entire batch, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---



Execute the following User Stories from `USER_STORIES.md` sequentially: US-4.1 through US-4.3. These stories implement the functionality to get recipes.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, create and switch to a new Git branch named appropriately for the task. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Start with a clean session state (if local data persists, trigger the `Borrar mis datos` routine first).
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(recetas): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize it in `GET_RECIPES.md`.

After completing the entire batch, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---



Execute the following User Stories from `USER_STORIES.md` sequentially: US-3.1 through US-3.4. These stories implement the functionality to add multiple ingredients at once, via photo.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, create and switch to a new Git branch named appropriately for the task. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Use the sample photos that were used for the demos to test the functionalities.
    * Start with a clean session state.
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(ingredientes): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize it in `GET_RECIPES.md`.

After completing the entire batch, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---



Write a `README.md` for this project.

The `README.md` must contain only the most important information:
- What the app is is.
- Screenshots from the main views.
- A very brief description of key functionalities.
- A quick start guide on how to install, run and deploy.
- An architecture diagram, generated using the `diagram` skill.

You can create as many additional documentation files, in the `docs\readme` folder. Some of them may be:
- `ADD_INGREDIENTS.md` and `GET_RECIPES.md`, the complete documentation on how those features were implemented.
- A complete description of the project architecture. It may include additional diagrams that are not included on the main `README.md`.
- Description of important data models used.
- Description of LLM calls implemented, and their fallbacks.
- Complete guide to install, run and deploy the project.
- Information on unit, integration and e2e testing.
- Any other information you consider deserves its own file.

Write the documentation in spanish. If there is some term without a suitable translation, put the term in english, italicized.



---



We are now working on the second iteration of the project. Use `SPEC.md` and `PLANNING.md` to create `USER_STORIES_2.md`.

Read the latest `Next week plan` section in `SPEC.md` and the `Iteration 2` section in `PLANNING.md`. Ask clarifying questions if needed befor proceeding. Based on all these sources, generate a comprehensive `USER_STORIES_2.md` file. Break the project down into small, sequential phases. `

Every user story must include specific, testable acceptance criteria.



---



Execute the following User Stories from `USER_STORIES_2.md` sequentially: US-5.1 through US-5.2. These stories update the local data.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, check if a relevant Git branch exists and use it. If not, create one named appropriately for the task and switch to it. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Use the sample photos that were used for the demos to test the functionalities.
    * Start with a clean session state.
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES_2.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(ingredientes): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize by updating `ADD_INGREDIENTS.md`.

After completing the entire batch, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---



Execute the following User Stories from `USER_STORIES_2.md` sequentially: US-6.1 through US-6.3. These stories increase the local recipes dataset and deal with recipe variations.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, check if a relevant Git branch exists and use it. If not, create one named appropriately for the task and switch to it. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Use the sample photos that were used for the demos to test the functionalities.
    * Start with a clean session state.
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES_2.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(ingredientes): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize by updating `GET_RECIPES.md`.

After completing the entire batch, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---



Execute the following User Stories from `USER_STORIES_2.md` sequentially: US-7.1 through US-7.4. These stories are related to recipe history.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, check if a relevant Git branch exists and use it. If not, create one named appropriately for the task and switch to it. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Use the sample photos that were used for the demos to test the functionalities.
    * Start with a clean session state.
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES_2.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(ingredientes): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize by updating `GET_RECIPES.md`.

After completing the entire batch, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---


Execute the following User Stories from `USER_STORIES_2.md` sequentially: US-8.1 through US-8.2. These stories are related to the shopping list feature.

Adhere strictly to the rules in `AGENTS.md` and the requirements in `SPEC.md`.

Work autonomously end-to-end for EACH user story in the sequence:

1. **Branch Management:** When starting, check if a relevant Git branch exists and use it. If not, create one named appropriately for the task and switch to it. Ensure all subsequent stories related to that same feature or panel are committed to its corresponding branch.
2. **Implementation & Tests:** Complete each step required by the current story's acceptance criteria without asking for intermediate approvals. In accordance with `AGENTS.md`, write or update the corresponding unit tests and end-to-end integration tests using `package:integration_test`.
3. **Build & Static Verification:** Run `flutter analyze` and `flutter test` to verify there are zero lint issues, type errors, or failing unit tests. If you hit any errors, debug and resolve them independently.
4. **End-to-End Testing:** Once static checks and unit tests pass, execute the automated integration test (e.g., `flutter test integration_test/<test_name>.dart`) to verify the app flow:
    * Use the sample photos that were used for the demos to test the functionalities.
    * Start with a clean session state.
    * Navigate through the ingredient input flow, input the test ingredients, and verify they appear correctly in the list.
    * Ensure there are no layout overflows (`RenderFlex` errors) or uncaught exceptions during execution.
5. **Committing:** After the story is fully implemented, verified, and marked with `[x]` in `USER_STORIES_2.md`, stage and commit the changes using the Conventional Commits specification (e.g., `feat(ingredientes): ...`). Make exactly one commit per story.

Only stop when all specified User Stories are fully implemented, verified, and committed across their respective branches. Then, provide a comprehensive report of what was done and the test results for each story. Summarize by updating `ADD_INGREDIENTS.md`.

Then repeat the complete process for stories US-9.1 to US-9.2. Use the file `NUTRITION_TIPS.md` to document. Use a new branch for this functionality.

After completing the entire two batches, execute `[console]::beep(800, 800)` to notify me that the task is complete.



---



Update the `README.md` for this project.

The `README.md` must contain only the most important information:
- What the app is is.
- Screenshots from the main views. New views have been added since last documentation.
- A very brief description of key functionalities.
- A quick start guide on how to install, run and deploy.
- An architecture diagram, generated using the `diagram` skill.
- A simple comparative table with the info from `COMPETITIVE_ANALYSIS.md`. Mark clearly which functionality we have already implemented, and which are pending.

You can create as many additional documentation files, in the `docs\readme` folder. Some of them may be:
- `ADD_INGREDIENTS.md`, `GET_RECIPES.md` and `NUTRITION_TIPS.md`: the complete documentation on how those features were implemented.
- A complete description of the project architecture. It may include additional diagrams that are not included on the main `README.md`.
- Description of important data models used.
- Description of LLM calls implemented, and their fallbacks.
- Complete guide to install, run and deploy the project.
- Information on unit, integration and e2e testing.
- Any other information you consider deserves its own file.

Notice that many of these were created in the last documentation and might only need to be updated.

Write the documentation in spanish. If there is some term without a suitable translation, put the term in english, italicized.



---



Implement `FEAT-1` from `FEATURES.md` end-to-end.

Adhere strictly to all rules in `AGENTS.md` and requirements in `SPEC.md` (Spanish UI, GTQ currency where applicable, SVG icons only, no pseudo-metadata badges, and offline/local resilience).

Work autonomously through the full lifecycle:

1. **Branch Management:** Create and switch to the suggested feature branch (`feat/cooking-cycle-and-time-filter`) before making changes.
2. **Design & Implementation:** Review the existing codebase first, then implement all deliverables in `FEAT-1` so they integrate cleanly with the current architecture.
3. **Automated Tests:** Create or update unit tests, widget tests, and `package:integration_test` end-to-end tests covering all acceptance criteria in `FEAT-1` (plus backend tests if `/api/*` files are modified).
4. **Verification:** Run `flutter analyze`, `flutter test`, and the relevant `flutter test integration_test/...` suite. Resolve any lint issues, layout overflows, or test failures before finishing.
5. **Tracking & Commit:** Update `FEAT-1` and its acceptance criteria with `[x]` in `FEATURES.md` (and update `SPEC.md` if required by the feature). Stage and commit your changes using Conventional Commits (e.g., `feat(recipes): ...`).

When finished, provide a concise summary of the changes, files touched, and exact test results. Execute `[console]::beep(800, 800)` to notify me when complete.


---


We are now working on the second iteration of the project. Use `SPEC.md` and `PLANNING.md` to update `FEATURES.md`.

Read the latest `Next week plan` section in `SPEC.md` and the `Iteration 3` section in `PLANNING.md`. Ask clarifying questions if needed before proceeding. Based on all these sources, generate a comprehensive `FEATURES.md` file.

Every feature must include product problem, scope and deliverables and acceptance criteria.

Push the current `FEAT-2` and `FEAT-3` to the end of document.


---


Implement `FEAT-2` from `FEATURES.md` end-to-end.

Adhere strictly to all rules in `AGENTS.md` and requirements in `SPEC.md` (Spanish UI, GTQ currency where applicable, SVG icons only, no pseudo-metadata badges, and offline/local resilience).

Work autonomously through the full lifecycle:

1. **Branch Management:** Create and switch to the suggested feature branch (`feat/cooking-cycle-and-time-filter`) before making changes.
2. **Design & Implementation:** Review the existing codebase first, then implement all deliverables in `FEAT-1` so they integrate cleanly with the current architecture.
3. **Automated Tests:** Create or update unit tests, widget tests, and `package:integration_test` end-to-end tests covering all acceptance criteria in `FEAT-1` (plus backend tests if `/api/*` files are modified).
4. **Verification:** Run `flutter analyze`, `flutter test`, and the relevant `flutter test integration_test/...` suite. Resolve any lint issues, layout overflows, or test failures before finishing.
5. **Tracking & Commit:** Update `FEAT-1` and its acceptance criteria with `[x]` in `FEATURES.md` (and update `SPEC.md` if required by the feature). Stage and commit your changes using Conventional Commits (e.g., `feat(recipes): ...`).

When finished, provide a concise summary of the changes, files touched, and exact test results. Execute `[console]::beep(800, 800)` to notify me when complete.


---


Implement `FEAT-4` from `FEATURES.md` end-to-end.

Adhere strictly to all rules in `AGENTS.md` and requirements in `SPEC.md` (Spanish UI, GTQ currency where applicable, SVG icons only, no pseudo-metadata badges, and offline/local resilience).

Work autonomously through the full lifecycle:

1. **Branch Management:** Create and switch to the suggested feature branch (`feat/cooking-cycle-and-time-filter`) before making changes.
2. **Design & Implementation:** Review the existing codebase first, then implement all deliverables in `FEAT-1` so they integrate cleanly with the current architecture.
3. **Automated Tests:** Create or update unit tests, widget tests, and `package:integration_test` end-to-end tests covering all acceptance criteria in `FEAT-1` (plus backend tests if `/api/*` files are modified).
4. **Verification:** Run `flutter analyze`, `flutter test`, and the relevant `flutter test integration_test/...` suite. Resolve any lint issues, layout overflows, or test failures before finishing.
5. **Tracking & Commit:** Update `FEAT-4` and its acceptance criteria with `[x]` in `FEATURES.md` (and update `SPEC.md` if required by the feature). Stage and commit your changes using Conventional Commits (e.g., `feat(recipes): ...`).

When finished, provide a concise summary of the changes, files touched, and exact test results. Execute `[console]::beep(800, 800)` to notify me when complete.


---


# TASK: Standalone Feasibility Demo — FEAT-5 (Supermarket Sales Scraping & Alerts)

## Operating Mode: Override AGENTS.md for Demos Only
For this session, you are building a quick, isolated proof-of-concept (POC) demo to validate the feasibility of `FEAT-5` from `FEATURES.md`.
- You are explicitly authorized to bypass standard `AGENTS.md` architectural constraints (e.g., Flutter stack, Vercel serverless structure, commit conventions, strict styling rules).
- You may use **any minimal standalone tech stack** (e.g., a lightweight Node.js/Express or Python server + single-page HTML/JS UI, or whatever local script/app stack is fastest and most reliable) instead of Flutter.
- Prioritize speed, rapid feasibility validation, and honest technical findings over production polish.
- Place all demo code in a dedicated sandbox directory: `/demos/supermarket-sales/` (do not alter any existing Flutter, `/api/`, or main project scaffolding).

---

## Goal
Implement a standalone minimal app in `/demos/supermarket-sales/` to validate whether promotional/sale data can be reliably fetched and parsed from local Guatemalan supermarket web pages (e.g., Walmart Guatemala and/or La Torre) and matched against a user's shopping needs.

### What to Validate & Build
- **Server-Side Fetch & Scraping Spike:**
  - Test fetching real promotional/offers pages or public endpoints from at least one Guatemalan supermarket (e.g., Walmart Guatemala and/or La Torre) from a backend script/server (not directly from the browser) to evaluate HTML structure, API endpoints, pagination, anti-bot protections, and reliability.
  - Design the retrieval around a cached/scheduled snapshot pattern (so requests don't scrape live on every client view) and include a curated fallback sales snapshot in `GTQ` (`Q`) if live fetching fails or is blocked.
- **Ingredient & Shopping-List Matching:**
  - Seed the demo with sample frequent ingredients (`timesUsed > 0`), sample `Favorita` recipe ingredients, and a mock `"Por comprar"` list.
  - Match fetched (or fallback) supermarket deals against those ingredients.
- **Minimal Demo UI (Spanish):**
  - Show an in-app notification banner and deals list displaying: supermarket name, product/ingredient name, regular vs. discounted price in Quetzales (`Q`), whether it came from a live fetch or fallback snapshot, and a quick button to add/check it in `"Por comprar"`.
  - Include a manual `"Actualizar ofertas ahora"` trigger and a short feasibility findings panel or `README.md` documenting what worked, what failed (e.g., JS-rendered pages, Cloudflare/anti-bot, rate limits), and whether scheduled scraping is viable for the main app.

---

## Technical Guidance for Demo
- Keep everything self-contained inside `/demos/supermarket-sales/` with a simple `README.md` explaining how to install and run it locally on Windows.
- Do not call any LLM unless strictly needed; test traditional HTTP fetching, HTML parsing, or public JSON/GraphQL endpoints first.
- Include automated or reproducible checks verifying live fetch handling, cache snapshot refresh, fallback behavior on network/block errors, and ingredient matching.

## General Rules
- **Branch Isolation:** Before starting implementation, create and switch to a new Git branch (e.g., `demo/supermarket-sales`) and implement all changes there. At the end, commit all changes to that branch without merging or integrating any changes into `main`.
- Before starting implementation, ask questions if you need any clarification.
- Do not modify `SPEC.md`, `FEATURES.md`, or main Flutter app files during this feasibility spike.


---


# TASK: Standalone Feasibility Demo — FEAT-6 (Local GPS Market Proximity Notifications)

## Operating Mode: Override AGENTS.md for Demos Only
For this session, you are building a quick, isolated proof-of-concept (POC) demo to validate the feasibility of `FEAT-6` from `FEATURES.md`.
- You are explicitly authorized to bypass standard `AGENTS.md` architectural constraints (e.g., Flutter stack, Vercel serverless structure, commit conventions, strict styling rules).
- You may use **any minimal standalone tech stack** (e.g., a lightweight HTML/JS/PWA app served locally, or a minimal Node/Vite web app testable on desktop and phone browsers) instead of Flutter.
- Prioritize speed, rapid feasibility validation, and honest technical findings over production polish.
- Place all demo code in a dedicated sandbox directory: `/demos/market-proximity/` (do not alter any existing Flutter, `/api/`, or main project scaffolding).

---

## Goal
Implement a standalone minimal app in `/demos/market-proximity/` to validate the feasibility of local GPS proximity detection and Spanish notifications when a user with pending items in `"Por comprar"` is near a Guatemalan market or supermarket—without ever sending user location data to any server.

### What to Validate & Build
- **100% Local GPS & Privacy Validation:**
  - Request foreground device/browser location with explicit opt-in controls and graceful handling if permission is denied or unavailable.
  - Strictly enforce that GPS coordinates never leave the client device (no backend/API/LLM calls with user coordinates).
  - Test and document browser/OS requirements and limitations (e.g., HTTPS/localhost requirement for Geolocation & Notifications APIs, foreground-only vs. background limits on mobile web).
- **Local Directory of Guatemalan Markets & Supermarkets:**
  - Include a local, extensible JSON/JS dataset of Guatemalan supermarkets and municipal markets (e.g., Mercado Central, Mercado El Guarda, La Torre, Walmart, Paiz) with name, type, latitude, longitude, and zone/municipality, structured so future iterations can support favorite stores.
- **Proximity Detection & Notification Flow (Spanish):**
  - Provide a minimal `"Por comprar"` list where the user can add/remove pending items (and test both empty and non-empty states).
  - Calculate Haversine distance locally against the store dataset. When within threshold (e.g., `<= 500 m`) AND `"Por comprar"` has pending items, trigger a clear Spanish alert banner (and browser Notification API alert if permitted) naming the nearby market/supermarket and the count of pending items. Stay silent when `"Por comprar"` is empty.
  - Include an interactive **Simulation / Test Coordinates Mode** (e.g., preset locations near a market or custom lat/lng sliders/inputs) so the proximity flow can be verified indoors without physically traveling.

---

## Technical Guidance for Demo
- Keep everything self-contained inside `/demos/market-proximity/` with a simple `README.md` explaining how to run it locally on Windows (and how to test on a mobile device if applicable).
- Include unit or browser/scripted tests verifying Haversine distance calculations, threshold boundaries (`<= 500 m` vs. `> 500 m`), empty vs. non-empty `"Por comprar"` behavior, and permission-denied handling.
- Document feasibility findings in `/demos/market-proximity/README.md` (what works cleanly in Web/mobile browsers vs. what would require native Android background permissions).

## General Rules
- **Branch Isolation:** Before starting implementation, create and switch to a new Git branch (e.g., `demo/market-proximity`) and implement all changes there. At the end, commit all changes to that branch without merging or integrating any changes into `main`.
- Before starting implementation, ask questions if you need any clarification.
- Do not modify `SPEC.md`, `FEATURES.md`, or main Flutter app files during this feasibility spike.


---


Implement `FEAT-7` from `FEATURES.md` end-to-end.

Adhere strictly to all rules in `AGENTS.md` and requirements in `SPEC.md` (Spanish UI, GTQ currency where applicable, SVG icons only, no pseudo-metadata badges, and offline/local resilience).

Work autonomously through the full lifecycle:

1. **Branch Management:** Check the current branches, if no relevant branch exist create a new one. Switch to a relevant branch before making changes.
2. **Design & Implementation:** Review the existing codebase first, then implement all deliverables in `FEAT-1` so they integrate cleanly with the current architecture.
3. **Automated Tests:** Create or update unit tests, widget tests, and `package:integration_test` end-to-end tests covering all acceptance criteria in `FEAT-7` (plus backend tests if `/api/*` files are modified).
4. **Verification:** Run `flutter analyze`, `flutter test`, and the relevant `flutter test integration_test/...` suite. Resolve any lint issues, layout overflows, or test failures before finishing.
5. **Tracking & Commit:** Update `FEAT-7` and its acceptance criteria with `[x]` in `FEATURES.md`, mark the completed job in `PENDING.md` (and update `SPEC.md` if required by the feature). Stage and commit your changes using Conventional Commits (e.g., `feat(x): ...`).

When finished, provide a concise summary of the changes, files touched, and exact test results. Execute `[console]::beep(800, 800)` to notify me when complete.


---


Implement `FEAT-9` from `FEATURES.md` end-to-end.

Adhere strictly to all rules in `AGENTS.md` and requirements in `SPEC.md` (Spanish UI, GTQ currency where applicable, SVG icons only, no pseudo-metadata badges, and offline/local resilience).

Work autonomously through the full lifecycle:

1. **Branch Management:** Check the current branches, if no relevant branch exist create a new one. Switch to a relevant branch before making changes.
2. **Design & Implementation:** Review the existing codebase first, then implement all deliverables in `FEAT-1` so they integrate cleanly with the current architecture.
3. **Automated Tests:** Create or update unit tests, widget tests, and `package:integration_test` end-to-end tests covering all acceptance criteria in `FEAT-9` (plus backend tests if `/api/*` files are modified).
4. **Verification:** Run `flutter analyze`, `flutter test`, and the relevant `flutter test integration_test/...` suite. Resolve any lint issues, layout overflows, or test failures before finishing.
5. **Tracking & Commit:** Update `FEAT-9` and its acceptance criteria with `[x]` in `FEATURES.md`, mark the completed job in `PENDING.md` (and update `SPEC.md` if required by the feature). Stage and commit your changes using Conventional Commits (e.g., `feat(x): ...`).

When finished, provide a concise summary of the changes, files touched, and exact test results. Execute `[console]::beep(800, 800)` to notify me when complete.


---


Make a list of this app features. Do not create it from the documentation, but from the real implementation. Present a short list, with a one or two line description of each feature, save that list in `IMPLEMENTED_FEATURES.md`.

Identify which features are core and which are optional. After I manually review the list, we will implement the following changes:

- When the user first enters the app, the app will ask which mode the user wants. `Simple` will give only the most core features. `Full` will give all the features. `Custom` will allow the user to customize their experience.
- The optional features will have a selector in `Settings` which will allow to turn them on or off. When they are off, they will not be shown in the UI and all their interactions with other features or part of the app should not apply.

Do not code this yet, just create the list. I'm just explaining so you can create the list in the best way possible.