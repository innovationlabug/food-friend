# Iteration 0

## Weekly distribution
Before presenting the project idea, this was our original plan:

### Week 1
- Work in the web and mobile app in parallel, since the beginning.
- Input the ingredients using buttons or text to generate recipes.
    - User can indicate how much time they have available to cook at the beginning, or filter the recipes later.
- Store the recipe history.
    - User can mark if they cooked the recipe, wants to cook it or mark so it won't be shown again.
    - User can indicate if they enjoyed or disliked the recipe.
- Basic shopping list functionality.

### Week 2
- Ingredient input via photo.
- Recipe variations in case the user wants to cook for many meals at a time.
- Use the history to give menu suggestions.
- Provide tips to help user's nutrition.
- Improve shopping list functionality.
    - Give suggestions according to the history.
    - Give suggestions according to nutrition tips.

### Week 3
- Notification on ingredients' sales.
- Suggest relevant and useful ingredient substitutions according to user's health goals.
- Improve shopping list to track slowly consumed ingredients amount and expiration date.
- Notify the user when they are near some market or supermarked and they have some important ingredient missing.

### Week 4
- UI/UX adjustments.
- Detailed user feedback.

---

## Initial feedback
Before starting implementation, we got this team leader feedback:

### Users
- Generalize. Make an app that will get many user, instead of a very specific one.
- Survey before proceding to implement the whole project.
- Find some similar app or product with adoption, with real users, that works for our Latin America context.

### Implementation
- Quickly implement some of the planned features (and some additional ones discussed in the meeting) as standalone demos. The most relevants and demo-worthy are those:
    - Take photos of the user refrigerator to check if an LLM can accurately detect Guatemalan products.
    - Take photos of bills/invoices to known which ingredients are available.
- Then, start the complete project with a single feature.

### Feature ideas
- Compare takeout with what I have in home, moneywise and nutritionwise.
- Heuristics on food consumption.
- Detailed instructions on how to cook (Cooking for Engineers as reference).

---

# Iteration 1

## Demos

### Fridge detector
- User takes a photo of their refrigerator.
- The photo is uploaded to an LLM.
- The LLM detects the products.
- **Result:** Feasible. The LLM (Gemini 3.8 Flash) reliably detects both international and local Guatemalan brands (e.g., Pollo Rey, Ducal, Trebolac, Campero). Obscured products, containers, and leftovers are correctly assigned medium/low confidence with estimated quantities. A confirmation UI with manual editing before saving into pantry is required.

### Receipt parser
- User takes a photo of a supermarket receipt.
- the photo is uploaded to an LLM.
- The LLM detects the products.
- **Result:** Feasible. The LLM accurately decodes Guatemalan POS abbreviations (e.g., AR/BLA, FJOL/NG, CH/MEIN) and maps them to standard ingredient names. Crucially, it reliably separates food ingredients from non-food household purchases (cleaning supplies, toiletries) and extracts prices in GTQ (Q). An option to consolidate duplicate lines and manual ingredient confirmation before adding to pantry is recommended.

## Week 1 updated planning
In response to the demos' results and the feedback "start with a single feature", this is the updated plan for the first iteration.

- Shopping list feature.
    - Each ingredient will have these fields:
        - **Ingredient name:** Used when searching recipes. This is the most important field for each product.
        - **Brand name:** Not required. We are adding it because it was included in the demo.
        - **Amount:** This field has two parts: numeric and unit. The unit can be `liters`, `milliliters`, `grams`, `pieces`, `units`, etc. We will use this in later iterations.
        - **Expiration / best before date:** Only one of these fields will be used for each product. It can be a single date field, and some boolean to tell which kind of date it is. We will use this in later iterations.
        - **Times used (`timesUsed`):** Internal counter starting at 0 to track the user's favorite ingredients.
        - **Last used (`lastUsed`):** Internal timestamp tracking when an ingredient was last used.
        - *Note:* The user will almost never interact with `timesUsed` and `lastUsed`; they are used internally by the app.
    - The main screen will have a button to enter the shoping list feature.
    - The shopping list screen will have a button to add ingredients.
    - The shopping list screen will have a button to check the list of available ingredients.

