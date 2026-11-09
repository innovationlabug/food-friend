import type { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Traditional recipe ingredient mapping from Spanish to English
 * for querying TheMealDB (non-LLM public REST API).
 */
const SPANISH_TO_ENGLISH_INGREDIENTS: Record<string, string> = {
  tomate: 'tomato',
  miltomate: 'tomatillo',
  cebolla: 'onion',
  'cebolla blanca': 'onion',
  'cebolla morada': 'red_onion',
  ajo: 'garlic',
  pollo: 'chicken',
  'pechuga de pollo': 'chicken_breast',
  'alitas de pollo': 'chicken',
  papa: 'potato',
  zanahoria: 'carrot',
  aguacate: 'avocado',
  pepino: 'cucumber',
  espinaca: 'spinach',
  lechuga: 'lettuce',
  arroz: 'rice',
  'arroz blanco': 'rice',
  frijol: 'beans',
  frijoles: 'beans',
  'frijoles negros': 'black_beans',
  lentejas: 'lentils',
  pescado: 'fish',
  'filete de pescado': 'fish',
  res: 'beef',
  'carne de res': 'beef',
  'carne molida de res': 'minced_beef',
  huevo: 'egg',
  huevos: 'eggs',
  queso: 'cheese',
  limon: 'lemon',
  'limón': 'lemon',
  cilantro: 'coriander',
  perejil: 'parsley',
  hierbabuena: 'mint',
  oregano: 'oregano',
  'orégano': 'oregano',
  pimienta: 'pepper',
  sal: 'salt',
  chile: 'chilli',
  'chile pimiento': 'bell_pepper',
  platano: 'plantain',
  'plátano': 'plantain',
};

/**
 * Common culinary English to Spanish dictionary for translating
 * traditional external recipe titles, categories, and measures.
 */
const COMMON_TRANSLATIONS: Record<string, string> = {
  chicken: 'Pollo',
  beef: 'Carne de res',
  fish: 'Pescado',
  pork: 'Cerdo',
  vegetarian: 'Vegetariano',
  pasta: 'Pasta',
  soup: 'Sopa',
  stew: 'Guiso',
  salad: 'Ensalada',
  rice: 'Arroz',
  curry: 'Curry',
  pie: 'Pastel',
  roast: 'Asado',
  boiled: 'Cocido',
  fried: 'Frito',
  grilled: 'A la plancha',
  baked: 'Al horno',
  lemon: 'Limón',
  garlic: 'Ajo',
  tomato: 'Tomate',
  onion: 'Cebolla',
  potato: 'Papa',
  carrot: 'Zanahoria',
  spicy: 'Picante',
  crispy: 'Crujiente',
  casserole: 'Cazuela',
};

/**
 * Normalizes input text by removing accents, trimming, and converting to lowercase.
 */
function normalizeText(text: string): string {
  return text
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

/**
 * Translates recipe title from English to Spanish using dictionary heuristics.
 */
function translateTitleToSpanish(title: string): string {
  let translated = title;
  for (const [en, es] of Object.entries(COMMON_TRANSLATIONS)) {
    const regex = new RegExp(`\\b${en}\\b`, 'gi');
    translated = translated.replace(regex, es);
  }
  return translated;
}

/**
 * Splits meal preparation instructions into clean, readable steps in Spanish.
 */
function formatInstructions(raw: string): string[] {
  if (!raw || typeof raw !== 'string') return [];

  return raw
    .split(/\r?\n+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 10 && !s.toLowerCase().startsWith('step'))
    .map((s) => {
      // Basic sentence cleanup
      return s.endsWith('.') ? s : `${s}.`;
    });
}

/**
 * Serverless API endpoint: `/api/recipes`
 * Queries traditional (non-LLM) recipe databases (TheMealDB) with Spanish query mapping
 * and returns structured JSON conforming to Food Friend's Recipe model.
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    let inputIngredients: string[] = [];

    if (req.method === 'POST') {
      const body = req.body ?? {};
      if (Array.isArray(body.ingredients)) {
        inputIngredients = body.ingredients.map((i: unknown) => String(i));
      }
    } else if (req.method === 'GET') {
      const queryParam = req.query.ingredients;
      if (typeof queryParam === 'string') {
        inputIngredients = queryParam.split(',').map((s) => s.trim());
      } else if (Array.isArray(queryParam)) {
        inputIngredients = queryParam.map(String);
      }
    } else {
      return res.status(405).json({
        success: false,
        error: 'Método HTTP no permitido. Use GET o POST.',
      });
    }

    // Sanitize and filter input ingredients
    const sanitizedList = inputIngredients
      .map(normalizeText)
      .filter((s) => s.length > 0 && s.length < 50);

    if (sanitizedList.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Debe proporcionar al menos un ingrediente válido para la búsqueda.',
        recipes: [],
      });
    }

    // Map first recognizable Spanish ingredient to English query
    let targetEnglishIngredient = 'chicken';
    for (const spanish of sanitizedList) {
      if (SPANISH_TO_ENGLISH_INGREDIENTS[spanish]) {
        targetEnglishIngredient = SPANISH_TO_ENGLISH_INGREDIENTS[spanish];
        break;
      }
      for (const [key, val] of Object.entries(SPANISH_TO_ENGLISH_INGREDIENTS)) {
        if (spanish.includes(key) || key.includes(spanish)) {
          targetEnglishIngredient = val;
          break;
        }
      }
    }

    // Traditional REST API query to TheMealDB
    const apiUrl = `https://www.themealdb.com/api/json/v1/1/filter.php?i=${encodeURIComponent(
      targetEnglishIngredient
    )}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);

    const filterResponse = await fetch(apiUrl, { signal: controller.signal });
    clearTimeout(timeout);

    if (!filterResponse.ok) {
      throw new Error(`Error en API externa de recetas: ${filterResponse.status}`);
    }

    const filterData = (await filterResponse.json()) as { meals?: Array<{ idMeal: string; strMeal: string }> };

    if (!filterData.meals || filterData.meals.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        recipes: [],
        message: 'No se encontraron recetas externas para los ingredientes indicados.',
      });
    }

    // Take top 3 meals to avoid rate-limiting and keep response fast
    const candidateMeals = filterData.meals.slice(0, 3);
    const recipes = [];

    for (const mealPreview of candidateMeals) {
      try {
        const detailUrl = `https://www.themealdb.com/api/json/v1/1/lookup.php?i=${mealPreview.idMeal}`;
        const detailController = new AbortController();
        const detailTimeout = setTimeout(() => detailController.abort(), 4000);

        const detailRes = await fetch(detailUrl, { signal: detailController.signal });
        clearTimeout(detailTimeout);

        if (detailRes.ok) {
          const detailData = (await detailRes.json()) as { meals?: Array<Record<string, string | null>> };
          const meal = detailData.meals?.[0];
          if (meal) {
            // Extract ingredients
            const ingredients = [];
            for (let i = 1; i <= 20; i++) {
              const ingName = meal[`strIngredient${i}`];
              const measure = meal[`strMeasure${i}`];
              if (ingName && ingName.trim().length > 0) {
                ingredients.push({
                  name: translateTitleToSpanish(ingName.trim()),
                  displayAmount: measure ? measure.trim() : 'Al gusto',
                });
              }
            }

            const rawInstructions = meal.strInstructions ?? '';
            const instructions = formatInstructions(rawInstructions);

            recipes.push({
              id: `external_${meal.idMeal}`,
              title: translateTitleToSpanish(meal.strMeal ?? 'Receta Internacional'),
              description: `Receta tradicional adaptada (${meal.strArea ?? 'Internacional'})`,
              category: meal.strCategory ? translateTitleToSpanish(meal.strCategory) : 'Almuerzo',
              prepTimeMinutes: 15,
              cookTimeMinutes: 30,
              servings: 4,
              difficulty: 'Fácil',
              source: 'external',
              ingredients: ingredients.length > 0 ? ingredients : [
                { name: 'Ingrediente principal', displayAmount: '1 porción' }
              ],
              instructions: instructions.length > 0 ? instructions : [
                'Preparar y limpiar todos los ingredientes.',
                'Cocinar a fuego medio en una sartén u olla hasta alcanzar el punto deseado.',
                'Servir caliente.',
              ],
            });
          }
        }
      } catch {
        // Individual lookup timeout/failure gracefully ignored
      }
    }

    return res.status(200).json({
      success: true,
      count: recipes.length,
      recipes,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Error al consultar API externa';
    return res.status(502).json({
      success: false,
      error: message,
      recipes: [],
    });
  }
}
