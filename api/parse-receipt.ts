import type { VercelRequest, VercelResponse } from '@vercel/node';
import fs from 'node:fs';
import path from 'node:path';

/**
 * Permitted confidence levels for parsed food items.
 */
export type ConfidenceLevel = 'high' | 'medium' | 'low';

/**
 * Structured food item extracted from a supermarket receipt.
 */
export interface ReceiptFoodItem {
  rawName: string;
  standardIngredient: string;
  brand: string;
  category: string;
  quantity: string;
  unitCount: number;
  priceGtq?: number;
  totalPriceGtq?: number;
  confidence: ConfidenceLevel;
}

/**
 * Response payload for the receipt parser endpoint.
 */
export interface ParseReceiptResponse {
  success: boolean;
  supermarket?: string;
  date?: string;
  totalFacturaGtq?: number;
  totalAlimentosGtq?: number;
  summary?: string;
  items: ReceiptFoodItem[];
  error?: string;
}

/**
 * Common POS (Point-of-Sale) abbreviations used by Guatemalan supermarkets
 * (Walmart Guatemala, Paiz, Despensa Familiar, Maxi Despensa, La Torre, Super del Barrio).
 */
export const GUATEMALA_POS_ABBREVIATIONS: Record<string, string> = {
  'AR/BLA': 'Arroz blanco',
  'AR/PREC': 'Arroz precocido',
  'FJOL/NG': 'Frijol negro',
  'FJOL/VOLT': 'Frijoles volteados',
  'FJOL/PAR': 'Frijoles parados',
  'ACTE/VEG': 'Aceite vegetal',
  'ACTE/OLIV': 'Aceite de oliva',
  'CH/MEIN': 'Fideos chow mein',
  'JAM/FAM': 'Jamón familiar',
  'CHOR/COL': 'Chorizo colorado',
  'SALCH/HOT': 'Salchicha para hot dog',
  'CONS/RES': 'Consomé de res',
  'CONS/POL': 'Consomé de pollo',
  'HAR/MAIZ': 'Harina de maíz',
  'HAR/TRIGO': 'Harina de trigo',
  'LECH/ENT': 'Leche entera',
  'LECH/DESM': 'Leche descremada',
  'CREM/PUR': 'Crema pura de vaca',
  'QUES/CAP': 'Queso de capas',
  'QUES/FRES': 'Queso fresco',
  'MANZ/ROJ': 'Manzana roja',
  'PLAT/MAD': 'Plátano maduro',
  'PAPA/LAV': 'Papa lavada',
  'TOM/MANZ': 'Tomate manzano',
  'CEB/BLA': 'Cebolla blanca',
  'CEB/MOR': 'Cebolla morada',
  'ZANAH/GR': 'Zanahoria',
  'GÜISQ/VER': 'Güisquil verde',
  'PECH/DESH': 'Pechuga deshuesada de pollo',
  'CARN/MOL': 'Carne molida de res',
  'FILET/TIL': 'Filete de tilapia',
  'HUEV/BLA': 'Huevos blancos',
  'HUEV/GRA': 'Huevos de granja',
  'AZUC/BLA': 'Azúcar blanca',
  'SAL/REF': 'Sal refinada',
};

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
 * Normalizes confidence string to strictly 'high' | 'medium' | 'low'.
 */
function normalizeConfidence(raw: unknown): ConfidenceLevel {
  if (typeof raw === 'number') {
    if (raw >= 0.85) return 'high';
    if (raw <= 0.6) return 'low';
    return 'medium';
  }
  if (typeof raw !== 'string') return 'medium';
  const lower = raw.trim().toLowerCase();
  if (lower === 'high' || lower === 'alta' || lower === 'alto') return 'high';
  if (lower === 'low' || lower === 'baja' || lower === 'bajo') return 'low';
  return 'medium';
}

/**
 * System instruction tuned for Guatemalan supermarket receipt OCR and POS abbreviations.
 */
