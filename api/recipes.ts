import type { VercelRequest, VercelResponse } from '@vercel/node';
import fs from 'node:fs';
import path from 'node:path';

/**
 * Interface representing structured recipe item from Gemini.
 */
interface GeminiRecipeItem {
  id?: string;
  title: string;
  description?: string;
  category?: string;
  prepTimeMinutes?: number;
  cookTimeMinutes?: number;
  servings?: number;
  difficulty?: string;
  ingredients: Array<{ name: string; displayAmount?: string }>;
  instructions: string[];
}

/**
 * Reads the Gemini API key from environment variables or .env.local.
 */
function getGeminiApiKey(): string | undefined {
  if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim().length > 0) {
    return process.env.GEMINI_API_KEY.trim();
  }
  try {
    const envPath = path.resolve(process.cwd(), '.env.local');
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf8');
      const match = content.match(/GEMINI_API_KEY=([^\r\n]+)/);
      if (match) return match[1].trim();
    }
  } catch {}
  return undefined;
}

/**
 * Generates authentic, healthy Spanish recipes using Gemini 3.8 Flash
 * based on the user's available cooking ingredients.
 */
async function generateRecipesWithGemini(
  ingredients: string[]
): Promise<Array<Record<string, unknown>> | null> {
  const apiKey = getGeminiApiKey();
  if (!apiKey) return null;

  const model = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const SYSTEM_INSTRUCTION = `Eres un chef profesional y asesor nutricional experto para la aplicación Food Friend en Guatemala.
Tu objetivo es sugerir recetas caseras, saludables, apetitosas y prácticas en español, basadas primordialmente en los ingredientes seleccionados por el usuario.
Las recetas deben tener instrucciones claras paso a paso en español guatemalteco / latino neutro, y utilizar los ingredientes proporcionados como protagonistas principales.
Los ingredientes deben especificar cantidades realistas (ej. "2 unidades", "1/2 libra", "2 cucharadas").
Devuelve siempre salida JSON estricta según el esquema solicitado.`;

  const PROMPT_TEXT = `El usuario tiene los siguientes ingredientes disponibles en casa: ${ingredients.join(', ')}.

Genera 2 o 3 recetas saludables, apetitosas y concisas en español donde estos ingredientes sean los protagonistas principales.

Devuelve un JSON con:
"recipes": Lista de recetas estructuradas con:
- "id": Identificador único (ej. "gemini_receta_1")
- "title": Título atractivo en español (ej. "Guiso Casero de Yuca y Berenjena al Tomate")
- "description": Breve descripción culinaria atractiva (1 oración)
- "category": Una de ["Almuerzo", "Cena", "Desayuno", "Guarnición", "Sopas y Caldos"]
- "prepTimeMinutes": Tiempo de preparación en minutos (número entero)
- "cookTimeMinutes": Tiempo de cocción en minutos (número entero)
- "servings": Número de porciones (ej. 4)
- "difficulty": "Fácil", "Media" o "Difícil"
- "ingredients": Lista de objetos con "name" (nombre limpio del ingrediente en español que coincida con los ingredientes del usuario o comunes) y "displayAmount" (cantidad sugerida, ej. "1 unidad", "1 taza", "Al gusto")
- "instructions": Lista de pasos claros, ordenados y directos en español (4 a 6 pasos por receta).`;

  const payload = {
    system_instruction: {
      parts: [{ text: SYSTEM_INSTRUCTION }],
    },
    contents: [
      {
        parts: [{ text: PROMPT_TEXT }],
      },
    ],
    generationConfig: {
      response_mime_type: 'application/json',
      temperature: 0.6,
    },
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) {
      console.warn(`[Gemini API] Request returned status ${res.status}`);
      return null;
    }

    const data = (await res.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawText) return null;

    const parsed = JSON.parse(rawText) as { recipes?: GeminiRecipeItem[] };
    if (!parsed.recipes || !Array.isArray(parsed.recipes) || parsed.recipes.length === 0) {
      return null;
    }

    return parsed.recipes.map((r, index) => ({
      id: r.id || `gemini_${Date.now()}_${index}`,
      title: r.title,
      description: r.description || 'Receta saludable sugerida por Food Friend',
      category: r.category || 'Almuerzo',
      prepTimeMinutes: typeof r.prepTimeMinutes === 'number' ? r.prepTimeMinutes : 15,
      cookTimeMinutes: typeof r.cookTimeMinutes === 'number' ? r.cookTimeMinutes : 25,
      servings: typeof r.servings === 'number' ? r.servings : 4,
      difficulty: r.difficulty || 'Fácil',
      source: 'gemini',
      ingredients: (r.ingredients || []).map((ing) => ({
        name: ing.name.trim(),
        displayAmount: ing.displayAmount?.trim() || 'Al gusto',
      })),
      instructions:
        Array.isArray(r.instructions) && r.instructions.length > 0
          ? r.instructions.map((step) => step.trim())
          : ['Preparar y cocinar todos los ingredientes hasta alcanzar el punto deseado.'],
    }));
  } catch (error) {
    clearTimeout(timeout);
    console.warn('[Gemini API] Generation failed or timed out, falling back to traditional database:', error);
    return null;
  }
}

