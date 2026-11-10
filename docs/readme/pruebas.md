# Estrategia y Reporte de Pruebas - Food Friend

Este documento describe la pirámide de pruebas, la cobertura automatizada y los procedimientos de verificación implementados en **Food Friend** para asegurar la calidad del código, la integridad de los datos y la ausencia de regresiones.

---

## 1. Pirámide de Pruebas

Food Friend sigue una rigurosa estrategia de aseguramiento de calidad estructurada en cuatro niveles:

```text
               / \
              /   \
             / E2E \       Pruebas de Integración End-to-End (package:integration_test)
            /-------\
           / Widget  \     Pruebas de Interfaz y Componentes Reactivos (flutter_test)
          /-----------\
         /    Unit     \   Pruebas Unitarias de Lógica, Algoritmos y Modelos (test/unit)
        /---------------\
       / Estático & Tipos\ Análisis Estático de Código (flutter analyze & TypeScript tsc)
      ---------------------
```

---

## 2. Nivel 1: Análisis Estático y Tipado Seguro

Antes de ejecutar pruebas dinámicas, se comprueba que el código no contenga advertencias, tipos implícitos ni infracciones de estilo:

```bash
# Verificación de linter y análisis estático en Dart/Flutter
flutter analyze

# Verificación de tipado estricto en TypeScript para funciones serverless
npm run typecheck
```
- **Resultado:** **0 errores, 0 advertencias** (*No issues found!*).

---

## 3. Nivel 2: Pruebas Unitarias (`test/unit/`)

Verifican de forma aislada las reglas de negocio, la serialización JSON, la persistencia local y los algoritmos de búsqueda:

| Archivo de Prueba | Componente Evaluado | Casos Clave Verificados |
| :--- | :--- | :--- |
| `ingredient_model_test.dart` | `Ingredient` | Inmutabilidad, serialización JSON, `copyWith`, incremento de uso (`markUsed`) |
| `ingredient_storage_service_test.dart` | `IngredientStorageService` | Persistencia en `shared_preferences`, deduplicación de ingredientes, eliminación y ordenamiento |
| `ingredient_catalog_test.dart` | `IngredientCatalog` | Jerarquía taxonómica con profundidad $\le 4$, normalización de acentos, coincidencia aproximada (Levenshtein) |
| `recipe_model_test.dart` | `Recipe` & `RecipeIngredient` | Mapeo de tiempos, porciones, instrucciones y validación de ingredientes opcionales |
| `local_recipe_dataset_test.dart` | `LocalRecipeDataset` | Integridad de las 16 recetas locales precargadas en español, verificación de tiempos de comida |
| `recipe_search_service_test.dart` | `RecipeSearchService` | Algoritmo de puntaje culinario, cálculo de porcentajes de coincidencia, identificación de faltantes |
| `external_recipe_service_test.dart` | `ExternalRecipeService` | Comunicación HTTP con `/api/recipes`, mapeo de respuestas de Gemini y respaldo TheMealDB |
| `fridge_detection_service_test.dart` | `FridgeDetectionService` | Conversión de imágenes a Base64, consumo de `/api/detect-fridge` y ordenamiento por certeza |
| `receipt_parser_service_test.dart` | `ReceiptParserService` | Consumo de `/api/parse-receipt`, parseo de montos en Quetzales (GTQ) y vinculación con catálogo |

---

## 4. Nivel 3: Pruebas de Interfaz y Widgets (`test/features/`)

Evalúan el comportamiento reactivo de las pantallas, la navegación, la respuesta ante eventos táctiles y la adaptación responsiva:

| Archivo de Prueba | Pantalla Evaluada | Casos Clave Verificados |
| :--- | :--- | :--- |
| `home_screen_test.dart` | `HomeScreen` | Renderizado del encabezado de bienvenida, tarjetas de resumen, navegación hacia lista y sugerencias |
| `shopping_list_screen_test.dart` | `ShoppingListScreen` | Estado vacío, marcado de casillas (*checkboxes*), eliminación individual, acción de vaciar lista |
| `add_ingredient_screen_test.dart` | `AddIngredientScreen` | Pestañas *Buscar*, *Categorías* y *Foto*; sugerencias en tiempo real, navegación por árbol y botón atrás |
| `fridge_scanner_screen_test.dart` | `FridgeScannerScreen` | Selección de muestras, visualización ordenada por confianza alta/media, selección múltiple y adición a lista |
| `receipt_scanner_screen_test.dart` | `ReceiptScannerScreen` | Carga de factura, desglose de productos comestibles en Quetzales, validación de montos y guardado |
| `recipe_suggestions_screen_test.dart` | `RecipeSuggestionsScreen` | Filtros por tiempo de comida (*Desayuno*, *Almuerzo*, *Cena*, etc.), ordenamiento por porcentaje de coincidencia |
| `recipe_detail_screen_test.dart` | `RecipeDetailScreen` | Desglose de porciones, lista de ingredientes con indicador visual de disponibles vs faltantes, pasos de cocción |

---

## 5. Nivel 4: Pruebas de Integración End-to-End (`integration_test/`)

Ejecutan flujos de usuario completos de principio a fin utilizando el paquete oficial `package:integration_test`:

- **Flujo de Entrada de Ingredientes:** Navega a la pantalla de agregar, busca por texto con autocompletado, navega por categorías taxonómicas, procesa una imagen de muestra del refrigerador, y comprueba que todos los ingredientes aparezcan consolidados en la lista de compras sin duplicados ni desbordamientos de pantalla (*RenderFlex*).
- **Flujo de Descubrimiento de Recetas:** Con ingredientes específicos en despensa, solicita recetas, filtra por *Almuerzo*, selecciona una receta y valida que los ingredientes faltantes se presenten claramente.

---

## 6. Comandos de Ejecución

Para correr la suite completa de pruebas:

```bash
# Ejecutar todas las pruebas unitarias y de widgets (119 pruebas)
flutter test

# Ejecutar una suite específica
flutter test test/features/recipe_suggestions_screen_test.dart

# Ejecutar pruebas de integración en el navegador Chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_e2e_test.dart -d chrome
```

- **Métricas Actuales:** **119 pruebas unitarias y de interfaz superadas exitosamente (100% de aprobación).**

