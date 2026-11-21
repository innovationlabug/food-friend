import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_variation.dart';

/// Extended catalog of 28 healthy offline Guatemalan and Latin American recipes
/// ensuring full coverage across all categories, time tiers (<=20, 21-40, 41-60 min),
/// meal-prep variations, and all four health goals.
const List<Recipe> expandedLocalRecipes = <Recipe>[
  // =========================================================================
  // DESAYUNO (6 nuevas recetas: 2 <=20 min, 2 21-40 min, 2 41-60 min)
  // =========================================================================
  Recipe(
    id: 'avena_frutas_yogur',
    title: 'Avena Fresca con Yogur Griego, Fresa y Banano',
    description:
        'Tazón rápido de avena tibia con yogur griego proteico, frutas frescas, almendras y un toque de canela.',
    ingredients: [
      RecipeIngredient(name: 'Avena en hojuelas', displayAmount: '1 taza'),
      RecipeIngredient(name: 'Yogur griego', displayAmount: '1/2 taza'),
      RecipeIngredient(name: 'Fresa', displayAmount: '6 unidades'),
      RecipeIngredient(name: 'Banano', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Almendras', displayAmount: '2 cdas'),
      RecipeIngredient(name: 'Canela en polvo', displayAmount: '1/2 cdita'),
    ],
    instructions: [
      'Cocer la avena en una olla pequeña con una taza de agua y la canela durante 5 minutos hasta que espese.',
      'Servir en un tazón hondo y dejar entibiar un minuto.',
      'Incorporar el yogur griego por encima junto con el banano en rodajas y las fresas picadas.',
      'Terminar con las almendras picadas para sumar crocancia y saciedad.',
    ],
    prepTimeMinutes: 8,
    cookTimeMinutes: 7,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Desayuno',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'panqueques_avena_banano',
        title: 'En panqueques dorados al sartén',
        description:
            'Licúa la avena con banano y huevo para preparar panqueques saludables en sartén.',
        swappedIngredients: ['Huevo', 'Leche descremada'],
      ),
      RecipeVariation(
        recipeId: 'avena_horneada_manzana_canela',
        title: 'Versión horneada para varios días',
        description:
            'Cambia las fresas por manzana y hornea por porciones para toda la semana.',
        swappedIngredients: ['Manzana', 'Huevo'],
      ),
    ],
  ),
  Recipe(
    id: 'huevos_revueltos_ejote_tomate',
    title: 'Huevos Revueltos con Ejote, Tomate y Queso Fresco',
    description:
        'Desayuno chapín rápido rico en proteína y vegetales salteados, listo en menos de 20 minutos.',
    ingredients: [
      RecipeIngredient(name: 'Huevo', displayAmount: '4 unidades'),
      RecipeIngredient(name: 'Ejote', displayAmount: '1 taza picada'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/4 unidad'),
      RecipeIngredient(name: 'Queso fresco', displayAmount: '60 g'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
    ],
    instructions: [
      'Picar finamente la cebolla blanca, el tomate y los ejotes en trozos pequeños.',
      'Saltear los ejotes y la cebolla en sartén con el aceite de oliva durante 4 minutos hasta suavizar.',
      'Agregar el tomate picado, cocinar 2 minutos e incorporar los huevos batidos.',
      'Revolver suavemente a fuego medio hasta cuajar al gusto y servir con el queso fresco desmoronado y una pizca de sal al gusto.',
    ],
    prepTimeMinutes: 7,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Desayuno',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'omelet_espinaca_queso',
        title: 'Versión en omelet con espinaca',
        description:
            'Sustituye los ejotes por espinaca fresca y dobla los huevos en forma de omelet.',
        swappedIngredients: ['Espinaca', 'Queso de capas'],
      ),
      RecipeVariation(
        recipeId: 'huevos_rancheros_frijoles',
        title: 'Versión ranchera con frijoles negros',
        description:
            'Acompaña los huevos en salsa de tomate con frijoles negros y aguacate.',
        swappedIngredients: ['Frijoles negros', 'Aguacate'],
      ),
    ],
  ),
  Recipe(
    id: 'huevos_rancheros_frijoles',
    title: 'Huevos Rancheros con Salsa de Tomate y Frijoles Negros',
    description:
        'Huevos estrellados bañados en chirmol casero cocido con chile pimiento, servidos con frijoles negros y aguacate.',
    ingredients: [
      RecipeIngredient(name: 'Huevo', displayAmount: '4 unidades'),
      RecipeIngredient(name: 'Frijoles negros', displayAmount: '1 taza cocida'),
      RecipeIngredient(name: 'Tomate', displayAmount: '4 unidades'),
      RecipeIngredient(name: 'Chile pimiento', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '1 diente'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Aguacate', displayAmount: '1/2 unidad'),
    ],
    instructions: [
      'Asar o cocer los tomates, el chile pimiento, la cebolla y el ajo; licuar con cilantro para obtener una salsa espesa sin sodio añadido.',
      'Cocinar la salsa en una sartén por 8 minutos hasta concentrar su sabor y sazonar con sal al gusto.',
      'Hacer pequeños huecos en la salsa, cascar los huevos encima, tapar y cocer 5 minutos hasta que las claras cuajen.',
      'Servir acompañados de frijoles negros tibios y rebanadas de aguacate fresco.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 18,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Desayuno',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'desayuno_chapin_saludable',
        title: 'Versión clásica sin salsa picante',
        description:
            'Prepara los huevos revueltos aparte con queso fresco y tortillas de maíz.',
        swappedIngredients: ['Queso fresco', 'Tortilla de maíz'],
      ),
      RecipeVariation(
        recipeId: 'huevos_revueltos_ejote_tomate',
        title: 'Versión express en 17 minutos',
        description:
            'Saltea tomate y ejote directamente en la sartén para ahorrar tiempo de licuado.',
        swappedIngredients: ['Ejote', 'Queso fresco'],
      ),
      RecipeVariation(
        recipeId: 'huevos_cazuela_espinaca',
        title: 'En cazuela horneada con camote',
        description:
            'Agrega cubos de camote y espinaca y hornea todo junto en una sola fuente.',
        swappedIngredients: ['Camote', 'Espinaca'],
      ),
    ],
  ),
  Recipe(
    id: 'panqueques_avena_banano',
    title: 'Panqueques Saludables de Avena, Banano y Huevo',
    description:
        'Panqueques esponjosos sin harinas refinadas ni azúcares añadidos, servidos con fresa y yogur natural.',
    ingredients: [
      RecipeIngredient(name: 'Avena en hojuelas', displayAmount: '1 taza'),
      RecipeIngredient(name: 'Banano', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Leche descremada', displayAmount: '1/2 taza'),
      RecipeIngredient(name: 'Canela en polvo', displayAmount: '1 cdita'),
      RecipeIngredient(name: 'Fresa', displayAmount: '6 unidades'),
      RecipeIngredient(name: 'Yogur natural', displayAmount: '1/2 taza'),
    ],
    instructions: [
      'Licuar la avena en hojuelas, los bananos maduros, los huevos, la leche descremada y la canela hasta obtener una mezcla homogénea.',
      'Dejar reposar la mezcla 5 minutos para que la avena hidrate y espese ligeramente.',
      'Calentar un comal o sartén antiadherente a fuego medio y verter porciones pequeñas de mezcla.',
      'Cocinar 2 minutos por lado hasta dorar y servir con yogur natural y fresas rebanadas.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 15,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Desayuno',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'avena_frutas_yogur',
        title: 'Versión rápida en tazón (sin sartén)',
        description:
            'Cuece la avena directamente con agua y sírvela con yogur griego y almendras.',
        swappedIngredients: ['Yogur griego', 'Almendras'],
      ),
      RecipeVariation(
        recipeId: 'avena_horneada_manzana_canela',
        title: 'Versión horneada con manzana',
        description:
            'Reemplaza el banano por manzana picada y hornea para obtener porciones listas de desayuno.',
        swappedIngredients: ['Manzana', 'Almendras'],
      ),
    ],
  ),
  Recipe(
    id: 'avena_horneada_manzana_canela',
    title: 'Avena Horneada con Manzana, Canela y Almendras',
    description:
        'Desayuno horneado ideal para preparar varias porciones nutritivas ricas en fibra y proteína.',
    ingredients: [
      RecipeIngredient(name: 'Avena en hojuelas', displayAmount: '2 tazas'),
      RecipeIngredient(name: 'Manzana', displayAmount: '2 unidades picadas'),
      RecipeIngredient(name: 'Leche descremada', displayAmount: '1 1/2 tazas'),
      RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Almendras', displayAmount: '1/3 taza'),
      RecipeIngredient(name: 'Canela en polvo', displayAmount: '1 cdita'),
      RecipeIngredient(name: 'Yogur griego', displayAmount: '1/2 taza'),
    ],
    instructions: [
      'Precalentar el horno a 180 grados centígrados y alistar un molde mediano.',
      'Batir los huevos con la leche descremada y la canela en polvo en un tazón.',
      'Agregar la avena en hojuelas y los cubos de manzana, mezclar bien y verter en el molde.',
      'Distribuir las almendras por encima y hornear durante 35 minutos hasta dorar; servir tibio con yogur griego.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 35,
    servings: 4,
    difficulty: 'Media',
    category: 'Desayuno',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'avena_frutas_yogur',
        title: 'Tazón rápido de 15 minutos',
        description:
            'Prepara la avena en olla sin usar horno y añade banano y fresa.',
        swappedIngredients: ['Banano', 'Fresa'],
      ),
      RecipeVariation(
        recipeId: 'panqueques_avena_banano',
        title: 'Panqueques de avena y banano',
        description:
            'Cambia la manzana por banano y cocina porciones individuales al comal.',
        swappedIngredients: ['Banano', 'Yogur natural'],
      ),
    ],
  ),
  Recipe(
    id: 'huevos_cazuela_espinaca',
    title: 'Cazuela de Huevos al Horno con Espinaca, Camote y Frijoles',
    description:
        'Desayuno completo al horno que combina carbohidratos complejos, hierro vegetal y proteína de huevo.',
    ingredients: [
      RecipeIngredient(name: 'Huevo', displayAmount: '4 unidades'),
      RecipeIngredient(name: 'Camote', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Espinaca', displayAmount: '2 tazas'),
      RecipeIngredient(name: 'Frijoles negros', displayAmount: '1 taza cocida'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Queso fresco', displayAmount: '60 g'),
      RecipeIngredient(name: 'Orégano seco', displayAmount: '1/2 cdita'),
    ],
    instructions: [
      'Precalentar el horno a 190 grados centígrados y colocar en una fuente el camote en cubos pequeños con la cebolla morada y el orégano.',
      'Hornear el camote durante 20 minutos hasta que esté tierno.',
      'Incorporar el tomate picado, los frijoles negros y la espinaca mezclando suavemente.',
      'Abrir cuatro espacios para cascar los huevos, espolvorear queso fresco y sal al gusto, y hornear 12 a 15 minutos hasta cuajar.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 35,
    servings: 4,
    difficulty: 'Media',
    category: 'Desayuno',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'huevos_rancheros_frijoles',
        title: 'Versión ranchera al sartén',
        description:
            'Omite el camote y cocina los huevos en salsa de tomate con frijoles en menos de 30 minutos.',
        swappedIngredients: ['Chile pimiento', 'Aguacate'],
      ),
      RecipeVariation(
        recipeId: 'desayuno_chapin_saludable',
        title: 'Desayuno chapín tradicional',
        description:
            'Sirve los huevos revueltos en el comal junto a plátano asado y tortillas.',
        swappedIngredients: ['Plátano', 'Tortilla de maíz'],
      ),
      RecipeVariation(
        recipeId: 'omelet_espinaca_queso',
        title: 'Omelet rápido de espinaca',
        description:
            'Prepara solo los huevos con espinaca y queso al sartén para un desayuno express.',
        swappedIngredients: ['Queso de capas'],
      ),
    ],
  ),

  // =========================================================================
  // ALMUERZO (5 nuevas recetas: 3 <=20 min, 1 21-40 min, 1 41-60 min)
  // =========================================================================
  Recipe(
    id: 'salteado_pollo_arveja_china',
    title: 'Salteado Rápido de Pollo con Arveja China y Chile Pimiento',
    description:
        'Tiras de pechuga salteadas a fuego alto con vegetales crujientes, jengibre fresco y ajonjolí tostado.',
    ingredients: [
      RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '400 g en tiras'),
      RecipeIngredient(name: 'Arveja china', displayAmount: '150 g'),
      RecipeIngredient(name: 'Chile pimiento', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Jengibre', displayAmount: '1 cdita rallado'),
      RecipeIngredient(name: 'Ajonjolí', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Aceite vegetal', displayAmount: '1 cda'),
    ],
    instructions: [
      'Cortar la pechuga de pollo en tiras delgadas para que se cocinen en pocos minutos.',
      'Calentar el aceite vegetal en sartén amplio o wok y dorar el pollo con el ajo y el jengibre durante 5 minutos.',
      'Añadir la arveja china, el chile pimiento y la cebolla morada en tiras, y saltear 4 minutos manteniendo los vegetales crujientes.',
      'Ajustar con una pizca de sal al gusto y espolvorear el ajonjolí justo antes de servir.',
    ],
    prepTimeMinutes: 8,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Almuerzo',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'camarones_ajillo_brocoli',
        title: 'Con camarones y brócoli al limón',
        description:
            'Cambia el pollo y la arveja china por camarones con brócoli para variar la proteína.',
        swappedIngredients: ['Camarones', 'Brócoli', 'Limón'],
      ),
      RecipeVariation(
        recipeId: 'pollo_plancha_vegetales',
        title: 'Pechuga a la plancha tradicional',
        description:
            'Asa la pechuga entera con orégano y sírvela con brócoli y zanahoria al vapor.',
        swappedIngredients: ['Brócoli', 'Zanahoria', 'Orégano seco'],
      ),
    ],
  ),
  Recipe(
    id: 'tilapia_plancha_tomate_limon',
    title: 'Filete de Tilapia a la Plancha con Tomate y Limón',
    description:
        'Almuerzo ligero y alto en proteína con filete de tilapia dorado al limón acompañado de güicoy y tomate.',
    ingredients: [
      RecipeIngredient(name: 'Filete de tilapia', displayAmount: '2 filetes'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Limón', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Güicoy', displayAmount: '1 unidad en medias lunas'),
    ],
    instructions: [
      'Sazonar los filetes de tilapia con jugo de limón, ajo picado y sal al gusto.',
      'Calentar el aceite de oliva en una plancha o sartén y dorar el güicoy en medias lunas durante 4 minutos por lado.',
      'Cocinar los filetes de tilapia en la misma plancha durante 3 minutos por lado hasta que estén opacos.',
      'Servir cubriendo con tomate picado, cebolla morada y cilantro fresco.',
    ],
    prepTimeMinutes: 8,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Almuerzo',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'pescado_limon_cilantro',
        title: 'Versión horneada al aluminio con perulero',
        description:
            'Envuelve el filete con zanahoria y perulero en aluminio para cocinarlo al vapor.',
        swappedIngredients: ['Perulero', 'Zanahoria'],
      ),
      RecipeVariation(
        recipeId: 'salmon_horno_camote_brocoli',
        title: 'Salmón al horno con camote y brócoli',
        description:
            'Sustituye la tilapia por salmón rico en omega-3 y acompaña con camote asado.',
        swappedIngredients: ['Salmón', 'Camote', 'Brócoli'],
      ),
      RecipeVariation(
        recipeId: 'camarones_ajillo_brocoli',
        title: 'Camarones al ajillo con brócoli',
        description:
            'Usa camarones en lugar de tilapia y acompáñalos con floretes de brócoli salteados.',
        swappedIngredients: ['Camarones', 'Brócoli'],
      ),
    ],
  ),
  Recipe(
    id: 'camarones_ajillo_brocoli',
    title: 'Camarones al Ajillo con Brócoli y Limón',
    description:
        'Almuerzo proteico de cocción rápida con camarones frescos, brócoli crujiente, ajo y perejil.',
    ingredients: [
      RecipeIngredient(name: 'Camarones', displayAmount: '350 g limpios'),
      RecipeIngredient(name: 'Brócoli', displayAmount: '2 tazas de floretes'),
      RecipeIngredient(name: 'Ajo', displayAmount: '3 dientes'),
      RecipeIngredient(name: 'Limón', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Perejil', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Chile pimiento', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
    ],
    instructions: [
      'Saltear los floretes de brócoli y el chile pimiento en el aceite de oliva con dos cucharadas de agua durante 4 minutos.',
      'Incorporar el ajo finamente picado y los camarones limpios.',
      'Saltear 3 a 4 minutos hasta que los camarones tomen tono rosado parejo.',
      'Retirar del fuego, bañar con jugo de limón fresco, perejil picado y sal al gusto.',
    ],
    prepTimeMinutes: 8,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Almuerzo',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'tilapia_plancha_tomate_limon',
        title: 'Con filete de tilapia a la plancha',
        description:
            'Reemplaza los camarones por filete de tilapia y acompaña con güicoy y tomate.',
        swappedIngredients: ['Filete de tilapia', 'Güicoy', 'Tomate'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_camarones_mango_aguacate',
        title: 'Versión fría en ensalada con mango',
        description:
            'Enfría los camarones cocidos y mézclalos con mango, aguacate y lechuga.',
        swappedIngredients: ['Mango', 'Aguacate', 'Lechuga'],
      ),
      RecipeVariation(
        recipeId: 'salteado_pollo_arveja_china',
        title: 'Salteado con pechuga y arveja china',
        description:
            'Sustituye los camarones por tiras de pechuga de pollo y arveja china.',
        swappedIngredients: ['Pechuga de pollo', 'Arveja china'],
      ),
    ],
  ),
  Recipe(
    id: 'arroz_integral_garbanzos_espinaca',
    title: 'Tazón de Arroz Integral con Garbanzos y Espinaca',
    description:
        'Almuerzo completo de proteína vegetal al combinar cereal integral con legumbres, cúrcuma y verduras.',
    ingredients: [
      RecipeIngredient(name: 'Arroz integral', displayAmount: '1 taza'),
      RecipeIngredient(name: 'Garbanzos', displayAmount: '1 1/2 tazas cocidas'),
      RecipeIngredient(name: 'Espinaca', displayAmount: '2 tazas'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '1 unidad rallada'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Cúrcuma', displayAmount: '1/2 cdita'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
    ],
    instructions: [
      'Enjuagar el arroz integral y cocerlo en 2 tazas y media de agua con la cúrcuma y un diente de ajo durante 22 minutos.',
      'En una sartén amplia sofreír la cebolla blanca y el segundo diente de ajo hasta acitronar.',
      'Agregar los garbanzos cocidos y la zanahoria rallada, cocinando 5 minutos a fuego medio.',
      'Añadir la espinaca al final hasta que se marchite, mezclar con el arroz integral y finalizar con limón y sal al gusto.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 25,
    servings: 3,
    difficulty: 'Fácil',
    category: 'Almuerzo',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'arroz_vegetales_pollo',
        title: 'Con arroz blanco y pechuga en cubos',
        description:
            'Cambia los garbanzos por pechuga de pollo y acompaña con güisquil y chile pimiento.',
        swappedIngredients: ['Arroz blanco', 'Pechuga de pollo', 'Güisquil'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_tibia_garbanzos_pollo',
        title: 'Ensalada tibia de garbanzos y pollo',
        description:
            'Omite el arroz y agrega pechuga de pollo asada junto a floretes de brócoli.',
        swappedIngredients: ['Pechuga de pollo', 'Brócoli'],
      ),
      RecipeVariation(
        recipeId: 'sopa_ayote_garbanzos',
        title: 'Crema de ayote con garbanzos',
        description:
            'Aprovecha los garbanzos cocidos como guarnición crujiente sobre crema natural de ayote.',
        swappedIngredients: ['Ayote', 'Semillas de girasol'],
      ),
    ],
  ),
  Recipe(
    id: 'lomo_cerdo_achiote_camote',
    title: 'Lomo de Cerdo al Achiote con Camote y Ejotes',
    description:
        'Almuerzo horneado en adobo natural de achiote y naranja agria o dulce, acompañado de camote y ejotes.',
    ingredients: [
      RecipeIngredient(name: 'Lomo de cerdo', displayAmount: '450 g'),
      RecipeIngredient(name: 'Achiote en pasta', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Naranja', displayAmount: '2 unidades en jugo'),
      RecipeIngredient(name: 'Camote', displayAmount: '2 unidades en cubos'),
      RecipeIngredient(name: 'Ejote', displayAmount: '1 1/2 tazas'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Orégano seco', displayAmount: '1 cdita'),
    ],
    instructions: [
      'Disolver el achiote en pasta en el jugo de naranja junto con el ajo machacado, orégano y sal al gusto.',
      'Marinar el lomo de cerdo en esa mezcla dentro de una fuente para horno junto con el camote y la cebolla morada.',
      'Hornear tapado a 190 grados centígrados durante 25 minutos.',
      'Destapar, incorporar los ejotes a la charola y hornear 15 minutos más hasta cocer bien el lomo y caramelizar el camote.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 40,
    servings: 4,
    difficulty: 'Media',
    category: 'Almuerzo',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'lomo_res_horno_coliflor',
        title: 'Con lomo de res y coliflor al tomillo',
        description:
            'Sustituye el lomo de cerdo por lomo de res y hornea con coliflor y zanahoria.',
        swappedIngredients: ['Lomo de res', 'Coliflor', 'Tomillo'],
      ),
      RecipeVariation(
        recipeId: 'guiso_pollo_perulero',
        title: 'En guiso de pollo con perulero',
        description:
            'Cambia el horneado por una cocción en olla con pechuga de pollo, tomate y perulero.',
        swappedIngredients: ['Pechuga de pollo', 'Perulero', 'Tomate'],
      ),
    ],
  ),

  // =========================================================================
  // CENA (6 nuevas recetas: 3 <=20 min, 1 21-40 min, 2 41-60 min)
  // =========================================================================
  Recipe(
    id: 'revuelto_acelga_huevo_queso',
    title: 'Salteado Ligero de Acelga, Champiñones y Huevo',
    description:
        'Cena ligera baja en calorías rica en hierro, fibra vegetal y proteína completa.',
    ingredients: [
      RecipeIngredient(name: 'Acelga', displayAmount: '1 manojo picado'),
      RecipeIngredient(name: 'Champiñones', displayAmount: '1 taza laminados'),
      RecipeIngredient(name: 'Huevo', displayAmount: '3 unidades'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/4 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '1 diente'),
      RecipeIngredient(name: 'Queso fresco', displayAmount: '50 g'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
    ],
    instructions: [
      'Lavar y picar las hojas y tallos tiernos de acelga en tiras delgadas.',
      'Saltear la cebolla blanca, el ajo y los champiñones en el aceite de oliva durante 4 minutos.',
      'Añadir la acelga y cocinar 2 minutos hasta que reduzca su volumen.',
      'Incorporar los huevos batidos, revolver suavemente hasta cuajar y servir con queso fresco y sal al gusto.',
    ],
    prepTimeMinutes: 8,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Cena',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'omelet_espinaca_queso',
        title: 'Omelet de espinaca y queso de capas',
        description:
            'Cambia la acelga por espinaca y prepara una tortilla doblada sin champiñones.',
        swappedIngredients: ['Espinaca', 'Queso de capas'],
      ),
      RecipeVariation(
        recipeId: 'tortilla_guicoy_huevo_espinaca',
        title: 'Tortilla española de güicoy y espinaca',
        description:
            'Sustituye la acelga por rodajas finas de güicoy y cuaja a fuego lento.',
        swappedIngredients: ['Güicoy', 'Espinaca'],
      ),
    ],
  ),
  Recipe(
    id: 'tacos_lechuga_pollo_aguacate',
    title: 'Rollitos de Lechuga con Pollo Desmenuzado y Aguacate',
    description:
        'Cena fresca sin harinas ni cocción prolongada, ideal para aprovechar pollo desmenuzado.',
    ingredients: [
      RecipeIngredient(name: 'Pollo desmenuzado', displayAmount: '250 g'),
      RecipeIngredient(name: 'Lechuga', displayAmount: '6 hojas grandes'),
      RecipeIngredient(name: 'Aguacate', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/4 unidad'),
    ],
    instructions: [
      'Picar en cubos pequeños el tomate, el aguacate, la cebolla morada y el cilantro.',
      'Entibiar ligeramente el pollo desmenuzado en una sartén seca o con dos cucharadas de agua durante 4 minutos.',
      'Mezclar el pollo con los vegetales picados, el jugo de limón y una pizca de sal al gusto.',
      'Rellenar cada hoja limpia de lechuga con la preparación y servir como rollitos frescos.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 5,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Cena',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ensalada_pollo_aguacate_pepino',
        title: 'En plato hondo con berro y pepino',
        description:
            'Pica la lechuga o cámbiala por berro y pepino para servirlo como ensalada completa.',
        swappedIngredients: ['Berro', 'Pepino', 'Rábano'],
      ),
      RecipeVariation(
        recipeId: 'salteado_atun_guicoy',
        title: 'Versión caliente con atún y güicoy',
        description:
            'Sustituye el pollo y la lechuga por atún salteado rápidamente con güicoy.',
        swappedIngredients: ['Atún en lata', 'Güicoy', 'Chile pimiento'],
      ),
    ],
  ),
  Recipe(
    id: 'salteado_atun_guicoy',
    title: 'Salteado Express de Atún con Güicoy y Chile Pimiento',
    description:
        'Cena práctica de despensa lista en 18 minutos combinando proteína marina magra y vegetales tiernos.',
    ingredients: [
      RecipeIngredient(name: 'Atún en lata', displayAmount: '2 latas escurridas'),
      RecipeIngredient(name: 'Güicoy', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Chile pimiento', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/4 unidad'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Orégano seco', displayAmount: '1/2 cdita'),
    ],
    instructions: [
      'Calentar una sartén antiadherente a fuego medio y saltear la cebolla blanca con el chile pimiento por 3 minutos.',
      'Añadir el güicoy en cubos pequeños y el tomate picado con dos cucharadas de agua y el orégano seco.',
      'Tapar y cocinar 5 minutos hasta que el güicoy esté tierno.',
      'Incorporar el atún escurrido, calentar 2 minutos más y servir con jugo de limón y sal al gusto.',
    ],
    prepTimeMinutes: 8,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Cena',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ensalada_atun_pepino_garbanzos',
        title: 'Versión fría con garbanzos y pepino',
        description:
            'Sirve el atún sin cocción mezclado con pepino fresco y garbanzos cocidos.',
        swappedIngredients: ['Garbanzos', 'Pepino', 'Aceite de oliva'],
      ),
      RecipeVariation(
        recipeId: 'tacos_lechuga_pollo_aguacate',
        title: 'Rollitos fríos de pollo y aguacate',
        description:
            'Cambia el atún y el güicoy por pollo desmenuzado envuelto en hojas de lechuga.',
        swappedIngredients: ['Pollo desmenuzado', 'Lechuga', 'Aguacate'],
      ),
    ],
  ),
  Recipe(
    id: 'tortilla_guicoy_huevo_espinaca',
    title: 'Tortilla Española Ligera de Güicoy, Espinaca y Huevo',
    description:
        'Cena horneada o al sartén estilo tortilla gruesa con láminas de güicoy tierno y hojas verdes.',
    ingredients: [
      RecipeIngredient(name: 'Güicoy', displayAmount: '2 unidades en láminas'),
      RecipeIngredient(name: 'Espinaca', displayAmount: '2 tazas'),
      RecipeIngredient(name: 'Huevo', displayAmount: '5 unidades'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '1 diente'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Perejil', displayAmount: '2 cdas picado'),
    ],
    instructions: [
      'Rebanar los güicoyes en láminas delgadas junto con la cebolla blanca.',
      'Cocinar el güicoy, la cebolla y el ajo tapados en el aceite de oliva a fuego medio-bajo por 10 minutos hasta suavizar.',
      'Agregar la espinaca y cocinar 2 minutos; pasar todo a un tazón con los huevos batidos, el perejil y sal al gusto.',
      'Regresar la mezcla al sartén, cuajar 4 minutos por lado con tapa hasta dorar y cortar en triángulos.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    servings: 3,
    difficulty: 'Fácil',
    category: 'Cena',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'revuelto_acelga_huevo_queso',
        title: 'Versión rápida en 18 minutos con acelga',
        description:
            'Cambia el güicoy por acelga y champiñones en un revuelto rápido sin voltear tortilla.',
        swappedIngredients: ['Acelga', 'Champiñones', 'Queso fresco'],
      ),
      RecipeVariation(
        recipeId: 'omelet_espinaca_queso',
        title: 'Omelet individual de espinaca',
        description:
            'Omite el güicoy para obtener una porción más rápida rellena de queso de capas.',
        swappedIngredients: ['Queso de capas'],
      ),
    ],
  ),
  Recipe(
    id: 'salmon_horno_camote_brocoli',
    title: 'Salmón al Horno con Camote, Brócoli y Romero',
    description:
        'Cena completa en una sola bandeja con grasas saludables omega-3, vitamina C y carbohidrato complejo.',
    ingredients: [
      RecipeIngredient(name: 'Salmón', displayAmount: '2 filetes'),
      RecipeIngredient(name: 'Camote', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Brócoli', displayAmount: '2 tazas de floretes'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Romero', displayAmount: '1 cdita'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
    ],
    instructions: [
      'Precalentar el horno a 200 grados centígrados y mezclar los cubos de camote con la mitad del aceite de oliva, romero y sal al gusto.',
      'Hornear el camote durante 15 minutos en una bandeja para que inicie su cocción.',
      'Hacer espacio en la bandeja, añadir el brócoli y los filetes de salmón pincelados con el aceite restante, ajo picado y jugo de limón.',
      'Hornear 12 a 15 minutos adicionales hasta que el salmón se desmenuce fácil con tenedor.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 30,
    servings: 2,
    difficulty: 'Media',
    category: 'Cena',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'tilapia_plancha_tomate_limon',
        title: 'Con filete de tilapia a la plancha (18 min)',
        description:
            'Cambia el salmón por filete de tilapia y cocínalo en sartén junto con güicoy.',
        swappedIngredients: ['Filete de tilapia', 'Güicoy', 'Tomate'],
      ),
      RecipeVariation(
        recipeId: 'pescado_limon_cilantro',
        title: 'Filete empapelado con perulero',
        description:
            'Sustituye el salmón por pescado blanco con perulero y zanahoria en papel aluminio.',
        swappedIngredients: ['Filete de robalo', 'Perulero', 'Zanahoria'],
      ),
    ],
  ),
  Recipe(
    id: 'lomo_res_horno_coliflor',
    title: 'Lomo de Res Asado con Coliflor y Zanahoria al Tomillo',
    description:
        'Cena magra de preparación al horno con vegetales rostizados y especias aromáticas sin sodio extra.',
    ingredients: [
      RecipeIngredient(name: 'Lomo de res', displayAmount: '450 g'),
      RecipeIngredient(name: 'Coliflor', displayAmount: '3 tazas de floretes'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '2 unidades en bastones'),
      RecipeIngredient(name: 'Ajo', displayAmount: '3 dientes'),
      RecipeIngredient(name: 'Tomillo', displayAmount: '1 cdita'),
      RecipeIngredient(name: 'Páprika', displayAmount: '1 cdita'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
    ],
    instructions: [
      'Precalentar el horno a 195 grados centígrados y untar el lomo de res con ajo picado, páprika, tomillo, aceite de oliva y sal al gusto.',
      'Colocar los bastones de zanahoria y floretes de coliflor alrededor del lomo en una fuente amplia.',
      'Hornear durante 35 a 40 minutos hasta que las verduras doren en los bordes y el lomo alcance el término deseado.',
      'Dejar reposar la carne 5 minutos antes de rebanar y rociar unas gotas de limón al servir.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 40,
    servings: 4,
    difficulty: 'Media',
    category: 'Cena',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'lomo_cerdo_achiote_camote',
        title: 'Con lomo de cerdo al achiote',
        description:
            'Sustituye el lomo de res por lomo de cerdo adobado en achiote con naranja y camote.',
        swappedIngredients: ['Lomo de cerdo', 'Achiote en pasta', 'Camote'],
      ),
      RecipeVariation(
        recipeId: 'pollo_plancha_vegetales',
        title: 'Versión rápida con pechuga a la plancha',
        description:
            'Cambia la cocción al horno por pechuga a la plancha con brócoli al vapor en 25 minutos.',
        swappedIngredients: ['Pechuga de pollo', 'Brócoli'],
      ),
    ],
  ),

  // =========================================================================
  // SOPAS Y CALDOS (5 nuevas recetas: 2 <=20 min, 2 21-40 min, 1 41-60 min)
  // =========================================================================
  Recipe(
    id: 'caldo_rapido_espinaca_huevo',
    title: 'Caldo Rápido de Espinaca, Tomate y Huevo Escalfado',
    description:
        'Sopa reconfortante de hierro y proteína lista en 17 minutos para días frescos o cenas livianas.',
    ingredients: [
      RecipeIngredient(name: 'Huevo', displayAmount: '4 unidades'),
      RecipeIngredient(name: 'Espinaca', displayAmount: '3 tazas'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
    ],
    instructions: [
      'Picar finamente el tomate, la cebolla blanca y el ajo y sofreírlos en una olla con un chorrito de agua por 3 minutos.',
      'Agregar cuatro tazas de agua caliente y llevar a hervor suave durante 5 minutos con cilantro.',
      'Incorporar las hojas de espinaca y cascar con cuidado los huevos directamente en el caldo hirviendo a fuego bajo.',
      'Tapar y cocinar 4 minutos hasta que las claras estén firmes; servir con sal al gusto y unas gotas de limón.',
    ],
    prepTimeMinutes: 5,
    cookTimeMinutes: 12,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Sopas y Caldos',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'sopa_rapida_pollo_fideos',
        title: 'Con pollo desmenuzado y fideos',
        description:
            'Cambia el huevo y la espinaca por pollo desmenuzado, fideos y apio.',
        swappedIngredients: ['Pollo desmenuzado', 'Fideos', 'Apio'],
      ),
      RecipeVariation(
        recipeId: 'sopa_lentejas_espinaca',
        title: 'Sopa de lentejas y espinaca',
        description:
            'Sustituye el huevo por lentejas y zanahoria para una sopa más espesa.',
        swappedIngredients: ['Lentejas', 'Zanahoria'],
      ),
    ],
  ),
  Recipe(
    id: 'sopa_rapida_pollo_fideos',
    title: 'Sopa Express de Pollo Desmenuzado, Fideos y Apio',
    description:
        'Caldo ligero con sabor tradicional a hierbabuena listo en 20 minutos usando pollo ya cocido.',
    ingredients: [
      RecipeIngredient(name: 'Pollo desmenuzado', displayAmount: '250 g'),
      RecipeIngredient(name: 'Fideos', displayAmount: '80 g'),
      RecipeIngredient(name: 'Apio', displayAmount: '2 tallos picados'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '1 unidad en cubitos'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/4 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '1 diente'),
      RecipeIngredient(name: 'Hierbabuena', displayAmount: '3 ramitas'),
    ],
    instructions: [
      'Llevar a hervor cuatro tazas de agua con la cebolla blanca, el ajo, el apio y la zanahoria picada en cubos pequeños.',
      'Cocinar tapado durante 7 minutos para ablandar los vegetales.',
      'Agregar los fideos delgados, el pollo desmenuzado y las ramitas de hierbabuena.',
      'Hervir 6 minutos más hasta que los fideos estén al dente y ajustar con sal al gusto.',
    ],
    prepTimeMinutes: 6,
    cookTimeMinutes: 14,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Sopas y Caldos',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'caldo_pollo_verduras',
        title: 'Caldo tradicional con güisquil y papa',
        description:
            'Prepara el caldo desde cero con pechuga en trozos y verduras enteras en 55 minutos.',
        swappedIngredients: ['Pechuga de pollo', 'Güisquil', 'Papa'],
      ),
      RecipeVariation(
        recipeId: 'caldo_rapido_espinaca_huevo',
        title: 'Versión ligera de espinaca y huevo',
        description:
            'Reemplaza el pollo y los fideos por huevo escalfado y espinaca fresca.',
        swappedIngredients: ['Huevo', 'Espinaca'],
      ),
    ],
  ),
  Recipe(
    id: 'sopa_ayote_garbanzos',
    title: 'Crema Natural de Ayote y Zanahoria con Garbanzos',
    description:
        'Sopa cremosa naturalmente dulce sin cremas lácteas, coronada con garbanzos y semillas de girasol.',
    ingredients: [
      RecipeIngredient(name: 'Ayote', displayAmount: '450 g en cubos'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Garbanzos', displayAmount: '1 taza cocida'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Jengibre', displayAmount: '1 cdita rallado'),
      RecipeIngredient(name: 'Semillas de girasol', displayAmount: '2 cdas'),
    ],
    instructions: [
      'Colocar en una olla el ayote en cubos, la zanahoria, la cebolla blanca, el ajo y el jengibre con tres tazas de agua.',
      'Cocinar a fuego medio durante 18 minutos hasta que el ayote y la zanahoria estén muy suaves.',
      'Licuar con el mismo caldo de cocción hasta lograr una textura aterciopelada y regresar al fuego con sal al gusto.',
      'Servir bien caliente agregando los garbanzos tibios y las semillas de girasol por encima.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 25,
    servings: 3,
    difficulty: 'Fácil',
    category: 'Sopas y Caldos',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'sopa_lentejas_espinaca',
        title: 'Sopa rústica de lentejas y espinaca',
        description:
            'Sustituye el ayote por lentejas y espinaca para un caldo sin licuar.',
        swappedIngredients: ['Lentejas', 'Espinaca'],
      ),
      RecipeVariation(
        recipeId: 'caldo_frijoles_colorados_verduras',
        title: 'Sopa casera de frijoles colorados',
        description:
            'Cambia el ayote por frijoles colorados con güicoy y repollo.',
        swappedIngredients: ['Frijoles colorados', 'Güicoy', 'Repollo blanco'],
      ),
      RecipeVariation(
        recipeId: 'arroz_integral_garbanzos_espinaca',
        title: 'Tazón seco de arroz integral y garbanzos',
        description:
            'Usa los garbanzos en un plato sólido con arroz integral y espinaca.',
        swappedIngredients: ['Arroz integral', 'Espinaca'],
      ),
    ],
  ),
  Recipe(
    id: 'caldo_pescado_verduras',
    title: 'Caldo Ligero de Pescado con Perulero y Apio',
    description:
        'Sopa aromática alta en proteína magra con filete de robalo, perulero tierno y toque cítrico de limón.',
    ingredients: [
      RecipeIngredient(name: 'Filete de robalo', displayAmount: '350 g en trozos'),
      RecipeIngredient(name: 'Perulero', displayAmount: '2 unidades en cubos'),
      RecipeIngredient(name: 'Apio', displayAmount: '2 tallos'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
    ],
    instructions: [
      'Picar el tomate, la cebolla, el ajo y el apio y hervirlos en cuatro tazas de agua durante 8 minutos.',
      'Agregar los cubos de perulero y cocinar 10 minutos más hasta que comiencen a ablandar.',
      'Añadir los trozos de filete de robalo con sal al gusto y cocer suavemente 5 a 6 minutos sin revolver de más.',
      'Retirar del fuego y finalizar con cilantro fresco picado y jugo de limón.',
    ],
    prepTimeMinutes: 10,
    cookTimeMinutes: 25,
    servings: 3,
    difficulty: 'Fácil',
    category: 'Sopas y Caldos',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'pescado_limon_cilantro',
        title: 'Pescado empapelado sin caldo',
        description:
            'Cocina los mismos ingredientes envueltos en aluminio sin añadir agua.',
        swappedIngredients: ['Zanahoria'],
      ),
      RecipeVariation(
        recipeId: 'caldo_pollo_verduras',
        title: 'Caldo tradicional de pollo y güisquil',
        description:
            'Cambia el pescado y perulero por pollo, güisquil, papa y hierbabuena.',
        swappedIngredients: ['Pechuga de pollo', 'Güisquil', 'Hierbabuena'],
      ),
      RecipeVariation(
        recipeId: 'tilapia_plancha_tomate_limon',
        title: 'Tilapia a la plancha (18 min)',
        description:
            'Prepara el pescado sellado a la plancha con güicoy en lugar de sopa.',
        swappedIngredients: ['Filete de tilapia', 'Güicoy'],
      ),
    ],
  ),
  Recipe(
    id: 'caldo_frijoles_colorados_verduras',
    title: 'Sopa Casera de Frijoles Colorados con Güicoy y Repollo',
    description:
        'Sopa sustanciosa guatemalteca rica en fibra, hierro vegetal y aromático epazote tradicional.',
    ingredients: [
      RecipeIngredient(name: 'Frijoles colorados', displayAmount: '2 tazas cocidas'),
      RecipeIngredient(name: 'Güicoy', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Repollo blanco', displayAmount: '2 tazas picadas'),
      RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1/2 unidad'),
      RecipeIngredient(name: 'Ajo', displayAmount: '2 dientes'),
      RecipeIngredient(name: 'Epazote', displayAmount: '2 ramitas'),
      RecipeIngredient(name: 'Elote', displayAmount: '1 unidad en rodajas'),
    ],
    instructions: [
      'Licuar media taza de los frijoles colorados cocidos con su propio caldo y una taza de agua para dar cuerpo a la sopa.',
      'En una olla cocinar el tomate picado, la cebolla y el ajo por 5 minutos, luego verter el licuado de frijol, el resto de frijoles enteros y tres tazas de agua.',
      'Agregar las rodajas de elote y las ramitas de epazote y hervir a fuego medio durante 20 minutos.',
      'Incorporar el güicoy y el repollo blanco y cocer otros 15 minutos hasta que todas las verduras estén tiernas; sazonar con sal al gusto.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 45,
    servings: 4,
    difficulty: 'Media',
    category: 'Sopas y Caldos',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'frijoles_parados_queso',
        title: 'Frijoles parados con queso fresco',
        description:
            'Cocina los frijoles negros con hierbas y acompáñalos con arroz blanco para proteína completa.',
        swappedIngredients: ['Frijoles negros', 'Arroz blanco', 'Queso fresco'],
      ),
      RecipeVariation(
        recipeId: 'sopa_lentejas_espinaca',
        title: 'Versión más rápida con lentejas',
        description:
            'Reemplaza los frijoles colorados por lentejas para reducir el tiempo total a 35 minutos.',
        swappedIngredients: ['Lentejas', 'Espinaca'],
      ),
      RecipeVariation(
        recipeId: 'sopa_ayote_garbanzos',
        title: 'Crema de ayote y garbanzos',
        description:
            'Cambia el caldo rústico por crema licuada de ayote con garbanzos.',
        swappedIngredients: ['Ayote', 'Garbanzos'],
      ),
    ],
  ),

  // =========================================================================
  // ENSALADAS (6 nuevas recetas: 2 <=20 min, 2 21-40 min, 2 41-60 min)
  // =========================================================================
  Recipe(
    id: 'ensalada_atun_pepino_garbanzos',
    title: 'Ensalada Fresca de Atún con Pepino y Garbanzos',
    description:
        'Ensalada sin cocción lista en 12 minutos, rica en proteína magra y fibra soluble.',
    ingredients: [
      RecipeIngredient(name: 'Atún en lata', displayAmount: '2 latas escurridas'),
      RecipeIngredient(name: 'Garbanzos', displayAmount: '1 taza cocida'),
      RecipeIngredient(name: 'Pepino', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/4 unidad'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Limón', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
    ],
    instructions: [
      'Escurrir bien el atún y enjuagar los garbanzos cocidos bajo el grifo.',
      'Cortar el pepino en cubos pequeños y picar finamente la cebolla morada y el cilantro.',
      'Mezclar todos los ingredientes en un tazón grande evitando deshacer por completo el atún.',
      'Aliñar con el jugo de limón, aceite de oliva y sal al gusto.',
    ],
    prepTimeMinutes: 12,
    cookTimeMinutes: 0,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Ensaladas',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ensalada_aguacate_tomate',
        title: 'Versión vegetariana de aguacate y queso',
        description:
            'Sustituye el atún y garbanzos por aguacate, tomate y queso fresco.',
        swappedIngredients: ['Aguacate', 'Tomate', 'Queso fresco'],
      ),
      RecipeVariation(
        recipeId: 'salteado_atun_guicoy',
        title: 'Salteado caliente con güicoy',
        description:
            'Lleva el atún al sartén con güicoy y chile pimiento para una cena tibia.',
        swappedIngredients: ['Güicoy', 'Chile pimiento'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_tibia_garbanzos_pollo',
        title: 'Con pechuga a la plancha y brócoli',
        description:
            'Cambia el atún por pechuga de pollo dorada y floretes de brócoli asados.',
        swappedIngredients: ['Pechuga de pollo', 'Brócoli'],
      ),
    ],
  ),
  Recipe(
    id: 'ensalada_fresa_pollo_espinaca',
    title: 'Ensalada Rápida de Espinaca, Fresa y Pollo Desmenuzado',
    description:
        'Ensalada fresca lista en 15 minutos que combina vitamina C de las fresas para absorber el hierro de la espinaca.',
    ingredients: [
      RecipeIngredient(name: 'Espinaca', displayAmount: '3 tazas de hojas'),
      RecipeIngredient(name: 'Fresa', displayAmount: '8 unidades rebanadas'),
      RecipeIngredient(name: 'Pollo desmenuzado', displayAmount: '220 g'),
      RecipeIngredient(name: 'Almendras', displayAmount: '2 cdas'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
    ],
    instructions: [
      'Lavar y secar cuidadosamente las hojas frescas de espinaca.',
      'Rebanar las fresas y tostar brevemente o picar las almendras.',
      'Colocar en una ensaladera la espinaca, el pollo desmenuzado y las fresas.',
      'Aderezar al momento de servir con jugo de limón, aceite de oliva, sal al gusto y almendras.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 0,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Ensaladas',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ensalada_manzana_nueces',
        title: 'Con manzana verde, nueces y pechuga',
        description:
            'Reemplaza las fresas y almendras por manzana verde y nueces sobre lechuga.',
        swappedIngredients: ['Manzana', 'Nueces', 'Lechuga'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_pollo_aguacate_pepino',
        title: 'Versión salada con aguacate y berro',
        description:
            'Omite las fresas y prepara una base de berro, pepino, rábano y aguacate.',
        swappedIngredients: ['Berro', 'Aguacate', 'Pepino'],
      ),
    ],
  ),
  Recipe(
    id: 'ensalada_camarones_mango_aguacate',
    title: 'Ensalada Tropical de Camarones, Mango y Aguacate',
    description:
        'Ensalada colorida y saciante con camarones salteados brevemente, mango fresco y aderezo cítrico.',
    ingredients: [
      RecipeIngredient(name: 'Camarones', displayAmount: '300 g limpios'),
      RecipeIngredient(name: 'Mango', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Aguacate', displayAmount: '1 unidad en cubos'),
      RecipeIngredient(name: 'Lechuga', displayAmount: '3 tazas troceadas'),
      RecipeIngredient(name: 'Cebolla morada', displayAmount: '1/4 unidad'),
      RecipeIngredient(name: 'Cilantro', displayAmount: '1/4 manojo'),
      RecipeIngredient(name: 'Limón', displayAmount: '2 unidades'),
    ],
    instructions: [
      'Saltear los camarones limpios en una sartén caliente con un toque de limón y sal al gusto por 4 minutos hasta quedar rosados; dejar enfriar un poco.',
      'Cortar el mango maduro pero firme, el aguacate y la cebolla morada en cubos o plumas finas.',
      'Disponer una cama de lechuga fresca en platos amplios.',
      'Repartir el mango, el aguacate, los camarones y el cilantro fresco, y terminar con jugo de limón.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 10,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Ensaladas',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ceviche_aguacate_pepino',
        title: 'Versión vegetariana tipo ceviche de garbanzo',
        description:
            'Sustituye los camarones y el mango por garbanzos, tomate y pepino.',
        swappedIngredients: ['Garbanzos', 'Tomate', 'Pepino'],
      ),
      RecipeVariation(
        recipeId: 'camarones_ajillo_brocoli',
        title: 'Camarones calientes al ajillo',
        description:
            'Sirve los camarones en plato caliente con brócoli y ajo dorado.',
        swappedIngredients: ['Brócoli', 'Ajo'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_pollo_aguacate_pepino',
        title: 'Con pechuga a la plancha y berro',
        description:
            'Reemplaza los camarones y mango por pechuga de pollo, berro y rábano.',
        swappedIngredients: ['Pechuga de pollo', 'Berro', 'Rábano'],
      ),
    ],
  ),
  Recipe(
    id: 'ensalada_pollo_aguacate_pepino',
    title: 'Ensalada Completa de Pollo a la Plancha, Berro y Aguacate',
    description:
        'Plato único equilibrado con pechuga asada al orégano sobre berro fresco, pepino, rábano y aguacate.',
    ingredients: [
      RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '300 g'),
      RecipeIngredient(name: 'Berro', displayAmount: '2 tazas limpias'),
      RecipeIngredient(name: 'Aguacate', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Rábano', displayAmount: '4 unidades en rodajas'),
      RecipeIngredient(name: 'Pepino', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Limón', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Orégano seco', displayAmount: '1/2 cdita'),
    ],
    instructions: [
      'Sazonar la pechuga de pollo con orégano seco, jugo de medio limón y sal al gusto.',
      'Asar la pechuga en plancha o sartén con media cucharada de aceite de oliva por 6 a 7 minutos de cada lado; reposar y cortar en tiras.',
      'Preparar una base con las hojas limpias de berro, el pepino y los rábanos en rodajas finas.',
      'Colocar encima el pollo tibio y cubos de aguacate, y aderezar con el aceite restante y limón.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 15,
    servings: 2,
    difficulty: 'Fácil',
    category: 'Ensaladas',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'tacos_lechuga_pollo_aguacate',
        title: 'Rollitos frescos en hoja de lechuga (15 min)',
        description:
            'Usa pollo ya desmenuzado y envuelve con tomate y aguacate en hojas de lechuga.',
        swappedIngredients: ['Pollo desmenuzado', 'Lechuga', 'Tomate'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_aguacate_tomate',
        title: 'Versión sin cocción con queso fresco',
        description:
            'Sustituye la pechuga por queso fresco y añade tomate para omitir el sartén.',
        swappedIngredients: ['Queso fresco', 'Tomate'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_tibia_garbanzos_pollo',
        title: 'Versión tibia con garbanzos y brócoli',
        description:
            'Cambia los rábanos por garbanzos y brócoli asado al horno.',
        swappedIngredients: ['Garbanzos', 'Brócoli', 'Zanahoria'],
      ),
    ],
  ),
  Recipe(
    id: 'ensalada_tibia_garbanzos_pollo',
    title: 'Ensalada Tibia de Pechuga, Garbanzos y Brócoli',
    description:
        'Ensalada templada horneada ideal para almuerzos de meal prep ricos en proteína y fibra.',
    ingredients: [
      RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '300 g en cubos'),
      RecipeIngredient(name: 'Garbanzos', displayAmount: '1 1/2 tazas cocidas'),
      RecipeIngredient(name: 'Brócoli', displayAmount: '2 tazas de floretes'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '1 unidad en rodajas'),
      RecipeIngredient(name: 'Espinaca', displayAmount: '2 tazas frescas'),
      RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Comino molido', displayAmount: '1/2 cdita'),
    ],
    instructions: [
      'Precalentar el horno a 195 grados centígrados y mezclar la pechuga en cubos, los garbanzos escurridos, el brócoli y la zanahoria con el aceite de oliva, el comino molido y sal al gusto.',
      'Distribuir todo en una bandeja amplia sin amontonar.',
      'Hornear durante 25 a 30 minutos removiendo a la mitad hasta que los garbanzos estén ligeramente dorados y el pollo bien cocido.',
      'Retirar del horno, mezclar en un tazón con la espinaca fresca para que se entibie y terminar con jugo de limón.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 30,
    servings: 3,
    difficulty: 'Media',
    category: 'Ensaladas',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ensalada_pollo_aguacate_pepino',
        title: 'Ensalada fresca de pollo y aguacate (30 min)',
        description:
            'Prepara la pechuga a la plancha sobre hojas de berro, pepino y aguacate.',
        swappedIngredients: ['Berro', 'Aguacate', 'Pepino'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_atun_pepino_garbanzos',
        title: 'Sin horno con atún y pepino (12 min)',
        description:
            'Cambia el pollo por atún en lata y mezcla directo con los garbanzos y pepino.',
        swappedIngredients: ['Atún en lata', 'Pepino'],
      ),
      RecipeVariation(
        recipeId: 'arroz_integral_garbanzos_espinaca',
        title: 'Tazón con arroz integral y cúrcuma',
        description:
            'Sustituye el pollo por arroz integral para formar una proteína vegetal completa.',
        swappedIngredients: ['Arroz integral', 'Cúrcuma'],
      ),
    ],
  ),
  Recipe(
    id: 'ensalada_tibia_remolacha_queso',
    title: 'Ensalada Tibia de Remolacha Asada, Espinaca y Queso Fresco',
    description:
        'Ensalada colorida de remolacha asada en horno con vinagreta cítrica de naranja, nueces y queso fresco.',
    ingredients: [
      RecipeIngredient(name: 'Remolacha', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Espinaca', displayAmount: '3 tazas'),
      RecipeIngredient(name: 'Queso fresco', displayAmount: '80 g'),
      RecipeIngredient(name: 'Naranja', displayAmount: '1 unidad en gajos'),
      RecipeIngredient(name: 'Nueces', displayAmount: '2 cdas'),
      RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
      RecipeIngredient(name: 'Vinagre de manzana', displayAmount: '1 cda'),
    ],
    instructions: [
      'Precalentar el horno a 200 grados centígrados; pelar y cortar las remolachas en cubos medianos.',
      'Hornear la remolacha rociada con la mitad del aceite de oliva y una pizca de sal al gusto durante 35 a 40 minutos hasta que esté tierna.',
      'Batir el resto del aceite de oliva con el vinagre de manzana para preparar una vinagreta ligera.',
      'Servir la remolacha tibia sobre la espinaca fresca con gajos de naranja, nueces troceadas y queso fresco desmoronado.',
    ],
    prepTimeMinutes: 15,
    cookTimeMinutes: 40,
    servings: 2,
    difficulty: 'Media',
    category: 'Ensaladas',
    nutritionAttributes: {
      NutritionalAttribute.highProtein,
      NutritionalAttribute.lowCalorieDensity,
      NutritionalAttribute.lowSodiumWholeFood,
      NutritionalAttribute.highFiberOrVitamins,
    },
    variations: [
      RecipeVariation(
        recipeId: 'ensalada_manzana_nueces',
        title: 'Ensalada rápida con manzana y pollo (15 min)',
        description:
            'Cambia la remolacha asada por manzana fresca sin horno y añade pechuga de pollo.',
        swappedIngredients: ['Manzana', 'Pechuga de pollo', 'Lechuga'],
      ),
      RecipeVariation(
        recipeId: 'ensalada_tibia_garbanzos_pollo',
        title: 'Versión proteica de garbanzos y pollo',
        description:
            'Sustituye la remolacha y el queso por garbanzos, brócoli y pechuga horneada.',
        swappedIngredients: ['Pechuga de pollo', 'Garbanzos', 'Brócoli'],
      ),
    ],
  ),
];