/**
 * Comprehensive Spanish to English ingredient mapping
 * for querying TheMealDB (non-LLM public REST API).
 * Maps Guatemalan and standard Spanish culinary terms to TheMealDB ingredient names.
 */
const SPANISH_TO_ENGLISH_INGREDIENTS: Record<string, string> = {
  // Vegetables / Hortalizas
  tomate: 'tomato',
  miltomate: 'tomatillo',
  cebolla: 'onion',
  'cebolla blanca': 'onion',
  'cebolla morada': 'red_onion',
  'cebolla con tallo': 'spring_onions',
  cebollin: 'spring_onions',
  cebollino: 'spring_onions',
  ajo: 'garlic',
  papa: 'potatoes',
  patata: 'potatoes',
  zanahoria: 'carrots',
  aguacate: 'avocado',
  palta: 'avocado',
  pepino: 'cucumber',
  espinaca: 'spinach',
  lechuga: 'lettuce',
  acelga: 'chard',
  berenjena: 'aubergine',
  aubergine: 'aubergine',
  eggplant: 'aubergine',
  yuca: 'cassava',
  mandioca: 'cassava',
  cassava: 'cassava',
  camote: 'sweet_potato',
  batata: 'sweet_potato',
  remolacha: 'beetroot',
  betabel: 'beetroot',
  rabano: 'radish',
  repollo: 'cabbage',
  'repollo blanco': 'cabbage',
  'repollo morado': 'cabbage',
  col: 'cabbage',
  berro: 'watercress',
  guisquil: 'chayote',
  chayote: 'chayote',
  perulero: 'chayote',
  ayote: 'squash',
  calabaza: 'squash',
  pipian: 'squash',
  calabacita: 'courgettes',
  zucchini: 'courgettes',
  courgette: 'courgettes',
  puerro: 'leek',
  ejote: 'green_beans',
  'judia verde': 'green_beans',
  habichuela: 'green_beans',
  arveja: 'peas',
  chicharo: 'peas',
  elote: 'corn',
  maiz: 'corn',
  choclo: 'corn',
  chile: 'chilli',
  'chile pimiento': 'peppers',
  pimiento: 'peppers',
  'chile jalapeño': 'jalapeno',
  'chile serrano': 'chilli',
  champiñon: 'mushrooms',
  champiñones: 'mushrooms',
  hongos: 'mushrooms',
  apio: 'celery',

  // Herbs & Spices
  cilantro: 'coriander',
  culantro: 'coriander',
  perejil: 'parsley',
  hierbabuena: 'mint',
  menta: 'mint',
  albahaca: 'basil',
  laurel: 'bay_leaf',
  tomillo: 'thyme',
  oregano: 'oregano',
  romero: 'rosemary',
  canela: 'cinnamon',
  pimienta: 'pepper',
  sal: 'salt',
  comino: 'cumin',
  curry: 'curry',
  nueces: 'walnuts',
  nuez: 'walnuts',
  mani: 'peanuts',
  'maní': 'peanuts',
  cacahuate: 'peanuts',
  gouda: 'cheese',
  'queso gouda': 'cheese',
  parmesano: 'parmesan',
  'queso parmesano': 'parmesan',

  // Proteins / Meats / Poultry / Seafood
  pollo: 'chicken',
  'pechuga de pollo': 'chicken_breast',
  'alitas de pollo': 'chicken',
  'muslos de pollo': 'chicken_thighs',
  res: 'beef',
  'carne de res': 'beef',
  'carne molida de res': 'minced_beef',
  'carne molida': 'minced_beef',
  'costilla de res': 'beef',
  'lomo de res': 'beef',
  'posta de res': 'beef',
  cerdo: 'pork',
  'carne de cerdo': 'pork',
  'chuleta de cerdo': 'pork_chops',
  'costilla de cerdo': 'pork',
  'lomo de cerdo': 'pork',
  'posta de cerdo': 'pork',
  tocino: 'bacon',
  bacon: 'bacon',
  panceta: 'bacon',
  pescado: 'fish',
  'filete de pescado': 'fish',
  tilapia: 'fish',
  robalo: 'fish',
  salmon: 'salmon',
  atun: 'tuna',
  'atun en lata': 'tuna',
  camaron: 'prawns',
  camarones: 'prawns',
  longaniza: 'sausage',
  chorizo: 'sausage',
  salchicha: 'sausage',
  jamon: 'ham',

  // Grains / Legumes / Pasta
  arroz: 'rice',
  'arroz blanco': 'rice',
  frijol: 'beans',
  frijoles: 'beans',
  'frijoles negros': 'black_beans',
  'frijoles colorados': 'kidney_beans',
  'frijoles blancos': 'white_beans',
  lentejas: 'lentils',
  garbanzos: 'chickpeas',
  avena: 'oats',
  pasta: 'pasta',
  espagueti: 'spaghetti',
  fideos: 'noodles',
  harina: 'flour',
  'harina de trigo': 'flour',
  'harina de maiz': 'corn flour',
  maicena: 'cornstarch',

  // Dairy & Eggs
  huevo: 'eggs',
  huevos: 'eggs',
  leche: 'milk',
  queso: 'cheese',
  'queso fresco': 'cheese',
  'queso mozzarella': 'mozzarella',
  'queso crema': 'cream_cheese',
  crema: 'cream',
  mantequilla: 'butter',
  yogur: 'yogurt',
  yogurt: 'yogurt',

  // Fruits
  limon: 'lemon',
  limón: 'lemon',
  platano: 'banana',
  plátano: 'banana',
  banano: 'banana',
  naranja: 'orange',
  piña: 'pineapple',
  pina: 'pineapple',
  manzana: 'apple',
  fresa: 'strawberries',
};