- Add ingredient feature.
    - A user can add a single ingredient the following ways: entering its name, picking it from a list of common ingredients.
    - A user can add several ingredients at once the following ways: uploading a photo of the ingredients, uploading a photo of a supermarket receipts.
    - In this iteration, only the ingredient name will be added. In later iterations we will add additional information such as amount or expiration date.
    - **Entering an ingredient name:** A text field is presented to the user so it can write an ingredient name. While the user is writing, suggestions are pulled from a predefined list.
        - We aim to have enough suggestions on the list, so the user is always moved to choose one of them.
        - The suggestions are specific enough for the cooking context. For example, it should contain both `chicken breast` and `chicken wings` because some recipes may require different parts. Also include a generic `chicken` option in case the user want something more general.
        - If the user doesn't click on a suggestion, the app should try to apply the best one available anyway.
    - **Selecting from a list of common ingredients:** Show the user some categorized lists so they can choose some ingredient.
        - For example, first show general categories such as `fruits`, `vegetables`, `proteins`. When the user selects `proteins` now show subcategories such as `meat`, `pork`, `chicken`, `fish`. When the user selects `chicken` now show subcategories such as `chicken breast`, `chicken wing`, `chicken`.
        - The selection should be at most three or four steps long.
    - **Uploading a photo of the ingredients:** Refer to the `fridge-detector` demo.
        - The user uploads a photo of their refrigerator, pantry, etc.
        - The photo is sent to an LLM for object detection.
        - Structured data is received as an answer.
        - The items with high confidence are selected, the items with low confidence are unselected. The user can select and unselect items before adding them to their ingredient list.
    - **Uploading a photo of a receipt:** Refer to the `receipt-parser` demo.
        - The user uploads a photo of a supermarket receipt.
        - The photo is sent to an LLM for data extraction.
        - A list with common abreviations may be supplied to the LLM. We will populate this list during the app development.
        - Structered data is received as an answer.
        - The items with high confidence are selected, the items with low confidence are unselected. The user can select and unselect items before adding them to their ingredient list.

- Recipe generation feature.
    - The ingredient screen lets the user select one or more ingredients to generate a recipe.
    - First the app will search in its local data for a recipe, if it doesn't find a suitable one it will query an API for a recipe.

- Local availability for recipes.
    - The base app will have several different recipes available locally. They will include a list of their ingredients so they can be easily searched.
    - Populating this list is a task for the model running here on Antigravity IDE, not a task that the app itself will perform. This task will happen one time when we start developing the app. It will not happen again unless we explicitly request it.

- Access to additional recipes.
    - Investigating and proposing some recipe API is a task for the model running here on Antigravity IDE. It should find a source of recipes we can easily query using traditional tools. 
    - When a suitable recipe is not found locally, the source will be queried to obtain recipes.
    - At this point in the project development, a LLM call should not be used for this.

As of Tuesday 2026-11-10, week 1 planning was successfully implemented.

---

# Iteration 2

## Week 2 updated planning
This is the updated plan for the second iteration.

- Ingredient suggestions.
    - Take a took at Walmart and La Torre websites for ideas on ingredients and classification.
    - Increase the amount of ingredients both in the classified list and on the suggestions shown when the user is inputing text.
    - Some missing ingredients found in user testing: `nueces`, `maní`, `queso gouda`, `queso parmesano`, `curry`.
    - Improve the categories naming, use names logical for Guatemala. For example, no one in Guatemala says `Cucurbitáceas`.

- Recipe suggestions.
    - A variation is a similar recipe that use almost all the same ingredients, usually only one or two will change. In the pre-implementation survey one common problem users faced was that they got bored of a recipe if they cooked for the whole week, these variations may help those users.
    - Add variations for the recipes that it makes sense.
    - When the user selects a recipe, if the recipe has variations a button to see them will be shown.
    - Increase the amount of local recipes. Make sure to add recipes that include the newly added ingredients.
    - At the bottom of the recipe suggestion list add a button to generate additional recipes using AI. This will perform a call to an LLM similar to the one already implemented.

- Recipe history.
    - Add a `Cooked it` button to each recipe.
        - When the user pressed it stores the date the current date in our register of what the user has cooked, and increases the amount of times cooked by one.
        - Add sanity checks to this feature: If the user presses it several times a day, it only registers one time.
    - Add buttons to each recipe so the user can mark if they liked it. The buttons can include text or be an icon.
        - `Favorite`: Recipes marked with this will be suggested more often.
        - `Liked`: Recipe will be suggested again.
        - `Disliked`: Recipe will be suggested as a last option, along with other disliked recipes.
        - `Never`: Recipe won't be suggested again at all. Recipes never get deleted, just hidden permanently.
    - Add a view to allow the user to manage the recipes. In this view they can see all the recipes, included the ones marked with `Never` so they can ammend in case they clicked by accident.
    - Use the marks applied to each recipe and the history when deciding new recipe suggestions.

- Shopping list.
    - User can add ingredients via text field or list, similar to the ingredient list.
    - In the list view, each item will have two buttons.
        - `Bought`: Items will be moved to the ingredient list.
        - `Dismiss`: Items will be removed from this list.

- Nutrition tips.
    - Use the recipe history to provide nutrition tips to the user. At this time we will implement the simplest tips possible.
        - Alert about ingredients that might be harmful long term. For example, if the user has been consuming excesive amount of processed meats lately.
        - Suggest which ingredients might be used to obtain health benefits. For example, track fruits and vegetables and the vitamins they include, if the user seems to be missing some vitamin from their diet suggest them some item that includes it.
        - If the user has been consuming "incomplete proteins" give them pairing suggestions. For example, rice and beans on their own only contain certain aminoacids, but together they can be considered a complete source of protein.