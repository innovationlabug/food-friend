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