/**
 * English to Spanish ingredient translation dictionary.
 */
const ENGLISH_TO_SPANISH_INGREDIENTS: Record<string, string> = {
  aubergine: 'Berenjena',
  eggplant: 'Berenjena',
  cassava: 'Yuca',
  yuca: 'Yuca',
  courgettes: 'Calabacitas',
  courgette: 'Calabacita',
  zucchini: 'Calabacita',
  'yellow pepper': 'Chile pimiento amarillo',
  'red pepper': 'Chile pimiento rojo',
  'green pepper': 'Chile pimiento verde',
  'bell pepper': 'Chile pimiento',
  peppers: 'Chile pimiento',
  pepper: 'Pimienta',
  'black pepper': 'Pimienta negra',
  tomato: 'Tomate',
  tomatoes: 'Tomates',
  'cherry tomatoes': 'Tomates cherry',
  'tomato puree': 'Puré de tomate',
  'tomato paste': 'Pasta de tomate',
  'chopped tomatoes': 'Tomates picados',
  'olive oil': 'Aceite de oliva',
  'vegetable oil': 'Aceite vegetal',
  oil: 'Aceite',
  garlic: 'Ajo',
  'garlic clove': 'Diente de ajo',
  'garlic cloves': 'Dientes de ajo',
  onion: 'Cebolla',
  onions: 'Cebollas',
  'red onion': 'Cebolla morada',
  'spring onions': 'Cebollines',
  scallions: 'Cebollines',
  basil: 'Albahaca',
  parsley: 'Perejil',
  coriander: 'Cilantro',
  mint: 'Hierbabuena',
  oregano: 'Orégano',
  thyme: 'Tomillo',
  rosemary: 'Romero',
  salt: 'Sal',
  sugar: 'Azúcar',
  'brown sugar': 'Azúcar morena',
  lemon: 'Limón',
  'lemon juice': 'Jugo de limón',
  lime: 'Limón',
  'lime juice': 'Jugo de limón',
  potato: 'Papa',
  potatoes: 'Papas',
  'sweet potato': 'Camote',
  'sweet potatoes': 'Camotes',
  carrot: 'Zanahoria',
  carrots: 'Zanahorias',
  chicken: 'Pollo',
  'chicken breast': 'Pechuga de pollo',
  'chicken breasts': 'Pechugas de pollo',
  'chicken thighs': 'Muslos de pollo',
  'chicken wings': 'Alitas de pollo',
  beef: 'Carne de res',
  'minced beef': 'Carne molida de res',
  'ground beef': 'Carne molida de res',
  pork: 'Cerdo',
  'pork chops': 'Chuletas de cerdo',
  bacon: 'Tocino',
  fish: 'Pescado',
  salmon: 'Salmón',
  tuna: 'Atún',
  prawns: 'Camarones',
  shrimp: 'Camarones',
  egg: 'Huevo',
  eggs: 'Huevos',
  cheese: 'Queso',
  'parmesan cheese': 'Queso parmesano',
  parmesan: 'Queso parmesano',
  'cheddar cheese': 'Queso cheddar',
  mozzarella: 'Queso mozzarella',
  milk: 'Leche',
  'coconut milk': 'Leche de coco',
  'condensed milk': 'Leche condensada',
  'evaporated milk': 'Leche evaporada',
  butter: 'Mantequilla',
  cream: 'Crema',
  'sour cream': 'Crema agria',
  yogurt: 'Yogur',
  rice: 'Arroz',
  beans: 'Frijoles',
  'black beans': 'Frijoles negros',
  'kidney beans': 'Frijoles colorados',
  chickpeas: 'Garbanzos',
  lentils: 'Lentejas',
  peas: 'Arvejas',
  'green beans': 'Ejotes',
  spinach: 'Espinaca',
  lettuce: 'Lechuga',
  cucumber: 'Pepino',
  cabbage: 'Repollo',
  celery: 'Apio',
  mushrooms: 'Champiñones',
  mushroom: 'Champiñón',
  flour: 'Harina',
  'plain flour': 'Harina de trigo',
  cornstarch: 'Maicena',
  water: 'Agua',
  'soy sauce': 'Salsa de soya',
  vinegar: 'Vinagre',
  'red wine vinegar': 'Vinagre de vino tinto',
  'white vinegar': 'Vinagre blanco',
  cinnamon: 'Canela',
  vanilla: 'Vainilla',
  'vanilla extract': 'Extracto de vainilla',
  cumin: 'Comino',
  cloves: 'Clavos de olor',
  allspice: 'Pimienta gorda',
  bread: 'Pan',
  pasta: 'Pasta',
  spaghetti: 'Espagueti',
  noodles: 'Fideos',
  oats: 'Avena',
  beetroot: 'Remolacha',
  radish: 'Rábano',
};

