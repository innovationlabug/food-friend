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
