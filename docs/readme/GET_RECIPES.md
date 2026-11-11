# Documentación de Implementación: Descubrimiento y Generación de Recetas (Fase 4)

Este documento detalla la arquitectura, el diseño y los resultados de implementación de las historias de usuario de **Descubrimiento y Generación de Recetas** (**US-4.1** a **US-4.3**), incluyendo el algoritmo de coincidencia de ingredientes, el *dataset* local precargado en español, la integración con **Gemini 3.8 Flash** (`gemini-3.8-flash`) vía *backend proxy* y los filtros por tiempo de comida.

---

## 1. Inventario Local y Algoritmo de Coincidencia

### 1.1. Inventario Precargado
- **Catálogo de Ingredientes Disponibles:** **171 ingredientes** culinarios únicos organizados en 7 categorías taxonómicas en `IngredientCatalog` (con profundidad $\le 4$, sinónimos y búsqueda normalizada).
- **Recetario Local en Español:** **16 recetas auténticas, saludables y variadas** en `LocalRecipeDataset`:
  - *Almuerzos y Guisos:* Pepián de Pollo, Hilachas de Res, Tortitas de Ejote en Salsa de Tomate, Guiso de Pollo con Perulero, Arroz con Pollo y Verduras, Picado de Res con Verduras.
  - *Sopas y Caldos:* Caldo de Pollo con Verduras Frescas, Sopa Nutritiva de Lentejas y Espinaca.
  - *Cenas Ligeras:* Pechuga a la Plancha con Verduras al Vapor, Filete de Pescado al Vapor con Limón, Frijoles Negros Parados con Epazote.
  - *Desayunos:* Omelet de Espinaca y Queso de Capas, Desayuno Típico Saludable.
  - *Ensaladas:* Ensalada Chapina de Aguacate y Tomate, Ceviche Vegetariano de Aguacate y Pepino.

### 1.2. Algoritmo de Puntuación Culinaria (`RecipeSearchService`)
- Evalúa los ingredientes que el usuario tiene disponibles frente a los ingredientes requeridos de cada receta.
- Normaliza nombres ignorando mayúsculas, minúsculas, espacios y tildes mediante `StringNormalizer`.
- Aplica puentes de sinónimos (*synonym bridges*) culinarios (ej. *güisquil* $\leftrightarrow$ *chayote*, *berenjena* $\leftrightarrow$ *aubergine*, *aguacate* $\leftrightarrow$ *palta*).
- **Ordenamiento Jerárquico:**
  1. Mayor cantidad de ingredientes coincidentes (`matchCount` descendente).
  2. Mayor porcentaje de coincidencia (`matchPercentage` descendente).
  3. Menor cantidad de ingredientes faltantes.

---

## 2. Generación con Gemini 3.8 Flash y Respaldo Multinivel

### 2.1. El Reto de las Combinaciones Sin Coincidencias Locales
Cuando el usuario selecciona ingredientes poco habituales o combinaciones sin recetas locales precargadas (como `berenjena` + `yuca`), las bases de datos tradicionales en inglés (ej. *TheMealDB*) arrojan cero resultados o títulos con malas traducciones e instrucciones en inglés.

### 2.2. Solución con Gemini 3.8 Flash
- Se integró un *endpoint serverless* en `api/recipes.ts` utilizando el SDK oficial `@google/genai` con el modelo `gemini-3.8-flash`.
- **System Instruction Culinaria:** El modelo actúa como un chef profesional latinoamericano, devolviendo recetas viables, sabrosas y equilibradas estructuradas estrictamente en formato JSON (`response_mime_type: "application/json"`).
- **Respaldo Multinivel:**
  1. **Tier 1 (Principal):** Gemini 3.8 Flash genera recetas en español nativo a la medida de los ingredientes provistos.
  2. **Tier 2 (Secundario):** Si el LLM no está disponible, se consulta en paralelo a TheMealDB mediante puentes de traducción inglés-español.
  3. **Tier 3 (Local Desconectado):** Si el dispositivo está sin conexión, se realiza búsqueda local aproximada en `LocalRecipeDataset`.

