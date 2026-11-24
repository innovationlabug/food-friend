import type { VercelRequest, VercelResponse } from '@vercel/node';
import { get } from '@vercel/blob';
import fs from 'node:fs';
import path from 'node:path';

export interface SupermarketDealRecord {
  id: string;
  supermarketId: string;
  supermarketName: string;
  productName: string;
  brand: string;
  category: string;
  regularPriceGtq: number;
  salePriceGtq: number;
  discountPercent: number;
  savingsGtq: number;
  queryTerm: string;
  productUrl: string;
}

export interface SalesSnapshotResponse {
  success: boolean;
  sourceMode: 'live-cache' | 'fallback';
  fetchedAt: string;
  deals: SupermarketDealRecord[];
}

export const CURATED_FALLBACK_DEALS: SupermarketDealRecord[] = [
  {
    id: 'fallback-latorre-pollo-1',
    supermarketId: 'latorre',
    supermarketName: 'La Torre',
    productName: 'Milanesa Pollo Rey',
    brand: 'POLLO REY',
    category: 'Congelados y Helados / Empanizados',
    regularPriceGtq: 23.45,
    salePriceGtq: 17.55,
    discountPercent: 25,
    savingsGtq: 5.9,
    queryTerm: 'pollo',
    productUrl: 'https://www.latorre.com.gt/milanesa-pollo-rey/p',
  },
  {
    id: 'fallback-walmart-aceite-1',
    supermarketId: 'walmart',
    supermarketName: 'Walmart',
    productName: 'Aceite de Oliva Great Value Extra Virgen - 502 ml',
    brand: 'GREAT VALUE',
    category: 'Abarrotes / Aceites de cocina',
    regularPriceGtq: 36.25,
    salePriceGtq: 18.13,
    discountPercent: 50,
    savingsGtq: 18.12,
    queryTerm: 'aceite',
    productUrl: 'https://www.walmart.com.gt/aceite-de-oliva-great-value/p',
  },
  {
    id: 'fallback-latorre-arroz-1',
    supermarketId: 'latorre',
    supermarketName: 'La Torre',
    productName: 'Arroz Precocido Primavera Gallo Dorado',
    brand: 'GALLO DORADO',
    category: 'Abarrotes / Granos',
    regularPriceGtq: 19.5,
    salePriceGtq: 15.6,
    discountPercent: 20,
    savingsGtq: 3.9,
    queryTerm: 'arroz',
    productUrl: 'https://www.latorre.com.gt/arroz-precocido-gallo-dorado/p',
  },
  {
    id: 'fallback-walmart-frijol-1',
    supermarketId: 'walmart',
    supermarketName: 'Walmart',
    productName: 'Frijol negro La Chula volteados - 1000 g',
    brand: 'LA CHULA',
    category: 'Abarrotes / Frijoles',
    regularPriceGtq: 12.8,
    salePriceGtq: 11.0,
    discountPercent: 14,
    savingsGtq: 1.8,
    queryTerm: 'frijol',
    productUrl: 'https://www.walmart.com.gt/frijol-negro-la-chula-1000g/p',
  },
  {
    id: 'fallback-latorre-queso-1',
    supermarketId: 'latorre',
    supermarketName: 'La Torre',
    productName: 'Queso Mozarella Lactolac',
    brand: 'LACTOLAC',
    category: 'Quesos y Embutidos / Quesos',
    regularPriceGtq: 36.0,
    salePriceGtq: 24.9,
    discountPercent: 31,
    savingsGtq: 11.1,
    queryTerm: 'queso',
    productUrl: 'https://www.latorre.com.gt/queso-mozarella-lactolac/p',
  },
  {
    id: 'fallback-walmart-queso-1',
    supermarketId: 'walmart',
    supermarketName: 'Walmart',
    productName: 'Queso Trebolac Panela - 220 g',
    brand: 'TREBOLAC',
    category: 'Lácteos / Queso Fresco',
    regularPriceGtq: 25.0,
    salePriceGtq: 20.5,
    discountPercent: 18,
    savingsGtq: 4.5,
    queryTerm: 'queso',
    productUrl: 'https://www.walmart.com.gt/queso-trebolac-panela-220g/p',
  },
  {
    id: 'fallback-walmart-leche-1',
    supermarketId: 'walmart',
    supermarketName: 'Walmart',
    productName: 'Leche Semidescremada Dos Pinos Delactomy 3 Pack',
    brand: 'DOS PINOS',
    category: 'Lácteos / Leche',
    regularPriceGtq: 57.0,
    salePriceGtq: 47.5,
    discountPercent: 17,
    savingsGtq: 9.5,
    queryTerm: 'leche',
    productUrl: 'https://www.walmart.com.gt/leche-dos-pinos-delactomy-3pack/p',
  },
  {
    id: 'fallback-latorre-huevo-1',
    supermarketId: 'latorre',
    supermarketName: 'La Torre',
    productName: 'Huevos Blancos Guatehuevo (Cartón 30 uds)',
    brand: 'GUATEHUEVO',
    category: 'Leches, Huevos y Derivados',
    regularPriceGtq: 85.6,
    salePriceGtq: 76.9,
    discountPercent: 10,
    savingsGtq: 8.7,
    queryTerm: 'huevo',
    productUrl: 'https://www.latorre.com.gt/huevos-blancos-guatehuevo/p',
  },
  {
    id: 'fallback-latorre-atun-1',
    supermarketId: 'latorre',
    supermarketName: 'La Torre',
    productName: 'Atún Agua Lomo Trozos Costa Brava',
    brand: 'COSTA BRAVA',
    category: 'Abarrotes / Atún',
    regularPriceGtq: 15.35,
    salePriceGtq: 10.7,
    discountPercent: 30,
    savingsGtq: 4.65,
    queryTerm: 'atun',
    productUrl: 'https://www.latorre.com.gt/atun-agua-costa-brava/p',
  },
  {
    id: 'fallback-walmart-tomate-1',
    supermarketId: 'walmart',
    supermarketName: 'Walmart',
    productName: 'Tomate Killios Pelado Entero - 800 g',
    brand: 'KILLIOS',
    category: 'Abarrotes / Vegetales Enlatados',
    regularPriceGtq: 25.95,
    salePriceGtq: 20.0,
    discountPercent: 23,
    savingsGtq: 5.95,
    queryTerm: 'tomate',
    productUrl: 'https://www.walmart.com.gt/tomate-killios-pelado-800g/p',
  },
];

