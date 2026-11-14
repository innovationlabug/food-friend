# Estrategia y Reporte de Pruebas - Food Friend

Este documento describe la pirámide de pruebas, la cobertura automatizada y los procedimientos de verificación implementados en **Food Friend** a lo largo de sus 9 fases de desarrollo para garantizar la calidad del código, la exactitud de las reglas de negocio y la ausencia de regresiones.

---

## 1. Pirámide de Pruebas

Food Friend estructura su verificación continua en cuatro niveles complementarios:

```text
                / \
               /   \
              / E2E \       Pruebas de Integración de Flujos (test/integration & integration_test)
             /-------\
            / Widget  \     Pruebas de Interfaz y Componentes Reactivos (test/features)
           /-----------\
          /    Unit     \   Pruebas Unitarias de Lógica, Algoritmos y Servicios (test/unit & test/backend)
         /---------------\
        / Estático & Tipos\ Análisis Estático de Código (flutter analyze & TypeScript tsc)
       ---------------------
```

---

## 2. Nivel 1: Análisis Estático y Tipado Estricto

Antes de ejecutar pruebas dinámicas, se valida que tanto el código Dart como las funciones *serverless* en TypeScript cumplan con todas las reglas del analizador:

```powershell
# Verificación de linter y análisis estático en Dart/Flutter
flutter analyze

# Verificación de tipado estricto en TypeScript para funciones serverless
npm run typecheck
```
- **Resultado:** **0 errores, 0 advertencias** (*No issues found!*).

---

## 3. Nivel 2: Pruebas Unitarias (`test/unit/` y `test/backend/`)

Evalúan de forma aislada los modelos de dominio, catálogos, persistencia local, servicios HTTP y reglas deterministas:

