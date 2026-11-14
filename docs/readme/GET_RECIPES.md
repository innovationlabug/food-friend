# Documentación de Implementación: Descubrimiento, Generación y Gestión de Recetas (Fases 4, 6 y 7)

Este documento detalla la arquitectura, el diseño y los resultados de implementación de las funcionalidades de **Descubrimiento y Generación de Recetas** (**US-4.1** a **US-4.3**), **Variaciones Culinarias y Generación Bajo Demanda** (**US-6.1** a **US-6.3**) e **Historial de Cocina, Preferencias y Gestión de Recetas** (**US-7.1** a **US-7.4**).

---

## 1. Inventario Local y Algoritmo de Coincidencia (Fase 4)

### 1.1. Inventario Precargado
- **Catálogo de Ingredientes Disponibles:** **195+ ingredientes** culinarios únicos organizados en 7 categorías taxonómicas en [`IngredientCatalog`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/data/ingredient_catalog.dart) (con profundidad $\le 4$, sinónimos regionales y búsqueda normalizada).
- **Recetario Local en Español:** **23 recetas auténticas, saludables y variadas** en [`LocalRecipeDataset`](file:///c:/Users/luisr/food-friend/lib/features/recipes/data/local_recipe_dataset.dart), verificadas al 100% contra las hojas del catálogo de ingredientes:
  - *Almuerzos y Guisos:* Pepián de Pollo Tradicional, Hilachas de Res Saludables, Tortitas de Ejote en Salsa de Tomate, Guiso de Pollo con Perulero y Güisquil, Arroz con Pollo y Verduras Casero, Picado de Res con Verduras, Pollo al Curry con Arroz y Maní, Pasta con Pollo y Queso Parmesano, Pasta Integral con Vegetales y Queso Gouda.
  - *Sopas y Caldos:* Caldo de Pollo con Verduras Frescas, Sopa Nutritiva de Lentejas y Espinaca.
  - *Cenas Ligeras:* Pechuga a la Plancha con Verduras al Vapor, Filete de Pescado al Vapor con Limón, Frijoles Negros Parados con Epazote y Queso.
  - *Desayunos:* Omelet de Espinaca y Queso de Capas, Omelet con Queso Gouda y Champiñones, Desayuno Típico Saludable, Avena con Manzana y Nueces.
  - *Ensaladas:* Ensalada Chapina de Aguacate y Tomate, Ceviche Vegetariano de Aguacate y Pepino, Ensalada Fresca de Espinaca, Manzana y Nueces.

### 1.2. Algoritmo de Puntuación Culinaria ([`RecipeSearchService`](file:///c:/Users/luisr/food-friend/lib/features/recipes/data/recipe_search_service.dart))
- Evalúa los ingredientes disponibles del usuario frente a los ingredientes requeridos de cada receta.
- Normaliza nombres ignorando mayúsculas, minúsculas, espacios y tildes mediante [`StringNormalizer`](file:///c:/Users/luisr/food-friend/lib/core/utils/string_normalizer.dart).
- Aplica puentes de sinónimos (*synonym bridges*) culinarios (ej. *güisquil* $\leftrightarrow$ *chayote*, *berenjena* $\leftrightarrow$ *aubergine*, *aguacate* $\leftrightarrow$ *palta*).

---

## 2. Generación con Gemini 3.8 Flash y Respaldo Multinivel

### 2.1. Solución para Combinaciones Sin Coincidencias Locales
Cuando el usuario selecciona combinaciones sin recetas locales precargadas (como `berenjena` + `yuca`) o solicita explícitamente nuevas ideas con inteligencia artificial:
- Se invoca el *endpoint serverless* [`api/recipes.ts`](file:///c:/Users/luisr/food-friend/api/recipes.ts) utilizando el *SDK* oficial `@google/genai` con el modelo `gemini-3.8-flash`.
- **Instrucción del Sistema (*System Instruction*):** El modelo actúa como un *chef* profesional experto en cocina guatemalteca y latinoamericana, devolviendo recetas viables, saludables y estructuradas estrictamente en formato JSON (`response_mime_type: "application/json"`).
- **Respaldo Multinivel (*Fallback Tiers*):**
  1. **Nivel 1 (Principal):** Gemini 3.8 Flash genera recetas en español nativo a la medida de los ingredientes provistos.
  2. **Nivel 2 (Secundario):** Si el *LLM* no está disponible, se consulta a *TheMealDB* mediante puentes de traducción inglés-español.
  3. **Nivel 3 (Local Desconectado):** Si el dispositivo carece de conexión a Internet, se recurre de inmediato a [`LocalRecipeDataset`](file:///c:/Users/luisr/food-friend/lib/features/recipes/data/local_recipe_dataset.dart).

---

## 3. Experiencia de Usuario y Filtros de Recetas

- **Filtros por Tiempo de Comida:** En [`RecipeSuggestionsScreen`](file:///c:/Users/luisr/food-friend/lib/features/recipes/presentation/recipe_suggestions_screen.dart), el usuario cuenta con chips interactivos (*Todos*, *Desayuno*, *Almuerzo*, *Cena*, *Sopas y Caldos*, *Ensaladas*) para acotar las sugerencias.
- **Detalle de Receta e Integración con Compras:** La vista [`RecipeDetailScreen`](file:///c:/Users/luisr/food-friend/lib/features/recipes/presentation/recipe_detail_screen.dart) clasifica visualmente los ingredientes en dos bloques:
  - *Tienes en casa (N):* Ingredientes disponibles marcados con verificación.
  - *Ingredientes adicionales necesarios (M):* Elementos faltantes con botón directo para agregarlos individualmente o en bloque (`"Agregar faltantes a lista de compras"`) hacia la pestaña `Por comprar`.

---

## 4. Variaciones de Recetas y Generación Bajo Demanda (Fase 6)

### 4.1. Modelo y Visor de Variaciones para *Meal Prep* (US-6.1 y US-6.2)
- **Modelo [`RecipeVariation`](file:///c:/Users/luisr/food-friend/lib/features/recipes/domain/recipe_variation.dart):** Describe variaciones culinarias (`recipeId`, `title`, `description`, `swappedIngredients`) asociadas a cada [`Recipe`](file:///c:/Users/luisr/food-friend/lib/features/recipes/domain/recipe.dart).
- **Botón Condicional `"Ver variaciones (N)"`:** En `RecipeDetailScreen`, cuando una receta dispone de variaciones configuradas, se despliega una hoja modal (*modal bottom sheet*) que muestra los ingredientes intercambiados y permite navegar en un toque hacia la receta variante seleccionada.

### 4.2. Botón `"Generar más recetas con IA"` Bajo Demanda (US-6.3)
- En `RecipeSuggestionsScreen`, el botón `"Generar más recetas con IA"` permite solicitar nuevas recetas al *proxy serverless* incluso cuando ya existen sugerencias locales en pantalla.
- Las recetas generadas se anexan de forma no destructiva deduplicando por identificador y título, preservando los resultados locales previos.

---

## 5. Historial de Cocina, Preferencias y Gestión de Recetas (Fase 7)

### 5.1. Registro `"Lo cociné"` e Idempotencia Diaria (US-7.1)
- **Servicio [`RecipeHistoryService`](file:///c:/Users/luisr/food-friend/lib/features/recipes/data/recipe_history_service.dart):** Administra localmente el contador `timesCooked` y las fechas `cookedDates` por cada receta, además de conservar en caché las recetas generadas por IA (`cachedRecipe`).
- **Sincronización con Despensa:** Al pulsar `"Lo cociné"` en `RecipeDetailScreen`, se incrementa el contador de la receta y se actualiza `timesUsed` y `lastUsed` de los ingredientes disponibles empleados.
- **Idempotencia Diaria:** Pulsaciones repetidas durante el mismo día calendario se registran una sola vez, mostrando el estado `"Cocinada hoy"`.

### 5.2. Marcas de Preferencia y Algoritmo de Ranking (US-7.2 y US-7.3)
- **Estados de Preferencia ([`RecipePreference`](file:///c:/Users/luisr/food-friend/lib/features/recipes/domain/recipe_preference.dart)):**
  - `Favorita` (`heart.svg`): Bonificación prioritaria (+12) en el ordenamiento de sugerencias.
  - `Me gustó` (`thumb_up.svg`): Bonificación positiva (+6).
  - `Sin marcar`: Estado neutro por defecto.
  - `No me gustó` (`thumb_down.svg`): Relegada al final de la lista de sugerencias, siempre por debajo de cualquier receta activa.
  - `Nunca` (`block.svg`): Excluida de inmediato de todas las búsquedas de sugerencias.
- **Equilibrio de Variedad:** Las recetas cocinadas recientemente reciben un ajuste de rotación para promover variedad en la dieta semanal.

### 5.3. Pantalla `Gestión de Recetas` (US-7.4)
- Implementada en [`RecipeManagementScreen`](file:///c:/Users/luisr/food-friend/lib/features/recipes/presentation/recipe_management_screen.dart), accesible desde la pantalla principal y el menú lateral.
- Permite buscar por texto y filtrar combinando estado de cocción (*Todas*, *Cocinadas*, *No cocinadas*), marca de preferencia (*Favoritas*, *Me gustó*, *No me gustó*, *Ocultas*, *Sin marcar*) y categoría de comida.
- Desde cada tarjeta el usuario puede consultar cuántas veces ha preparado el platillo y cambiar o quitar la marca `Nunca` para restablecer la receta en las sugerencias.
