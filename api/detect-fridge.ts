import type { VercelRequest, VercelResponse } from '@vercel/node';
import fs from 'node:fs';
import path from 'node:path';

/**
 * Permitted confidence levels for detected ingredients.
 */
export type ConfidenceLevel = 'high' | 'medium' | 'low';

/**
 * Structured detected food item from a refrigerator or pantry photo.
 */
export interface FridgeDetectedItem {
  name: string;
  standardIngredient: string;
  brand: string;
  quantity: string;
  confidence: ConfidenceLevel;
  isLocalBrand: boolean;
  category: string;
  notes?: string;
}

/**
 * Response payload for the fridge photo detection endpoint.
 */
export interface DetectFridgeResponse {
  success: boolean;
  summary?: string;
  items: FridgeDetectedItem[];
  error?: string;
}

/**
 * Maximum permitted image payload size in bytes (~10 MB).
 */
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

/**
 * Allowed MIME types for vision analysis.
 */
const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
]);

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
 * Normalizes raw confidence strings to strictly 'high' | 'medium' | 'low'.
 */
function normalizeConfidence(raw: unknown): ConfidenceLevel {
  if (typeof raw !== 'string') return 'medium';
  const lower = raw.trim().toLowerCase();
  if (lower === 'high' || lower === 'alta' || lower === 'alto') return 'high';
  if (lower === 'low' || lower === 'baja' || lower === 'bajo') return 'low';
  return 'medium';
}

/**
 * System instruction tuned for Guatemalan kitchen and food recognition.
 */
const FRIDGE_SYSTEM_INSTRUCTION = `Eres un asistente experto en reconocimiento visual de alimentos, refrigeradores y despensas para la aplicación Food Friend en Guatemala.
Tu objetivo es identificar con alta precisión productos de refrigerador y alacena, reconociendo tanto marcas locales de Guatemala y Centroamérica (por ejemplo: Trebolac, Malher, Incaparina, Ducal, Sula, YaEstá, Pollo Campero, Don Lázaro, Foremost, B&B, Tortrix, Queso de Capas, crema de vaca local, embutidos Toledo o Perry, güisquil, perulero, aguacate criollo, hierbabuena, plátano, etc.) como marcas internacionales habituales (Hellmann's, Heinz, etc.).

Examina minuciosamente la imagen por niveles, bandejas o compartimentos.
Para cada alimento detectado:
1. "name": Nombre comercial o descriptivo del producto visto.
2. "standardIngredient": Nombre limpio, canónico y singular del ingrediente en español para cocinar (ej. "Leche entera", "Tomate", "Cebolla", "Huevos", "Queso fresco", "Frijoles negros", "Mantequilla").
3. "brand": Marca identificada o "Genérica" o "Casero".
4. "quantity": Estimación visual de cantidad (ej. "1 botella de 1L", "4 unidades", "1 refractario mediano").
5. "confidence": "high" (si el producto es claramente visible e inequívoco), "medium" (si es probable pero parcialmente cubierto o en recipiente genérico) o "low" (si hay duda razonable).
6. "isLocalBrand": booleano que indica si es una marca tradicionalmente guatemalteca o regional centroamericana.
7. "category": Categoría culinaria (Lácteos, Frutas y Verduras, Carnes y Embutidos, Bebidas, Condimentos y Salsas, Granos y Abarrotes, Platos Preparados).

Devuelve siempre información estructurada en formato JSON estricto.`;

const FRIDGE_PROMPT_TEXT = `Analiza detalladamente esta fotografía de refrigerador / alacena.
Identifica cada producto visible que sea un alimento o ingrediente de cocina.
Devuelve un JSON con:
- "summary": Breve descripción general en español de lo que contiene el refrigerador.
- "items": Lista detallada de productos detectados con: "name", "standardIngredient", "brand", "quantity", "confidence" ("high", "medium" o "low"), "isLocalBrand" (booleano), "category".`;

/**
 * Calls Gemini 3.8 Flash Vision to detect ingredients in the provided image.
 */