const BLOB_PATHNAME = 'sales-snapshot.json';
const MEMORY_TTL_MS = 15 * 60 * 1000;

let memoryCache: { expiresAt: number; payload: SalesSnapshotResponse } | null = null;

function readEnvValue(key: string): string | undefined {
  const fromEnv = process.env[key];
  if (fromEnv && fromEnv.trim().length > 0) {
    return fromEnv.trim().replace(/^["']|["']$/g, '');
  }
  try {
    const envPath = path.resolve(process.cwd(), '.env.local');
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf8');
      const regex = new RegExp(`^${key}=([^\\r\\n]+)`, 'm');
      const match = content.match(regex);
      if (match && match[1]) {
        return match[1].trim().replace(/^["']|["']$/g, '');
      }
    }
  } catch {
    // Ignore local .env.local read errors
  }
  return undefined;
}

async function readStreamText(stream: ReadableStream<Uint8Array>): Promise<string> {
  const reader = stream.getReader();
  const chunks: Uint8Array[] = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    if (value) chunks.push(value);
  }
  return Buffer.concat(chunks.map((c) => Buffer.from(c))).toString('utf8');
}

export async function readSnapshotFromBlob(
  token: string,
  blobGet: typeof get = get
): Promise<{ fetchedAt: string; deals: SupermarketDealRecord[] } | null> {
  for (const access of ['public', 'private'] as const) {
    try {
      const result = await blobGet(BLOB_PATHNAME, {
        access,
        token,
        abortSignal: AbortSignal.timeout(4000),
      });
      if (!result || result.statusCode !== 200 || !result.stream) {
        continue;
      }
      const raw = await readStreamText(result.stream);
      const parsed = JSON.parse(raw) as {
        fetchedAt?: string;
        deals?: SupermarketDealRecord[];
      };
      if (Array.isArray(parsed.deals) && parsed.deals.length > 0) {
        return {
          fetchedAt: parsed.fetchedAt || new Date().toISOString(),
          deals: parsed.deals,
        };
      }
    } catch {
      // Try next access mode or fall back cleanly
    }
  }
  return null;
}

export function resetSalesMemoryCacheForTests(): void {
  memoryCache = null;
}

/**
 * Serves cached supermarket sales in GTQ from Vercel Blob without triggering
 * live scraping on client requests, falling back to curated GTQ deals if
 * Blob is unavailable or uninitialized.
 */
export async function getSalesResponse(options?: {
  token?: string;
  blobGet?: typeof get;
  bypassMemoryCache?: boolean;
}): Promise<SalesSnapshotResponse> {
  if (!options?.bypassMemoryCache && memoryCache && Date.now() < memoryCache.expiresAt) {
    return memoryCache.payload;
  }

  const token = options?.token ?? readEnvValue('BLOB_READ_WRITE_TOKEN');
  if (token) {
    const blobSnapshot = await readSnapshotFromBlob(token, options?.blobGet);
    if (blobSnapshot) {
      const payload: SalesSnapshotResponse = {
        success: true,
        sourceMode: 'live-cache',
        fetchedAt: blobSnapshot.fetchedAt,
        deals: blobSnapshot.deals,
      };
      memoryCache = {
        expiresAt: Date.now() + MEMORY_TTL_MS,
        payload,
      };
      return payload;
    }
  }

  return {
    success: true,
    sourceMode: 'fallback',
    fetchedAt: new Date().toISOString(),
    deals: CURATED_FALLBACK_DEALS,
  };
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ success: false, error: 'Solo se acepta GET' });
  }

  try {
    const payload = await getSalesResponse();
    res.setHeader(
      'Cache-Control',
      'public, s-maxage=3600, stale-while-revalidate=86400'
    );
    return res.status(200).json(payload);
  } catch {
    return res.status(200).json({
      success: true,
      sourceMode: 'fallback',
      fetchedAt: new Date().toISOString(),
      deals: CURATED_FALLBACK_DEALS,
    });
  }
}
