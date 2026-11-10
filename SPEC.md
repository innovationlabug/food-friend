# Food Friend
Cooking + shopping + nutrition assistant.

## 1. Project overview

Web and mobile app to help the user decide what to cook, what should they buy, and evaluate how nutritious their diet is.

## 2. Target user

Our target user are adults in Guatemala adopting healthy lifestyles through healthy eating. We aim to fulfill some specific needs like having no idea what to cook, choosing healthy and varied recipes, and making the most of our shopping budget.

## 3. Key functionalities

### What do I cook tokay?
- User inputs some ingredients available to them and the app provides recipe suggestions.
- User may filter recipes by how much time they have available to cook.
- User may indicate how many days they want to cook for, and the app can give them suggestions on variations.
- User takes a photo of their refrigerator and the app recognizes ingredients to cook.
    - Validate first: In Latin America many people store food in recycled containers (yogurt, chinese food, etc) so we might not get an accurate reading.

### Recipe history
- User can tell the app if they enjoyed of disliked a recipe for better suggestions.
- App will provide many different recipes so the user can enjoy varied and healthy food.

### Shopping assistant
- User can add their shopping list in the app.
- App will recognize which are the user's favorite ingredients and help keep track how much they have left and when do they expire (for spices, sauces, and other slowly consumed ingredients).
    - Ingredients track `timesUsed` (starts at 0) and `lastUsed` internally to identify favorites and monitor slowly consumed ingredients. The user will almost never interact directly with this information.
- App will use the recipe history to help the user plan their shopping.
- If the user gives GPS access to the app, the app will notify them when they are near some market or supermarket and they are low on some ingredient.
    - Validate first: Since we will use some multi-platform tool such as Flutter, check if we can access the device GPS.
- App will notify the user when there is some sale in some important cooking ingredient.
    - Validate first: Check if we can reliable get info on food sales from supermarket web pages.

### Nutrition assistant
- App will use the recipe history to suggest improvements in user diet. For example, help them complement the vitamins they might be lacking based on their fruit and vegetables consumption.
- App will warn the user about possible healthy risks according to the recipes used. For example, too many recipes with processed ingredients in a short period.
- App will suggest which substitutions or reductions in ingredients can be done without altering the recipe too much, according to the user health goals.

## 4. Data flow and user interface

### Navigation & Shopping List
- **Access shopping list:** User taps button on the main screen to navigate to the shopping list.
- **View available ingredients:** User views the list of current ingredients.
- **Add ingredient action:** User taps button to add new ingredients.

### Adding Ingredients
- **Manual text input with suggestions:**
  - User types ingredient name in an input field.
  - App presents matching suggestions from a predefined list.
  - User picks a suggestion (or best match is auto-selected) to add the ingredient.
- **Category browsing:**
  - User browses hierarchical categories (up to 3–4 levels, e.g., Proteins &rarr; Chicken &rarr; Chicken breast).
  - User selects the specific ingredient to add.
- **Fridge photo upload:**
  - User captures or uploads a photo of their fridge/pantry.
  - Image is sent to backend proxy for LLM object detection.
  - App displays detected ingredients with confidence states (high confidence checked, low unchecked).
  - User reviews/edits checkboxes and confirms additions.
- **Receipt photo upload:**
  - User captures or uploads a photo of a supermarket receipt.
  - Image is sent to backend proxy for LLM data extraction.
  - App displays extracted food ingredients with confidence states.
  - User reviews/edits checkboxes and confirms additions.

### Recipe Generation
- **Select ingredients:** User selects one or more ingredients from their list and requests recipes.
- **Local recipe search:** App searches local offline recipe database for matching recipes.
- **External API lookup:** If no local recipe matches, app queries an external recipe API (traditional API, non-LLM) and displays matching recipes.

## 5. Scope boundaries

- **In Scope:** Simple, responsive interface. 

For the first iterations, we will work under these rules:

- **In Scope:** Saving data locally.
- **Out of Scope:** User authentication. Saving information to an external database.

In the first iterations, while we validate user interest in the project we will have no users. Data will be stored locally either on the user phone or user browser. If we find enough user interest, the option to create user and share date between devices will be added and these rules modified.

