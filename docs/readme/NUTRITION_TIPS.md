# Documentación de Implementación: Consejos de Nutrición Basados en Historial (Fase 9)

Este documento describe la arquitectura, el catálogo nutricional determinista y la interfaz de usuario implementados para el módulo de **Consejos de Nutrición** (**US-9.1** y **US-9.2**), diseñado para ofrecer orientación alimentaria práctica y adaptada a la cocina guatemalteca sin depender de llamadas costosas a modelos de lenguaje externos.

---

## 1. Arquitectura Determinista y Cero Llamadas a IA (US-9.1)

Siguiendo la regla arquitectónica de utilizar algoritmos tradicionales y deterministas siempre que sea posible, el motor nutricional evalúa localmente el historial de cocina del usuario (`RecipeHistoryService`) cruzándolo con un catálogo nutricional estructurado.

### 1.1. Modelos de Dominio Nutricional
Definidos en [`ingredient_nutrition_profile.dart`](file:///c:/Users/luisr/food-friend/lib/features/nutrition/domain/ingredient_nutrition_profile.dart) y [`nutrition_tip.dart`](file:///c:/Users/luisr/food-friend/lib/features/nutrition/domain/nutrition_tip.dart):
- **`ProteinGroup`:** Clasifica la naturaleza proteica de cada ingrediente:
  - `none`: Sin aporte proteico principal.
  - `completeAnimal`: Proteína completa de origen animal (*Pollo*, *Pechuga de pollo*, *Posta de res*, *Filete de pescado*, *Huevos*, *Queso fresco*, etc.).
  - `incompleteLegume`: Proteína vegetal de leguminosas (*Frijoles negros*, *Frijoles rojos*, *Lentejas*, *Garbanzos*).
  - `incompleteGrainOrSeed`: Proteína vegetal de cereales, frutos secos o semillas (*Arroz blanco*, *Tortillas de maíz*, *Avena*, *Maní*, *Nueces*, *Almendras*).
- **`TrackedNutrient`:** Micronutrientes esenciales monitoreados en la dieta:
  - *Vitamina A* (`vitaminaA`)
  - *Vitamina C* (`vitaminaC`)
  - *Hierro* (`hierro`)
  - *Calcio* (`calcio`)
  - *Fibra* (`fibra`)
- **`IngredientNutritionProfile`:** Perfil asociado a cada ingrediente del catálogo que indica si es un embutido/carne procesada (`isProcessedMeat`), su grupo proteico (`proteinGroup`) y el conjunto de micronutrientes que aporta (`nutrients`).
- **`NutritionTip` y `NutritionReport`:** Entidades que encapsulan las recomendaciones activas, su categoría (`NutritionTipCategory`), severidad (`NutritionTipSeverity.warning` o `recommendation`), el consejo accionable en español y la lista de ingredientes sugeridos (`suggestedIngredients`) para agregar a la lista de compras.

---

## 2. Reglas de Evaluación Nutricional (`NutritionService`)

El servicio [`NutritionService`](file:///c:/Users/luisr/food-friend/lib/features/nutrition/data/nutrition_service.dart) inspecciona las recetas cocinadas dentro de una ventana temporal configurable (por defecto los últimos **14 días**) y ejecuta tres reglas deterministas:

### Regla 1: Alerta por Consumo Frecuente de Carnes Procesadas y Embutidos
- **Condición de Disparo:** Se activa cuando el usuario registra **2 o más preparaciones** con embutidos o carnes procesadas (*Chorizo*, *Longaniza*, *Salchicha*, *Tocino*, *Jamón*, *Salami*, *Mortadela*) o cuando estos representan $\ge 35\%$ de las comidas cocinadas recientes.
- **Resultado:** Genera una alerta preventiva (`NutritionTipSeverity.warning`) recomendando moderar el consumo de embutidos por su alto contenido de sodio y grasas saturadas, sugiriendo alternativas frescas como *Pechuga de pollo*, *Filete de pescado*, *Huevos* o *Frijoles negros*.

### Regla 2: Detección de Vitaminas y Minerales Faltantes
- **Condición de Disparo:** Analiza el conjunto acumulado de micronutrientes (`TrackedNutrient`) presentes en los ingredientes de todas las recetas cocinadas recientemente. Si alguno de los nutrientes monitoreados (*Vitamina A*, *Vitamina C*, *Hierro*, *Calcio* o *Fibra*) está ausente, se activa una recomendación específica.
- **Resultado:** Explica la importancia del nutriente faltante y sugiere ingredientes locales ricos en él (por ejemplo, *Zanahoria* y *Espinaca* para *Vitamina A*; *Limón*, *Tomate* y *Chile pimiento* para *Vitamina C*; *Frijoles negros* y *Lentejas* para *Hierro*), permitiendo agregarlos en un toque a la lista `Por comprar`.

### Regla 3: Combinación de Proteínas Vegetales para Proteína Completa
- **Condición de Disparo:** Detecta si en las comidas recientes predominan fuentes de proteína vegetal incompleta aisladas (solo leguminosas como *Frijoles negros*, o solo cereales como *Arroz blanco* / *Tortillas de maíz*) sin combinarse entre sí ni acompañarse de proteína animal completa.
- **Resultado:** Emite un consejo educativo explicando cómo combinar leguminosas con cereales en el mismo tiempo de comida (ej. la clásica combinación guatemalteca de **Arroz + Frijoles negros** o **Frijoles + Tortillas de maíz**) para obtener todos los aminoácidos esenciales de una proteína completa.

---

## 3. Interfaz de Usuario e Integración con Compras (US-9.2)

### 3.1. Pantalla `Consejos de Nutrición` (`NutritionTipsScreen`)
Implementada en [`nutrition_tips_screen.dart`](file:///c:/Users/luisr/food-friend/lib/features/nutrition/presentation/nutrition_tips_screen.dart):
- **Resumen Estadístico:** Muestra el número de comidas cocinadas evaluadas y el conteo de ingredientes únicos consumidos en el período reciente.
- **Tarjetas de Consejos Accionables:** Cada recomendación muestra un icono vectorial SVG (`warning`, `nutrition`, `check_circle`), título claro, explicación del hallazgo y el bloque *"Consejo práctico"*.
- **Integración en 1 Toque con `Lista de Compras`:** Los ingredientes recomendados por cada consejo pueden agregarse individualmente mediante chips interactivos (`+ Zanahoria`, `+ Espinaca`) o en bloque mediante el botón `"Agregar sugeridos a lista de compras"`, enviándolos directamente a [`ShoppingListStorageService`](file:///c:/Users/luisr/food-friend/lib/features/shopping_list/data/shopping_list_storage_service.dart).
- **Estados Vacíos y Dieta Equilibrada:**
  - Si el usuario aún no ha registrado comidas con `"Lo cociné"`, presenta una guía invitándolo a registrar sus platillos preparados.
  - Si el historial reciente cumple con todas las reglas sin alertas, muestra una tarjeta de felicitación confirmando el buen equilibrio nutricional.

### 3.2. Panel Dinámico en la Pantalla Principal (`HomeScreen`)
- La pantalla principal incluye el panel **`Consejos de Nutrición`**, cuyo subtítulo se actualiza dinámicamente al regresar de cualquier vista (`RouteAware`), indicando cuántos consejos activos tiene el usuario o confirmando que sus comidas recientes están equilibradas.
- Si el usuario prefiere una pantalla principal más minimalista, puede ocultar este panel desde `Configuración > Pantalla principal` manteniendo el acceso en todo momento desde el menú lateral (`AppNavigationDrawer`).
