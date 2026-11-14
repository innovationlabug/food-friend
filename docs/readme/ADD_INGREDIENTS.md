# Documentación de Implementación: Entrada de Ingredientes y Lista de Compras (Fases 2, 3, 5 y 8)

Este documento detalla el diseño, la arquitectura y la implementación técnica de las funcionalidades de **Entrada de Ingredientes** y **Lista de Compras**, abarcando el ingreso manual (búsqueda predictiva y taxonomía jerárquica), la entrada inteligente mediante fotografías (refrigerador/congelador y facturas de supermercado), el refinamiento taxonómico guatemalteco y la separación entre inventario disponible (*Mis ingredientes*) y artículos pendientes (*Por comprar*).

---

## 1. Entrada Manual de Ingredientes (Fase 2: US-2.1 a US-2.3)

### 1.1. Catálogo Predefinido y Taxonomía en Español (US-2.1)
- **Componentes:**
  - [`CategoryNode`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/domain/category_node.dart): Nodo recursivo inmutable que modela carpetas intermedias o ingredientes hoja seleccionables. Cuenta con cálculo de profundidad, soporte de sinónimos y recolección recursiva de hojas.
  - [`IngredientCatalog`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/data/ingredient_catalog.dart): Catálogo integral de **195+ ingredientes** representativos de la despensa guatemalteca y latinoamericana.
- **Estructura Taxonómica y Profundidad Estricta:**
  - **Nivel 1 (Categorías Raíz):** *Verduras y Vegetales*, *Proteínas y Carnes*, *Granos, Cereales y Harinas*, *Lácteos y Huevos*, *Frutas*, *Hierbas, Especias y Condimentos*, *Despensa, Aceites y Salsas*.
  - **Nivel 2 (Subcategorías Culinarias):** *Pollo*, *Res*, *Cerdo*, *Pescados y Mariscos*, *Embutidos y carnes frías*, *Frijoles y legumbres*, *Quesos y crema*, *Frutos secos y semillas*, etc.
  - **Nivel 3 y 4 (Ingredientes Hoja):** Ingredientes con granularidad culinaria práctica (ej. *Pechuga de pollo*, *Alitas de pollo*, *Pollo*; *Carne molida de res*, *Posta de res*).
  - **Garantía Arquitectónica:** Profundidad máxima estrictamente menor o igual a 4 niveles ($\le 4$) en todo el árbol, permitiendo llegar a cualquier ingrediente en un máximo de 3 o 4 toques táctiles.
  - **Neutralidad de Marcas:** Los nombres canónicos utilizan descriptores genéricos (ej. *Harina de maíz* en lugar de marcas comerciales), manteniendo las marcas populares (*Maseca*, *Incaparina*, *Maggi*, *Lizano*) únicamente como sinónimos ocultos de búsqueda para comodidad del usuario, salvo productos cuyo nombre propio sea el estándar culinario reconocido (como *Nutella*).

