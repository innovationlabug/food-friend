# Documentación de Implementación: Entrada de Ingredientes (Fases 2 y 3)

Este documento detalla exhaustivamente el diseño, la arquitectura y la implementación técnica de las funcionalidades de **Entrada de Ingredientes**, abarcando tanto el ingreso manual (búsqueda predictiva y taxonomía jerárquica) como la entrada inteligente mediante fotografías (refrigerador/congelador y facturas de supermercado).

---

## 1. Entrada Manual de Ingredientes (Fase 2: US-2.1 a US-2.3)

### 1.1. Catálogo Predefinido y Taxonomía en Español (US-2.1)
- **Componentes:**
  - `CategoryNode` (`lib/features/ingredients/domain/category_node.dart`): Nodo recursivo que modela carpetas intermedias o ingredientes hoja seleccionables. Cuenta con cálculo de profundidad, soporte de sinónimos y recolección de hojas.
  - `IngredientCatalog` (`lib/features/ingredients/data/ingredient_catalog.dart`): Catálogo integral de **171 ingredientes** representativos de la despensa guatemalteca y latinoamericana.
- **Estructura Taxonómica y Profundidad Estricta:**
  - Nivel 1 (Categorías Raíz): *Verduras y Vegetales*, *Proteínas y Carnes*, *Granos, Cereales y Harinas*, *Lácteos y Huevos*, *Frutas*, *Hierbas, Especias y Condimentos*, *Despensa, Aceites y Salsas*.
  - Nivel 2 (Subcategorías Culinarias): *Pollo*, *Res*, *Cerdo*, *Pescados y Mariscos*, *Embutidos*, *Frijoles*, etc.
  - Nivel 3 y 4 (Ingredientes Hoja): Ingredientes con granularidad culinaria práctica (ej. *Pechuga de pollo*, *Alitas de pollo*, *Pollo*; *Carne molida de res*, *Posta de res*).
  - **Garantía:** Profundidad máxima estrictamente menor o igual a 4 niveles ($\le 4$) en todo el árbol, permitiendo llegar a cualquier ingrediente en 3 o 4 toques táctiles.
  - **Ingredientes Autóctonos de Guatemala:** *Güisquil*, *Perulero*, *Miltomate*, *Chile guaque*, *Chile pasa*, *Chile cobanero*, *Samat*, *Epazote*, *Longaniza guatemalteca*, *Chorizo negro*, *Frijoles negros*, *Masa de maíz*, *Harina de maíz*, *Plátano maduro*, *Queso de capas*, *Queso seco*, *Crema pura*.

### 1.2. Búsqueda con Sugerencias y Coincidencia Aproximada (US-2.2)
- **Pantalla:** `AddIngredientScreen` (`lib/features/ingredients/presentation/add_ingredient_screen.dart`), Pestaña 1 (*Buscar*).
- **Filtrado Predictivo en Tiempo Real:** Campo de texto `Nombre del ingrediente` insensible a mayúsculas, minúsculas y tildes (ej. escribir `pech` sugiere *Pechuga de pollo*; escribir `guis` sugiere *Güisquil*).
- **Selección Directa:** Tocar una sugerencia crea la entidad `Ingredient`, la persiste en `IngredientStorageService`, muestra un mensaje de confirmación (*SnackBar* en español) y regresa a la lista.
- **Respaldo por Distancia de Levenshtein (*Closest Match*):** Si el usuario escribe una palabra con errores tipográficos y presiona *Guardar* (ej. `tomte` $\rightarrow$ *Tomate*, `pechuga de polo` $\rightarrow$ *Pechuga de pollo*), el algoritmo resuelve el ingrediente canónico más cercano.

### 1.3. Exploración Jerárquica por Categorías (US-2.3)
- **Pantalla:** `AddIngredientScreen`, Pestaña 2 (*Categorías*).
- **Navegación Intuitiva:**
  - Encabezado con migas de pan (*breadcrumbs*) interactivo (ej. `Proteínas y Carnes > Pollo`).
  - Botón de retroceso en barra y soporte para botón físico/gesto de Android (`PopScope`), retrocediendo un nivel taxonómico antes de salir de la pantalla.
  - Inserción en almacenamiento local en un toque al seleccionar una hoja.

---

## 2. Entrada de Ingredientes vía Fotografía (Fase 3: US-3.1 a US-3.4)

### 2.1. Carga de Fotos de Refrigerador / Congelador (US-3.1)
- **Pantalla:** `FridgeScannerScreen` (`lib/features/ingredients/presentation/fridge_scanner_screen.dart`).
- **Capacidades:** Permite capturar imágenes directamente desde la cámara del dispositivo, seleccionar de la galería o elegir imágenes de prueba precargadas (`sample01_freezer.jpeg`, `sample02_door.jpeg`, `sample03_refrigerator.jpeg`).
- **Preprocesamiento:** Conversión automática a *Base64* y validación de tipos *MIME*.

### 2.2. Detección Inteligente con Gemini 3.8 Flash (US-3.2)
- **Servicio:** `FridgeDetectionService` consumiendo `POST /api/detect-fridge`.
- **Inferencia:** El modelo Gemini 3.8 Flash analiza la distribución visual del refrigerador y devuelve una lista de alimentos con índice de certeza (*confidence score*).
- **Mejora UI/UX Implementada:**
  - Eliminación de párrafos no estructurados de texto descriptivo.
  - Ordenamiento visual: Los alimentos con alta certeza ($\ge 0.8$) aparecen en la parte superior con casillas marcadas por defecto, y los de certeza media aparecen abajo para revisión rápida.

### 2.3. Escaneo y Extracción de Facturas de Supermercado (US-3.3)
- **Pantalla:** `ReceiptScannerScreen` (`lib/features/ingredients/presentation/receipt_scanner_screen.dart`).
- **Servicio:** `ReceiptParserService` consumiendo `POST /api/parse-receipt`.
- **Extracción Culinaria:**
  - Reconoce el nombre del comercio (ej. *Supermercados La Torre*, *Walmart*) y el monto total en Quetzales (`GTQ` / `Q`).
  - Extrae y filtra únicamente los productos alimenticios, ignorando artículos de limpieza, bolsas plásticas y cargos administrativos.
  - Cada línea de producto incluye cantidad, precio unitario y precio total en Quetzales.

### 2.4. Confirmación y Consolidación en Almacenamiento (US-3.4)
- **Flujo:** Las pantallas de refrigerador y recibo permiten marcar/desmarcar ingredientes detectados antes de confirmar.
- **Consolidación:** Al presionar `Agregar a mi lista`, `IngredientStorageService` consolida los ingredientes nuevos con los ya existentes en el dispositivo, evitando duplicados innecesarios y actualizando contadores de uso.

---

## 3. Optimización de Navegación y UI

En la última iteración de diseño se realizaron mejoras fundamentales:
1. **Pestaña "Foto" Unificada:** Se retiró el botón flotante de cámara y la tarjeta aislada de escaneo, integrando la opción fotográfica como una tercera pestaña (*Foto*) dentro de `AddIngredientScreen`.
2. **Claridad en Etiquetas:** Se eliminaron asteriscos innecesarios en el campo de búsqueda (`Nombre del ingrediente`).
3. **Terminología Consistente:** Se adoptó el término oficial **Ingredientes disponibles** en lugar de *Lista de compras* en todas las vistas principales.