const RECEIPT_SYSTEM_INSTRUCTION = `Eres un asistente experto en digitalización y extracción de comprobantes de pago, facturas y tickets de supermercados en Guatemala (Walmart, Paiz, Despensa Familiar, Maxi Despensa, Supermercados La Torre, Super del Barrio, etc.) para la aplicación Food Friend.

Tu misión:
1. Extraer el nombre del supermercado/tienda y totales en Quetzales (GTQ / Q).
2. Leer cada línea e interpretar las abreviaturas POS guatemaltecas habituales:
${Object.entries(GUATEMALA_POS_ABBREVIATIONS)
  .map(([k, v]) => `   - "${k}" => "${v}"`)
  .join('\n')}
3. Clasificar con precisión si el ítem es comestible / ingrediente de cocina ("isFood": true) o si es un producto no alimenticio como limpieza, detergente, jabón, fósforos, toallas húmedas, papel higiénico, cuidado personal ("isFood": false).
4. Mapear cada alimento a un nombre canónico y limpio ("standardIngredient") para la despensa del usuario (ej. "Arroz blanco", "Frijol negro", "Aceite vegetal", "Jamón", "Chorizo", "Crema", "Fideos chow mein", "Queso procesado", "Sal refinada").
5. Extraer precios en Quetzales (Q).
Devuelve siempre información estructurada en JSON estricto.`;

const RECEIPT_PROMPT_TEXT = `Analiza detalladamente esta fotografía de un recibo o ticket de supermercado de Guatemala.
Extrae la información en un JSON con:
- "supermarket": Nombre de la tienda o supermercado.
- "date": Fecha/hora si es legible.
- "totalFacturaGtq": Total general del ticket en Quetzales (número decimal).
- "totalAlimentosGtq": Suma de alimentos/ingredientes en Quetzales (número decimal).
- "summary": Breve resumen en español del ticket.
- "items": Lista completa de productos visibles. Para cada producto:
  * "rawName": Texto tal como aparece impreso en el recibo.
  * "standardIngredient": Nombre estandarizado y limpio del ingrediente en español para cocinar.
  * "brand": Marca del producto (o "Genérica").
  * "category": Categoría culinaria en español.
  * "quantity": Cantidad o peso (ej. "400 g", "1 lb", "750 ml", "1 unidad").
  * "unitCount": Número entero de unidades compradas (normalmente 1).
  * "priceGtq": Precio unitario en Quetzales (número decimal o null).
  * "totalPriceGtq": Precio total pagado por esa línea en Quetzales.
  * "isFood": booleano (true si es ingrediente/comida apto para despensa/cocina, false si es artículo de limpieza, papel, fósforos, etc.).
  * "confidence": "high", "medium" o "low".`;

/**
 * Calls Gemini 3.8 Flash Vision to parse the receipt.
 */