### 1.2. Búsqueda con Sugerencias, *Tooltip* de Ayuda y Coincidencia Aproximada (US-2.2)
- **Pantalla:** [`AddIngredientScreen`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/presentation/add_ingredient_screen.dart), Pestaña 1 (*Buscar*).
- **Filtrado Predictivo en Tiempo Real:** Campo de texto `Nombre del ingrediente` insensible a mayúsculas, minúsculas y tildes mediante [`StringNormalizer`](file:///c:/Users/luisr/food-friend/lib/core/utils/string_normalizer.dart) (ej. escribir `pech` sugiere *Pechuga de pollo*; escribir `guis` sugiere *Güisquil*).
- **Aviso Contextual (*Tooltip*) de Tecla *Enter*:** La primera vez que el usuario comienza a escribir en el buscador, se despliega un aviso informativo explicando que presionar *Enter* agregará automáticamente la primera sugerencia de la lista. Este consejo puede cerrarse permanentemente o restablecerse desde la pantalla de `Configuración`.
- **Permanencia en Pantalla para Carga Continua:** Al agregar un ingrediente (por sugerencia, tecla *Enter* o selección rápida), el usuario permanece por defecto en `AddIngredientScreen` con el campo limpio para seguir ingresando múltiples productos sin interrupciones, contando con un botón directo `Ver lista` en la barra superior y una opción en `Configuración` para activar el retorno automático si lo prefiere.
- **Respaldo por Distancia de *Levenshtein* (*Closest Match*):** Si el usuario escribe una palabra con errores tipográficos y presiona *Guardar* (ej. `tomte` $\rightarrow$ *Tomate*, `pechuga de polo` $\rightarrow$ *Pechuga de pollo*), el algoritmo resuelve el ingrediente canónico más cercano dentro de un umbral seguro de edición.

### 1.3. Exploración Jerárquica por Categorías (US-2.3)
- **Pantalla:** `AddIngredientScreen`, Pestaña 2 (*Categorías*).
- **Navegación Intuitiva:**
  - Encabezado con migas de pan (*breadcrumbs*) interactivas (ej. `Proteínas y Carnes > Pollo`).
  - Botón de retroceso y soporte para el gesto de retroceso del sistema (`PopScope`), subiendo un nivel taxonómico antes de salir de la pantalla.
  - Inserción en almacenamiento local en un solo toque al seleccionar un nodo hoja.

---

## 2. Entrada de Ingredientes vía Fotografía (Fase 3: US-3.1 a US-3.4)

### 2.1. Carga de Fotos de Refrigerador / Congelador (US-3.1)
- **Pantalla:** [`FridgeScannerScreen`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/presentation/fridge_scanner_screen.dart), integrada directamente dentro de la pestaña *Foto* de `AddIngredientScreen`.
- **Capacidades:** Permite capturar imágenes desde la cámara del dispositivo, seleccionar desde la galería o evaluar fotografías de prueba precargadas (`sample01_freezer.jpeg`, `sample02_door.jpeg`, `sample03_refrigerator.jpeg`).
- **Preprocesamiento:** Conversión automática a *Base64* y validación de tipos *MIME*.

### 2.2. Detección Inteligente con Gemini 3.8 Flash (US-3.2)
- **Servicio:** [`FridgeVisionService`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/data/fridge_vision_service.dart) consumiendo `POST /api/detect-fridge`.
- **Inferencia Multimodal:** El modelo `gemini-3.8-flash` analiza la escena visual del refrigerador y devuelve una lista estructurada de alimentos detectados con índice de certeza (*confidence score* entre `0.0` y `1.0`).
- **Ordenamiento por Certeza:** Los alimentos con alta certeza ($\ge 0.8$) aparecen en la parte superior con casillas marcadas por defecto, y los de certeza media se listan debajo para revisión rápida antes de guardarlos.

### 2.3. Escaneo y Extracción de Facturas de Supermercado (US-3.3)
- **Pantalla:** [`ReceiptScannerScreen`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/presentation/receipt_scanner_screen.dart).
- **Servicio:** [`ReceiptParserService`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/data/receipt_parser_service.dart) consumiendo `POST /api/parse-receipt`.
- **Extracción Culinaria:**
  - Reconoce el comercio (ej. *Supermercados La Torre*, *Walmart*, *Paiz*, *Despensa Familiar*) y el monto total en **Quetzales guatemaltecos (`GTQ` / `Q`)**.
  - Decodifica abreviaturas *POS* locales y filtra únicamente productos alimenticios, ignorando bolsas plásticas, artículos de limpieza o descuentos administrativos.

### 2.4. Confirmación y Consolidación en Almacenamiento (US-3.4)
- **Consolidación Sin Duplicados:** Al confirmar los elementos detectados en refrigerador o recibo, [`IngredientStorageService`](file:///c:/Users/luisr/food-friend/lib/features/ingredients/data/ingredient_storage_service.dart) fusiona los ingredientes con los ya existentes en el dispositivo sin crear duplicados.

---

## 3. Expansión del Catálogo y Taxonomía Guatemalteca (Fase 5: US-5.1 y US-5.2)

### 3.1. Refinamiento hacia Términos de Supermercado (US-5.1)
- **Cero Tecnicismos Botánicos:** Se reemplazaron etiquetas académicas (*Cucurbitáceas*, *Hortalizas de fruto*, *Bulbos y Vainas*, *Raíces y Tubérculos*) por las categorías cotidianas utilizadas en los pasillos de *Walmart Guatemala* y *Supermercados La Torre*:
  - *Verduras para cocido y guisos*
  - *Verduras para ensalada*
  - *Cebollas, ajos y chiles*
  - *Hierbas y montes*
  - *Ejotes y arvejas*
  - *Embutidos y carnes frías*
  - *Quesos y crema*
  - *Frutos secos y semillas*

### 3.2. Incorporación de Ingredientes Clave Evaluados por Usuarios (US-5.2)
- Se incorporaron ingredientes solicitados durante pruebas con usuarios reales: *Nueces*, *Maní*, *Queso gouda*, *Queso parmesano* y *Curry*, junto con *Champiñones*, *Brócoli*, *Coliflor*, *Lentejas*, *Garbanzos*, *Almendras*, *Semillas de marañón*, *Pasas*, *Queso cheddar*, *Páprika*, *Jengibre*, *Cúrcuma*, *Jamón de pavo*, *Salami* y *Mortadela*.

---

## 4. Lista de Compras Dedicada y Flujo de Adquisición (Fase 8: US-8.1 y US-8.2)

### 4.1. Separación entre Despensa Disponible y Lista de Compras (US-8.1)
- **Servicio Independiente:** [`ShoppingListStorageService`](file:///c:/Users/luisr/food-friend/lib/features/shopping_list/data/shopping_list_storage_service.dart) gestiona los artículos por comprar bajo la clave dedicada `food_friend_to_buy_shopping_list_v1`, completamente separada del inventario disponible en casa (`food_friend_shopping_list_v1`).
- **Interfaz de Doble Pestaña:** [`ShoppingListScreen`](file:///c:/Users/luisr/food-friend/lib/features/shopping_list/presentation/shopping_list_screen.dart) presenta dos vistas diferenciadas:
  1. **`Mis ingredientes`:** Inventario actual disponible en la despensa o refrigerador para cocinar hoy. Incluye un botón de vaciado con mensaje explícito (`Vaciar toda la lista`) y diálogo de confirmación previo para evitar borrados accidentales.
  2. **`Por comprar`:** Lista de supermercado para organizar futuras compras sin contaminar el cálculo de coincidencias de recetas actuales.
- **Adición Rápida desde Recetas y Consejos Nutricionales:** En `RecipeDetailScreen`, los ingredientes faltantes cuentan con acciones individuales y grupales (`"Agregar faltantes a lista de compras"`). De igual forma, las alertas de vitaminas en `NutritionTipsScreen` permiten añadir los alimentos sugeridos a `Por comprar` con un solo toque.

### 4.2. Acciones de Compra y Descarte (US-8.2)
Cada artículo dentro de la pestaña `Por comprar` ofrece dos acciones directas:
- **`Comprado` (Transferencia a Despensa):** Elimina el artículo de la lista de compras pendientes e inmediatamente lo registra como disponible dentro de `Mis ingredientes`, actualizando el inventario del hogar en una sola operación atómica.
- **`Descartar` (Eliminación Simple):** Retira el artículo de la lista `Por comprar` sin agregarlo a la despensa disponible.
- **Acciones por Lote:** En la parte superior de `Por comprar`, el botón `"Marcar todo comprado"` transfiere toda la compra del supermercado a la despensa en un solo toque, mientras que `"Vaciar"` limpia la lista pendiente.