---

## 3. Experiencia de Usuario y Filtros de Recetas

- **Filtros por Tiempo de Comida:** En la pantalla `RecipeSuggestionsScreen`, el usuario cuenta con chips de filtro interactivos (*Todos*, *Desayuno*, *Almuerzo*, *Cena*, *Postre*, *Snack*) para acotar las opciones a sus necesidades inmediatas.
- **Detalle de Receta Transparente:** La vista `RecipeDetailScreen` clasifica visualmente los ingredientes en dos bloques:
  - *Tienes en casa (N):* Ingredientes disponibles marcados con verificación verde.
  - *Ingredientes adicionales necesarios (M):* Elementos faltantes claramente identificados para facilitar la planificación.
- **Instrucciones Claras:** Pasos de preparación numerados, tiempos de cocción y porciones estimadas en formato legible sin elementos distractores.

---

## 4. Expansión del Recetario Local, Variaciones de Recetas y Generación con IA (Fase 6)

### 4.1. Expansión del Recetario y Modelo de Variaciones (US-6.1)
- **Incremento del Repertorio:** El catálogo local de recetas en `LocalRecipeDataset` se expandió de 16 a **23 recetas saludables y variadas**, incorporando ingredientes esenciales evaluados por los usuarios (`nueces`, `maní`, `queso gouda`, `queso parmesano` y `curry`).
- **Modelo de Dominio `RecipeVariation`:** Se implementó una entidad ligera y estructurada en `lib/features/recipes/domain/recipe_variation.dart` para describir variaciones culinarias (`recipeId`, `title`, `description`, `swappedIngredients`).
- **Vinculación en `Recipe`:** La clase `Recipe` incorpora `variations`, `variationIds` y el indicador `hasVariations` para asociar recetas alternativas sin duplicar la lógica de negocio.
- **Variaciones Precargadas:** Recetas complementarias vinculadas entre sí (ej. ensaladas con sustitución de nueces y manzana, pastas integrales con cambio de queso gouda a pollo con parmesano, y pollo al curry como alternativa a pechuga a la plancha).
- **Consistencia de Ingredientes:** Se verificó que el 100% de los ingredientes de las recetas coincidan con el catálogo taxonómico `IngredientCatalog`.

### 4.2. Visor de Variaciones en la Pantalla de Detalle (US-6.2)
- **Botón Condicional:** En `RecipeDetailScreen`, se presenta el botón *"Ver variaciones (N)"* con icono SVG exclusivamente cuando la receta dispone de variaciones configuradas.
- **Hoja Modal de Variaciones:** Al pulsar el botón, se despliega una hoja inferior (*modal bottom sheet*) que muestra:
  - Título y descripción explicativa del cambio culinario.
  - Etiquetas con los ingredientes sustituidos.
  - Navegación táctil inmediata hacia la vista completa de la receta variante seleccionada.

### 4.3. Botón de Generación de Recetas con IA Bajo Demanda (US-6.3)
- **Acceso Directo:** En la pantalla `RecipeSuggestionsScreen`, se incluyó el botón *"Generar más recetas con IA"* al pie de la lista de resultados, visible incluso cuando ya existen coincidencias locales.
- **Consulta al Proxy Serverless:** Al presionar el botón, se realiza una petición asíncrona a `POST /api/recipes` enviando los ingredientes seleccionados.
- **Estado de Carga y Prevención de Duplicados:** Muestra el texto *"Generando recetas con IA..."* acompañado de un indicador circular y deshabilita el botón durante la operación para prevenir peticiones simultáneas.
- **Incorporación No Destructiva:** Las recetas devueltas por la IA se anexan a la lista actual eliminando posibles duplicados por título o identificador, preservando intactas las sugerencias locales existentes.
- **Resiliencia ante Fallos:** En caso de corte de red o error en el *backend*, se notifica al usuario con un mensaje amigable en español mediante un *SnackBar*, manteniendo visibles los resultados previos sin interrupciones.

