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