async function analyzeFridgeWithGemini(
  base64Data: string,
  mimeType: string
): Promise<{ summary?: string; items: FridgeDetectedItem[] }> {
  const apiKey = getGeminiApiKey();
  if (!apiKey) {
    throw new Error('No se encontró GEMINI_API_KEY configurada en el servidor.');
  }

  const model = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const payload = {
    system_instruction: {
      parts: [{ text: FRIDGE_SYSTEM_INSTRUCTION }],
    },
    contents: [
      {
        parts: [
          { text: FRIDGE_PROMPT_TEXT },
          {
            inline_data: {
              mime_type: mimeType,
              data: base64Data,
            },
          },
        ],
      },
    ],
    generationConfig: {
      response_mime_type: 'application/json',
      temperature: 0.3,
    },
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 35000);

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) {
      throw new Error(`Gemini Vision API devolvió código HTTP ${res.status}`);
    }

    const data = (await res.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawText) {
      throw new Error('La respuesta de Gemini no contiene candidatos de texto.');
    }

    const parsed = JSON.parse(rawText) as {
      summary?: string;
      resumen?: string;
      items?: Array<{
        name?: string;
        producto?: string;
        standardIngredient?: string;
        ingrediente_estandar?: string;
        brand?: string;
        marca?: string;
        quantity?: string;
        cantidad?: string;
        cantidad_estimada?: string;
        confidence?: unknown;
        confianza?: unknown;
        isLocalBrand?: boolean;
        es_marca_local?: boolean;
        category?: string;
        categoria?: string;
        notes?: string;
        observaciones?: string;
      }>;
    };

    const rawItems = parsed.items || [];
    const items: FridgeDetectedItem[] = [];
    for (const it of rawItems) {
      const name = (it.name || it.producto || it.standardIngredient || '').trim();
      const standardIngredient = (
        it.standardIngredient ||
        it.ingrediente_estandar ||
        it.name ||
        it.producto ||
        ''
      ).trim();
      if (!name && !standardIngredient) continue;

      items.push({
        name: name || standardIngredient,
        standardIngredient: standardIngredient || name,
        brand: (it.brand || it.marca || 'Genérica').trim(),
        quantity: (it.quantity || it.cantidad || it.cantidad_estimada || '1 unidad').trim(),
        confidence: normalizeConfidence(it.confidence ?? it.confianza),
        isLocalBrand: Boolean(it.isLocalBrand ?? it.es_marca_local),
        category: (it.category || it.categoria || 'Varios').trim(),
        notes: it.notes || it.observaciones,
      });
    }

    return {
      summary: parsed.summary || parsed.resumen || 'Productos detectados en refrigerador / despensa',
      items,
    };
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

/**
 * Serverless function entrypoint for POST /api/detect-fridge
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({
      success: false,
      error: 'Método no permitido. Solo se acepta POST.',
      items: [],
    });
  }

  try {
    const body = (typeof req.body === 'string' ? JSON.parse(req.body) : req.body) || {};
    let rawImage = body.image;
    let mimeType = (body.mimeType || 'image/jpeg').trim().toLowerCase();

    if (!rawImage || typeof rawImage !== 'string' || rawImage.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No se proporcionó ninguna imagen. Se requiere un string en formato base64.',
        items: [],
      });
    }

    // Strip Data URI prefix if present (e.g., "data:image/jpeg;base64,....")
    const dataUriMatch = rawImage.match(/^data:([^;]+);base64,(.*)$/s);
    if (dataUriMatch) {
      mimeType = dataUriMatch[1].trim().toLowerCase();
      rawImage = dataUriMatch[2];
    }

    rawImage = rawImage.replace(/\s+/g, '');

    // Validate MIME type
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return res.status(400).json({
        success: false,
        error: `Formato de imagen no soportado (${mimeType}). Formatos admitidos: JPEG, PNG y WebP.`,
        items: [],
      });
    }

    // Approximate size calculation from base64 length: (len * 3 / 4)
    const approxBytes = Math.ceil((rawImage.length * 3) / 4);
    if (approxBytes > MAX_IMAGE_BYTES) {
      return res.status(413).json({
        success: false,
        error: 'La imagen excede el límite de tamaño permitido de 10 MB.',
        items: [],
      });
    }

    // Call Gemini 3.8 Flash
    const result = await analyzeFridgeWithGemini(rawImage, mimeType);

    return res.status(200).json({
      success: true,
      summary: result.summary,
      items: result.items,
    });
  } catch (error: unknown) {
    const errMessage = error instanceof Error ? error.message : String(error);
    const isTimeout =
      errMessage.includes('aborted') ||
      errMessage.includes('timeout') ||
      errMessage.includes('AbortError');

    console.error('[API /api/detect-fridge] Error:', errMessage);

    const status = isTimeout ? 504 : 500;
    const userMessage = isTimeout
      ? 'El análisis visual tardó demasiado tiempo en responder. Por favor intenta con una foto más ligera o añade tus ingredientes manualmente.'
      : 'Ocurrió un error al analizar la fotografía con el servicio de visión. Puedes reintentar o usar la entrada manual de ingredientes.';

    return res.status(status).json({
      success: false,
      error: userMessage,
      items: [],
    });
  }
}