async function parseReceiptWithGemini(
  base64Data: string,
  mimeType: string
): Promise<{
  supermarket?: string;
  date?: string;
  totalFacturaGtq?: number;
  totalAlimentosGtq?: number;
  summary?: string;
  items: ReceiptFoodItem[];
}> {
  const apiKey = getGeminiApiKey();
  if (!apiKey) {
    throw new Error('No se encontró GEMINI_API_KEY configurada en el servidor.');
  }

  const model = process.env.GEMINI_MODEL || 'gemini-3.8-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const payload = {
    system_instruction: {
      parts: [{ text: RECEIPT_SYSTEM_INSTRUCTION }],
    },
    contents: [
      {
        parts: [
          { text: RECEIPT_PROMPT_TEXT },
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
      temperature: 0.2,
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
      throw new Error(`Gemini Receipt Vision devolvió código HTTP ${res.status}`);
    }

    const data = (await res.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };
    const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawText) {
      throw new Error('La respuesta de Gemini no contiene candidatos de texto.');
    }

    const parsed = JSON.parse(rawText) as {
      supermarket?: string;
      supermercado?: string;
      date?: string;
      fecha?: string;
      totalFacturaGtq?: number;
      total_factura_gtq?: number;
      totalAlimentosGtq?: number;
      total_alimentos_gtq?: number;
      summary?: string;
      resumen?: string;
      items?: Array<{
        rawName?: string;
        nombre_ticket?: string;
        standardIngredient?: string;
        ingrediente_estandar?: string;
        brand?: string;
        marca?: string;
        category?: string;
        categoria?: string;
        quantity?: string;
        cantidad_o_peso?: string;
        unitCount?: number;
        unidades?: number;
        priceGtq?: number;
        precio_unitario_gtq?: number;
        totalPriceGtq?: number;
        precio_total_gtq?: number;
        isFood?: boolean;
        es_alimento?: boolean;
        confidence?: unknown;
        confianza?: unknown;
      }>;
    };

    const rawItems = parsed.items || [];
    // 1. Filter out non-food household items
    const foodCandidates = rawItems.filter((it) => {
      const isFood = it.isFood ?? it.es_alimento ?? true;
      return Boolean(isFood);
    });

    // 2. Consolidate duplicate receipt lines by standard ingredient
    const consolidatedMap = new Map<string, ReceiptFoodItem>();

    for (const it of foodCandidates) {
      const standardIngredient = (
        it.standardIngredient ||
        it.ingrediente_estandar ||
        it.rawName ||
        it.nombre_ticket ||
        ''
      ).trim();
      if (!standardIngredient) continue;

      const rawName = (it.rawName || it.nombre_ticket || standardIngredient).trim();
      const brand = (it.brand || it.marca || 'Genérica').trim();
      const category = (it.category || it.categoria || 'Abarrotes').trim();
      const quantity = (it.quantity || it.cantidad_o_peso || '1 unidad').trim();
      const unitCount = typeof it.unitCount === 'number' ? it.unitCount : typeof it.unidades === 'number' ? it.unidades : 1;
      const priceGtq = typeof it.priceGtq === 'number' ? it.priceGtq : typeof it.precio_unitario_gtq === 'number' ? it.precio_unitario_gtq : undefined;
      const totalPriceGtq = typeof it.totalPriceGtq === 'number' ? it.totalPriceGtq : typeof it.precio_total_gtq === 'number' ? it.precio_total_gtq : priceGtq;
      const confidence = normalizeConfidence(it.confidence ?? it.confianza);

      const key = standardIngredient.toLowerCase();
      if (consolidatedMap.has(key)) {
        const existing = consolidatedMap.get(key)!;
        existing.unitCount += unitCount;
        if (existing.totalPriceGtq && totalPriceGtq) {
          existing.totalPriceGtq = Number((existing.totalPriceGtq + totalPriceGtq).toFixed(2));
        }
      } else {
        consolidatedMap.set(key, {
          rawName,
          standardIngredient,
          brand,
          category,
          quantity,
          unitCount,
          priceGtq,
          totalPriceGtq,
          confidence,
        });
      }
    }

    const items = Array.from(consolidatedMap.values());

    return {
      supermarket: parsed.supermarket || parsed.supermercado || 'Supermercado de Guatemala',
      date: parsed.date || parsed.fecha,
      totalFacturaGtq: parsed.totalFacturaGtq ?? parsed.total_factura_gtq,
      totalAlimentosGtq: parsed.totalAlimentosGtq ?? parsed.total_alimentos_gtq,
      summary: parsed.summary || parsed.resumen || 'Comprobante de compra analizado con éxito.',
      items,
    };
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

/**
 * Serverless function entrypoint for POST /api/parse-receipt
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS headers
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
        error: 'No se proporcionó ninguna imagen del recibo. Se requiere base64.',
        items: [],
      });
    }

    // Strip Data URI prefix if present
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

    // Check size limit
    const approxBytes = Math.ceil((rawImage.length * 3) / 4);
    if (approxBytes > MAX_IMAGE_BYTES) {
      return res.status(413).json({
        success: false,
        error: 'La imagen del recibo excede el límite permitido de 10 MB.',
        items: [],
      });
    }

    const result = await parseReceiptWithGemini(rawImage, mimeType);

    return res.status(200).json({
      success: true,
      supermarket: result.supermarket,
      date: result.date,
      totalFacturaGtq: result.totalFacturaGtq,
      totalAlimentosGtq: result.totalAlimentosGtq,
      summary: result.summary,
      items: result.items,
    });
  } catch (error: unknown) {
    const errMessage = error instanceof Error ? error.message : String(error);
    const isTimeout =
      errMessage.includes('aborted') ||
      errMessage.includes('timeout') ||
      errMessage.includes('AbortError');

    console.error('[API /api/parse-receipt] Error:', errMessage);

    const status = isTimeout ? 504 : 500;
    const userMessage = isTimeout
      ? 'La lectura del recibo tardó demasiado tiempo. Por favor intenta con una foto más clara o ingresa tus ingredientes manualmente.'
      : 'Ocurrió un error al procesar el recibo de supermercado. Puedes reintentar con otra foto o agregar tus ingredientes manualmente.';

    return res.status(status).json({
      success: false,
      error: userMessage,
      items: [],
    });
  }
}
