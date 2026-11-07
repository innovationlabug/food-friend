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
