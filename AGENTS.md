# Project Architecture - Food Friend
Cooking + shopping + nutrition assistant.

## Core Tech Stack
- **Frontend:** Flutter (Web + Android).
- **Backend / Proxy:** Vercel Serverless Functions (Node.js/TypeScript) serving as a lightweight API gateway and security proxy.
- **Deployment:** Vercel for web hosting and API endpoints; direct APK build for Android.
- **External LLM:** Gemini Pro (via Google AI Studio `@google/genai` SDK on the backend proxy), only if strictly needed.

## Constraints & Rules

- **User Privacy:** Information such as user GPS information will only be used locally on their devices.
- **Security:** Never expose API keys in client components. All calls to Gemini or any third-party paid/authenticated API must route through backend Vercel Serverless Functions (`/api/*`), which inject environment secrets (`process.env.GEMINI_API_KEY`) and sanitize user input before forwarding.
- **Styling:** Flutter Material 3 (`useMaterial3: true`) with a centralized `ThemeData`. Use custom responsive breakpoints (`LayoutBuilder` / `MediaQuery`) to adapt fluidly across mobile and desktop browser viewports. Prefer clean SVG assets via `flutter_svg` over icon bloat or emoji characters.
- **Package Management:** Use Dart `pub` (`flutter pub add <package>`) with version pinning in `pubspec.yaml` and committed `pubspec.lock`. For Vercel API functions, use `npm` with `package.json` scoped inside the `/api` or project root.
- **LLM usage:** Only implement calls to LLM if strictly needed. First try to solve any problem by using traditional APIs and tools. Implement client-side or server-side fallbacks in case the LLM calls fail.
- **Testing & Integration Testing:** Automatically create and run unit tests and end-to-end integration tests (using `package:integration_test`) when relevant to the current user story. After implementing a feature or performing a code update, create or update the associated unit and integration tests to verify both business logic and user flows, and run them to ensure zero regressions.

## Development
- The Antigravity IDE tool is being used on Windows.
- Use Windows command line tools when needed, instead of the UNIX versions.

## Style Rules
- All the UI text and labels must be in spanish.
- Amounts of money will be in Guatemalan Quetzales (GTQ / Q).
- The responses from models must be in spanish. The prompts for them can be in english if that improves the results, but the responses must be in spanish.
- All the comments, documentation, and commit messages must be in english.
- Make the frontend look good: prefer a simple, modern and responsive design.
- Do not use excessive animations or transitions.
- Do not use emojis or non-standard characters, use simple svg icons instead.

## Version Control Rules
- Clearly mark the finished features with `[x]` in `USER_STORIES.md`
- After each feature has been completed, reviewed and aproved by the user, stage and commit your changes (`git add .` and `git commit`).
- Use the Conventional Commits specification for the message (e.g., `feat(recipe): implement ingredient calculation`, `fix(layout): adjust listview padding`).
- Summarize the commit based on the specific user story completed and the actual diff of the code.
- When the user instructs you to use multiple branches for development, only perform what you are instructed to. Do not auto merge branches without the user's explicit instruction.

## When finishing a long task
- After fully finishing a task (including all the required reviewing) execute `[console]::beep(800, 800)` to notify the user.

## UI Cleanliness & Information Architecture
- **No Pseudo-Metadata Badges:** Never invent or display tags, badges, or chips for internal mechanisms, input methods, or technical states.
- **Clutter-Free Visuals:** Keep headers and summaries focused. Avoid adding redundant status pills or informational chips unless explicitly requested in the user story.

## Markdown files
- Never modify the `PROMPTS.md` file. This file is a personal history of my most relevant prompts, so other team members can check them later. It should never be auto updated after I prompt the model.

## Demos
- Before starting the implementation of the main project, two demos were implemented. They are located in the `demos` folder.
- When some document say "refer to the demos" it means their functionality, not their exact implementation. The implementation must follow the rules detailed here.