## 6. Non-Functional Requirements

- **User Privacy:** Personal user data (such as name and address) will never be collected. Some health related information (such as height, weight, and health goals) will only be used anonimously. If the user chooses to share their GPS information, it will only be used anonimously, and locally in their device if possible.

- **Cost Optimization:** To reduce costs when calling LLMs (if needed), as much work as possible will be done on the user device or on our server.

- **Availability:** The web and mobile app will have several recipes included locally so they can be accessed while the user has no connection. Every call to an LLM (if needed) will have a user-side or server-side fallback.

- **Performance:** The app should be responsive and the user should not have to wait long for the results. This means we should strive for user-side or server-side processing as much as possible and use LLMs as little as possible.

- **Using LLMs only if absolutely needed:** When can include calls to some LLM only if it is absolutely needed. If not, use traditional APIs and tools to solve the problems.


## Week 1 Progress

### Implemented
- Demos.
  - Fridge detector demo: Upload a photo of your fridge so Gemini can recognize which ingredients are there. Feasible to include in the main app: Gemini can recognize several local products, a high/medium/low confidence score is included.
  - Receipt parser demo: Upload a photo of your supermarked receipt so Gemini can recognize which ingredients you got. Feasible to include in the main app: Gemini can recognize several local products, a list of common abreviations was created to help in the process, a high/medium/low confidence score is included.
    - Possible improvement: Use some classic OCR tool instead of calling an LLM.
- Data model.
  - Ingredient and recipe data models created. Several fields are not used yet, but will be used in the following iterations of the app.
- Ingredient list.
  - Add ingredients via text input. Suggests ingredients as the user writes. Pre-populated list with several ingredient name suggestions.
  - Add ingredients via list. A pre-populated list classified into categories and subcategories lets the user add ingredients with a single click.
  - Add ingredients from a refrigerator or a receipt photo. Implementation of the demos. The app presents a user with a list of the high confidence (selected by default) and medium/low confidence (unselected by default) items so they can confirm before adding to the list.
- Recipe suggestions.
  - Pre-populated local list of recipes with common ingredients.
    - Next iterations: Increase the amount of recipes.
  - If there is no local recipe available, call a LLM to generate one.
  - If the LLM call fails, query TheMealDB API to get a recipe. This is our last option since the recipes are in english and some ingredients may not be available.
    - Possible improvement: Find if there is some spanish language recipes API.
  - At this time, the recipes are ranked only by the amount of ingredients that match.
    - Next iterations: User can like or dislike a recipe. The app will track how ofter the recipes are used to provide varied suggestions.

### Next week plan

- Validate features with real users.
- Test the app in real Android phones.

- Recipe suggestions.
  - Increase the amount of local recipes.
  - When the user selects a recipe, it will have a button to generate variations.
    - Variations are similar recipes that use many similar ingredients, often only changing one. In the pre-implementation survey one common problem users faced was that they got bored of a recipe if they cooked for the whole week, these variations may help those users.

- Recipe history.
  - Add a `Did it` button to each recipe, when pressed it stores when the user cooked the recipe.
    - Add sanity checks to this feature: If the user presses it several times a day, it only registers one time.
  - Add four buttons for each recipe.
    - `Favorite`: Recipes marked with this will be suggested more often.
    - `Liked`: Recipe will be suggested again.
    - `Disliked`: Recipe will be suggested only as a last option.
    - `Never`: Recipe won't be suggested again at all.
  - Add a view to allow the user to manage the recipes. In this view they can see all the recipes, included the ones marked with `Never` so they can ammend in case they clicked by accident.
  - Use the marks applied to each recipe and the history when deciding new recipe suggestions.

- Shopping list.
  - User can add ingredients via text field or list, similar to the ingredient list.
  - In the list view, each item will have two buttons.
    - `Bought`: Items will be moved to the ingredient list.
    - `Dismiss`: Items will be removed from this list.

- Nutrition tips.
  - Use the recipe history to provide nutrition tips to the user.
    - Alert about ingredients that might be harmful long term. For example, excesive consumption of processed meats.
    - Suggest which ingredients might be used to obtain health benefits. For example, track fruits and vegetables and suggest the ones that include a vitamin that the user is not consuming enough.