| Archivo de Prueba | Componente Evaluado | Casos Clave Verificados |
| :--- | :--- | :--- |
| [`ingredient_model_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/ingredient_model_test.dart) | `Ingredient` | Inmutabilidad, serialización JSON, `copyWith`, formato de cantidades, `markUsed` |
| [`ingredient_storage_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/ingredient_storage_service_test.dart) | `IngredientStorageService` | Persistencia en `shared_preferences`, consolidación sin duplicados, vaciado y ordenamiento |
| [`shopping_list_storage_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/shopping_list_storage_service_test.dart) | `ShoppingListStorageService` | Independencia entre *Mis ingredientes* y *Por comprar*, acción `markAsBought` (*Comprado*) y `removeIngredient` (*Descartar*) |
| [`ingredient_catalog_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/ingredient_catalog_test.dart) | `IngredientCatalog` | Jerarquía estilo supermercado guatemalteco con profundidad $\le 4$, neutralidad de marcas, búsqueda de sinónimos y distancia de *Levenshtein* |
| [`recipe_model_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/recipe_model_test.dart) | `Recipe` & `RecipeVariation` | Serialización de recetas y variaciones (`swappedIngredients`), consistencia del 100% de las 23 recetas locales con el catálogo |
| [`recipe_history_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/recipe_history_service_test.dart) | `RecipeHistoryService` | Registro `"Lo cociné"` con idempotencia diaria, persistencia de las 4 marcas de preferencia (`Favorita`, `Me gustó`, `No me gustó`, `Nunca`) y sincronización con despensa |
| [`recipe_search_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/recipe_search_service_test.dart) | `RecipeSearchService` | Algoritmo de puntuación culinaria, exclusión inmediata de `Nunca`, relegación de `No me gustó`, bonificación de `Favorita` y rotación por variedad |
| [`nutrition_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/nutrition_service_test.dart) | `NutritionService` & `NutritionCatalog` | Regla de exceso de carnes procesadas/embutidos, detección de vitaminas faltantes y recomendación de combinación de proteínas completas (arroz + frijol) |
| [`external_recipe_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/external_recipe_service_test.dart) | `ExternalRecipeService` | Consumo de `/api/recipes`, mapeo de respuestas de Gemini y respaldo *TheMealDB* |
| [`fridge_vision_model_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/fridge_vision_model_test.dart) & [`fridge_vision_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/fridge_vision_service_test.dart) | `FridgeVisionService` | Envío de imágenes *Base64* a `/api/detect-fridge` y ordenamiento por índice de certeza |
| [`receipt_parser_model_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/receipt_parser_model_test.dart) & [`receipt_parser_service_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/receipt_parser_service_test.dart) | `ReceiptParserService` | Extracción de alimentos y montos en Quetzales (`GTQ`) desde `/api/parse-receipt` |
| [`settings_controller_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/settings_controller_test.dart) & [`theme_controller_test.dart`](file:///c:/Users/luisr/food-friend/test/unit/theme_controller_test.dart) | `SettingsController` & `ThemeController` | Persistencia de ajustes de paneles, retorno automático, restablecimiento de *tooltips* y cambio de tema claro/oscuro |

---

## 4. Nivel 3: Pruebas de Interfaz y *Widgets* (`test/features/`)

Verifican el renderizado reactivo, la ausencia de desbordamientos (*RenderFlex*) y las interacciones de usuario en cada pantalla:

| Archivo de Prueba | Pantalla Evaluada | Casos Clave Verificados |
| :--- | :--- | :--- |
| [`home_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/home_screen_test.dart) | `HomeScreen` | Paneles dinámicos según estado de despensa, acceso directo a `Agregar ingredientes`, ocultamiento opcional de paneles y navegación |
| [`shopping_list_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/shopping_list_screen_test.dart) | `ShoppingListScreen` | Pestañas *Mis ingredientes* y *Por comprar*, botones `Comprado` y `Descartar`, diálogo de confirmación antes de vaciar la lista |
| [`add_ingredient_search_test.dart`](file:///c:/Users/luisr/food-friend/test/features/add_ingredient_search_test.dart) & [`add_ingredient_categories_test.dart`](file:///c:/Users/luisr/food-friend/test/features/add_ingredient_categories_test.dart) | `AddIngredientScreen` | Búsqueda predictiva, *tooltip* de primera vez para tecla *Enter*, permanencia en pantalla tras agregar, botón `Ver lista` y árbol de categorías |
| [`fridge_scanner_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/fridge_scanner_screen_test.dart) & [`receipt_scanner_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/receipt_scanner_screen_test.dart) | `FridgeScannerScreen` & `ReceiptScannerScreen` | Escaneo de fotos de muestra, selección por nivel de certeza, desglose en `GTQ` y consolidación en despensa |
| [`recipe_suggestions_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/recipe_suggestions_screen_test.dart) | `RecipeSuggestionsScreen` | Filtros por categoría, porcentajes de coincidencia y botón `"Generar más recetas con IA"` |
| [`recipe_detail_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/recipe_detail_screen_test.dart) | `RecipeDetailScreen` | Botón `"Lo cociné"`, chips de preferencia, visor modal `"Ver variaciones (N)"` y adición de faltantes a `Por comprar` |
| [`recipe_management_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/recipe_management_screen_test.dart) | `RecipeManagementScreen` | Búsqueda y filtros combinados (*Cocinadas*, *Favoritas*, *Ocultas*), conteo de cocciones y restauración de recetas ocultas |
| [`nutrition_tips_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/nutrition_tips_screen_test.dart) | `NutritionTipsScreen` | Renderizado de alertas nutricionales y adición en 1 toque de alimentos sugeridos a la lista de compras |
| [`settings_screen_test.dart`](file:///c:/Users/luisr/food-friend/test/features/settings_screen_test.dart) | `SettingsScreen` | Ordenamiento contextual de secciones, interruptores de paneles, retorno automático, *tooltips* y selector de tema |

---

## 5. Nivel 4: Pruebas de Integración de Flujos Completos (`test/integration/` e `integration_test/`)

Validan recorridos completos de usuario conectando múltiples pantallas y servicios de almacenamiento:
- [`add_ingredients_flow_test.dart`](file:///c:/Users/luisr/food-friend/test/integration/add_ingredients_flow_test.dart): Flujo integral de ingreso manual por búsqueda, tecla *Enter*, categorías y verificación en despensa.
- [`photo_ingredients_flow_test.dart`](file:///c:/Users/luisr/food-friend/test/integration/photo_ingredients_flow_test.dart): Flujo de detección fotográfica de refrigerador y facturas de supermercado hasta la consolidación en `Mis ingredientes`.
- [`recipe_discovery_flow_test.dart`](file:///c:/Users/luisr/food-friend/test/integration/recipe_discovery_flow_test.dart): Flujo desde despensa hacia sugerencias, visualización de variaciones, registro de `"Lo cociné"`, preferencias y administración en `Gestión de Recetas`.
- [`shopping_list_flow_test.dart`](file:///c:/Users/luisr/food-friend/test/integration/shopping_list_flow_test.dart): Flujo de agregar ingredientes faltantes desde una receta a `Por comprar`, marcarlos como `Comprado` y verificar su transferencia automática a `Mis ingredientes`.
- [`nutrition_tips_flow_test.dart`](file:///c:/Users/luisr/food-friend/test/integration/nutrition_tips_flow_test.dart): Flujo desde el registro de recetas cocinadas hasta la generación de alertas en `Consejos de Nutrición` y envío de alimentos ricos en vitaminas a la lista de compras.
- [`settings_flow_test.dart`](file:///c:/Users/luisr/food-friend/test/integration/settings_flow_test.dart): Flujo de personalización desde el menú lateral y verificación en vivo sobre la pantalla principal y el registro de ingredientes.

---

## 6. Comandos de Ejecución

```powershell
# Ejecutar toda la suite de pruebas en Flutter (230+ pruebas)
flutter test

# Ejecutar pruebas de integración de flujos
flutter test test/integration/

# Ejecutar pruebas de endpoints backend en Node.js
node test/backend/detect_fridge_test.mjs
node test/backend/parse_receipt_test.mjs
```