/**
 * Common culinary English to Spanish dictionary for translating
 * traditional external recipe titles, categories, and measures.
 */
const COMMON_TRANSLATIONS: Record<string, string> = {
  aubergine: 'Berenjena',
  eggplant: 'Berenjena',
  cassava: 'Yuca',
  chicken: 'Pollo',
  beef: 'Carne de res',
  fish: 'Pescado',
  pork: 'Cerdo',
  tuna: 'Atún',
  salmon: 'Salmón',
  egg: 'Huevo',
  eggs: 'Huevos',
  cheese: 'Queso',
  chickpea: 'Garbanzo',
  chickpeas: 'Garbanzos',
  beetroot: 'Remolacha',
  cabbage: 'Repollo',
  mushroom: 'Champiñón',
  mushrooms: 'Champiñones',
  spinach: 'Espinaca',
  potato: 'Papa',
  potatoes: 'Papas',
  carrot: 'Zanahoria',
  carrots: 'Zanahorias',
  tomato: 'Tomate',
  tomatoes: 'Tomates',
  onion: 'Cebolla',
  onions: 'Cebollas',
  garlic: 'Ajo',
  lemon: 'Limón',
  vegetarian: 'Vegetariano',
  dessert: 'Postre',
  side: 'Acompañamiento',
  starter: 'Entrada',
  pasta: 'Pasta',
  soup: 'Sopa',
  stew: 'Guiso',
  salad: 'Ensalada',
  rice: 'Arroz',
  curry: 'Curry',
  pie: 'Pastel',
  cake: 'Pastel',
  pancakes: 'Panqueques',
  roast: 'Asado',
  boiled: 'Cocido',
  fried: 'Frito',
  grilled: 'A la plancha',
  grills: 'A la plancha',
  baked: 'Al horno',
  spicy: 'Picante',
  crispy: 'Crujiente',
  casserole: 'Cazuela',
  pudding: 'Pudín',
  wings: 'Alitas',
  couscous: 'Cuscús',
  sauerkraut: 'Chucrut',
  sauce: 'Salsa',
  dressing: 'Aderezo',
  sweet: 'Dulce',
  bread: 'Pan',
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
 * Translates an ingredient name from English to Spanish.
 */
function translateIngredientToSpanish(raw: string): string {
  const cleaned = raw.trim();
  const normalized = normalizeText(cleaned);

  if (ENGLISH_TO_SPANISH_INGREDIENTS[normalized]) {
    return ENGLISH_TO_SPANISH_INGREDIENTS[normalized];
  }

  // Partial match against known dictionary entries
  for (const [en, es] of Object.entries(ENGLISH_TO_SPANISH_INGREDIENTS)) {
    if (normalized === en || normalized.includes(en)) {
      return es;
    }
  }

  // Fallback to title translator
  return translateTitleToSpanish(cleaned);
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
 * Asynchronously translates an English recipe title into natural Spanish
 * using MyMemory Translation API with fallback to the dictionary heuristic.
 */
async function translateTitleAsync(title: string): Promise<string> {
  const dictionaryFallback = translateTitleToSpanish(title);
  if (!title || title.trim().length === 0) return dictionaryFallback;

  try {
    const clean = title.replace(/[&]/g, 'and').trim();
    const apiUrl = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(clean)}&langpair=en|es`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2500);

    const res = await fetch(apiUrl, { signal: controller.signal });
    clearTimeout(timeout);

    if (res.ok) {
      const data = (await res.json()) as { responseData?: { translatedText?: string } };
      const rawTranslated = data.responseData?.translatedText?.trim();
      if (rawTranslated && rawTranslated.length > 0 && !rawTranslated.toLowerCase().includes('mymemory')) {
        // Fix all-caps or all-lowercase
        return rawTranslated.charAt(0).toUpperCase() + rawTranslated.slice(1).toLowerCase();
      }
    }
  } catch {
    // Fall back to dictionary
  }

  return dictionaryFallback;
}

/**
 * Asynchronously translates English preparation instructions into fluent Spanish steps.
 */
async function translateInstructionsAsync(raw: string): Promise<string[]> {
  const steps = formatInstructions(raw);
  if (steps.length === 0) {
    return [
      'Preparar y limpiar todos los ingredientes.',
      'Cocinar a fuego medio en una sartén u olla hasta alcanzar el punto deseado.',
      'Servir caliente.',
    ];
  }

  // Join top steps for batch translation
  const candidateSteps = steps.slice(0, 5);
  const combined = candidateSteps.join(' || ');

  try {
    const apiUrl = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(combined.slice(0, 500))}&langpair=en|es`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3500);

    const res = await fetch(apiUrl, { signal: controller.signal });
    clearTimeout(timeout);

    if (res.ok) {
      const data = (await res.json()) as { responseData?: { translatedText?: string } };
      const translated = data.responseData?.translatedText;
      if (translated && translated.includes('||')) {
        return translated
          .split('||')
          .map((s) => s.trim())
          .filter((s) => s.length > 5)
          .map((s) => (s.endsWith('.') ? s : `${s}.`));
      }
    }
  } catch {
    // Fall back to candidate steps
  }

  return candidateSteps;
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
    .map((s) => (s.endsWith('.') ? s : `${s}.`));
}

/**
 * Maps a single Spanish ingredient name to its English TheMealDB equivalent.
 */
function mapSpanishToEnglish(spanishNormalized: string): string | null {
  if (SPANISH_TO_ENGLISH_INGREDIENTS[spanishNormalized]) {
    return SPANISH_TO_ENGLISH_INGREDIENTS[spanishNormalized];
  }

  for (const [key, val] of Object.entries(SPANISH_TO_ENGLISH_INGREDIENTS)) {
    if (spanishNormalized === key || spanishNormalized.includes(key) || key.includes(spanishNormalized)) {
      return val;
    }
  }

  // If already ASCII English letters, attempt direct query
  if (/^[a-z_ ]+$/.test(spanishNormalized) && spanishNormalized.length >= 3) {
    return spanishNormalized.replace(/\s+/g, '_');
  }

  return null;
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

    // 1. Primary: Generate authentic Spanish recipes with Gemini 3.8 Flash
    try {
      const geminiRecipes = await generateRecipesWithGemini(sanitizedList);
      if (geminiRecipes && geminiRecipes.length > 0) {
        return res.status(200).json({
          success: true,
          count: geminiRecipes.length,
          recipes: geminiRecipes,
        });
      }
    } catch (geminiError) {
      console.warn('[Backend Proxy] Gemini generation failed, falling back to traditional database:', geminiError);
    }

    // 2. Secondary fallback: Query traditional recipe databases (TheMealDB) with translation
    const englishTerms: string[] = [];
    for (const spanish of sanitizedList) {
      const mapped = mapSpanishToEnglish(spanish);
      if (mapped && !englishTerms.includes(mapped)) {
        englishTerms.push(mapped);
      }
    }

    if (englishTerms.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        recipes: [],
        message: 'No se encontraron equivalencias para los ingredientes indicados en el recetario externo.',
      });
    }

    // Query TheMealDB filter endpoint for each mapped ingredient (up to 3 queries in parallel)
    const activeTerms = englishTerms.slice(0, 3);
    const filterPromises = activeTerms.map(async (term) => {
      try {
        const apiUrl = `https://www.themealdb.com/api/json/v1/1/filter.php?i=${encodeURIComponent(term)}`;
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);
        const response = await fetch(apiUrl, { signal: controller.signal });
        clearTimeout(timeout);

        if (!response.ok) return [];
        const data = (await response.json()) as { meals?: Array<{ idMeal: string; strMeal: string }> };
        return data.meals ?? [];
      } catch {
        return [];
      }
    });

    const mealLists = await Promise.all(filterPromises);

    // Track occurrence frequency of each meal to prioritize recipes matching multiple terms
    const mealCountMap = new Map<string, { meal: { idMeal: string; strMeal: string }; count: number }>();
    for (const list of mealLists) {
      for (const item of list) {
        const existing = mealCountMap.get(item.idMeal);
        if (existing) {
          existing.count += 1;
        } else {
          mealCountMap.set(item.idMeal, { meal: item, count: 1 });
        }
      }
    }

    if (mealCountMap.size === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        recipes: [],
        message: 'No se encontraron recetas externas para los ingredientes indicados.',
      });
    }

    // 1. Prioritize meals that match multiple queried ingredients (count > 1)
    const multiMatchMeals: Array<{ idMeal: string; strMeal: string }> = [];
    for (const entry of mealCountMap.values()) {
      if (entry.count > 1) {
        multiMatchMeals.push(entry.meal);
      }
    }

    // 2. Interleave candidates across each ingredient list in round-robin order
    const selectedMeals: Array<{ idMeal: string; strMeal: string }> = [...multiMatchMeals];
    const seenIds = new Set<string>(multiMatchMeals.map((m) => m.idMeal));

    const maxListLength = Math.max(...mealLists.map((l) => l.length));
    for (let i = 0; i < maxListLength && selectedMeals.length < 5; i++) {
      for (const list of mealLists) {
        if (i < list.length && selectedMeals.length < 5) {
          const item = list[i];
          if (!seenIds.has(item.idMeal)) {
            seenIds.add(item.idMeal);
            selectedMeals.push(item);
          }
        }
      }
    }

    // Fetch details for selected candidate meals
    const detailPromises = selectedMeals.map(async (preview) => {
      try {
        const detailUrl = `https://www.themealdb.com/api/json/v1/1/lookup.php?i=${preview.idMeal}`;
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);
        const detailRes = await fetch(detailUrl, { signal: controller.signal });
        clearTimeout(timeout);

        if (!detailRes.ok) return null;
        const detailData = (await detailRes.json()) as { meals?: Array<Record<string, string | null>> };
        const meal = detailData.meals?.[0];
        if (!meal) return null;

        // Extract ingredients and translate to Spanish
        const ingredients = [];
        for (let i = 1; i <= 20; i++) {
          const ingName = meal[`strIngredient${i}`];
          const measure = meal[`strMeasure${i}`];
          if (ingName && ingName.trim().length > 0) {
            ingredients.push({
              name: translateIngredientToSpanish(ingName.trim()),
              displayAmount: measure && measure.trim().length > 0 ? measure.trim() : 'Al gusto',
            });
          }
        }

        const rawInstructions = meal.strInstructions ?? '';
        const rawTitle = meal.strMeal ?? 'Receta Internacional';

        const [translatedTitle, instructions] = await Promise.all([
          translateTitleAsync(rawTitle),
          translateInstructionsAsync(rawInstructions),
        ]);

        return {
          id: `external_${meal.idMeal}`,
          title: translatedTitle,
          description: `Receta tradicional adaptada (${meal.strArea ?? 'Internacional'})`,
          category: meal.strCategory ? translateTitleToSpanish(meal.strCategory) : 'Almuerzo',
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          servings: 4,
          difficulty: 'Fácil',
          source: 'external',
          ingredients:
            ingredients.length > 0
              ? ingredients
              : [{ name: 'Ingrediente principal', displayAmount: '1 porción' }],
          instructions:
            instructions.length > 0
              ? instructions
              : [
                  'Preparar y limpiar todos los ingredientes.',
                  'Cocinar a fuego medio en una sartén u olla hasta alcanzar el punto deseado.',
                  'Servir caliente.',
                ],
        };
      } catch {
        return null;
      }
    });

    const detailedRecipes = (await Promise.all(detailPromises)).filter(Boolean);

    return res.status(200).json({
      success: true,
      count: detailedRecipes.length,
      recipes: detailedRecipes,
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
