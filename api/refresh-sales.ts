import type { VercelRequest, VercelResponse } from '@vercel/node';
import { put } from '@vercel/blob';
import fs from 'node:fs';
import path from 'node:path';

/**
 * Normalized supermarket deal payload stored in Vercel Blob and served by /api/sales.
 */
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

export interface StoreScrapeSummary {
  storeId: string;
  storeName: string;
  ok: boolean;
  scannedProducts: number;
  dealsFound: number;
  latencyMs: number;
  error?: string;
}

export interface SalesSnapshotPayload {
  fetchedAt: string;
  deals: SupermarketDealRecord[];
  stores: StoreScrapeSummary[];
}

interface SupermarketConfig {
  id: string;
  name: string;
  baseUrl: string;
}

const SUPERMARKETS: SupermarketConfig[] = [
  { id: 'latorre', name: 'La Torre', baseUrl: 'https://www.latorre.com.gt' },
  { id: 'walmart', name: 'Walmart', baseUrl: 'https://www.walmart.com.gt' },
];

const STAPLE_INGREDIENT_QUERIES = [
  'pollo',
  'arroz',
  'frijol',
  'leche',
  'queso',
  'aceite',
  'huevo',
  'tomate',
  'atun',
  'cebolla',
  'papa',
  'avena',
];

const NON_FOOD_CATEGORY_PREFIXES = [
  '/higiene',
  '/cuidado personal',
  '/ropa',
  '/autos',
  '/limpieza',
  '/artículos para el hogar',
  '/articulos para el hogar',
  '/mascotas',
  '/electrónica',
  '/electronica',
  '/juguetería',
  '/jugueteria',
  '/ferretería',
  '/ferreteria',
  '/librería',
  '/libreria',
  '/farmacia',
  '/deportes',
  '/cervezas, vinos y licores',
  '/bebés',
];

const NON_FOOD_NAME_TERMS = [
  'pasta dental',
  'cepillo',
  'jabon',
  'jabón',
  'shampoo',
  'acondicionador',
  'mascarilla revitalizante',
  'desodorante',
  'detergente',
  'suavizante',
  'cloro',
  'papel higienico',
  'papel higiénico',
  'toalla sanitaria',
  'pañal',
  'alimento para perro',
  'alimento para gato',
  'arena para gato',
];

const BLOB_PATHNAME = 'sales-snapshot.json';

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

function normalizeText(value: string): string {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}

interface VtexProductLike {
  productId?: string;
  productName?: string;
  brand?: string;
  link?: string;
  linkText?: string;
  categories?: string[];
  priceRange?: {
    sellingPrice?: { lowPrice?: number };
    listPrice?: { highPrice?: number };
  };
  items?: Array<{
    itemId?: string;
    sellers?: Array<{
      commertialOffer?: {
        Price?: number;
        ListPrice?: number;
        AvailableQuantity?: number;
      };
    }>;
  }>;
}

export function isFoodProduct(product: VtexProductLike): boolean {
  const categories = Array.isArray(product.categories) ? product.categories : [];
  for (const rawCategory of categories) {
    const lower = String(rawCategory || '').toLowerCase().trim();
    if (NON_FOOD_CATEGORY_PREFIXES.some((prefix) => lower.startsWith(prefix))) {
      return false;
    }
  }

  const normalizedName = normalizeText(String(product.productName || ''));
  return !NON_FOOD_NAME_TERMS.some((term) =>
    normalizedName.includes(normalizeText(term))
  );
}

export function extractDealFromVtexProduct(
  product: VtexProductLike,
  store: SupermarketConfig,
  queryTerm: string
): SupermarketDealRecord | null {
  if (!product || !isFoodProduct(product)) {
    return null;
  }

  const firstItem = Array.isArray(product.items) ? product.items[0] : undefined;
  const offer = firstItem?.sellers?.[0]?.commertialOffer;

  const salePrice = Number(
    offer?.Price ?? product.priceRange?.sellingPrice?.lowPrice ?? 0
  );
  const listPrice = Number(
    offer?.ListPrice ?? product.priceRange?.listPrice?.highPrice ?? 0
  );
  const availableQty = Number(offer?.AvailableQuantity ?? 1);

  if (
    !Number.isFinite(salePrice) ||
    !Number.isFinite(listPrice) ||
    salePrice <= 0 ||
    listPrice <= salePrice ||
    availableQty <= 0
  ) {
    return null;
  }

  const savings = roundCurrency(listPrice - salePrice);
  const discountPercent = Math.round(((listPrice - salePrice) / listPrice) * 100);
  if (discountPercent < 3 || savings < 0.25) {
    return null;
  }

  const category = Array.isArray(product.categories) && product.categories.length > 0
    ? String(product.categories[0])
        .split('/')
        .map((s) => s.trim())
        .filter(Boolean)
        .slice(0, 2)
        .join(' / ') || 'Supermercado'
    : 'Supermercado';

  let productUrl = store.baseUrl;
  if (product.link && product.link.startsWith('http')) {
    productUrl = product.link;
  } else if (product.link && product.link.startsWith('/')) {
    productUrl = `${store.baseUrl}${product.link}`;
  } else if (product.linkText) {
    productUrl = `${store.baseUrl}/${product.linkText}/p`;
  }

  const rawId = product.productId || firstItem?.itemId || product.linkText || product.productName || '';
  return {
    id: `${store.id}-${String(rawId).replace(/[^a-zA-Z0-9_-]/g, '')}`,
    supermarketId: store.id,
    supermarketName: store.name,
    productName: String(product.productName || '').trim(),
    brand: String(product.brand || 'Genérico').trim(),
    category,
    regularPriceGtq: roundCurrency(listPrice),
    salePriceGtq: roundCurrency(salePrice),
    discountPercent,
    savingsGtq: savings,
    queryTerm,
    productUrl,
  };
}

async function scrapeStore(
  store: SupermarketConfig,
  fetchImpl: typeof fetch
): Promise<{ deals: SupermarketDealRecord[]; summary: StoreScrapeSummary }> {
  const startedAt = Date.now();
  const seenKeys = new Set<string>();
  const deals: SupermarketDealRecord[] = [];
  let scannedProducts = 0;
  let successfulQueries = 0;
  let lastError: string | undefined;

  for (const queryTerm of STAPLE_INGREDIENT_QUERIES) {
    const url = `${store.baseUrl}/api/io/_v/api/intelligent-search/product_search/?query=${encodeURIComponent(queryTerm)}&count=12&page=1&hideUnavailableItems=true`;
    try {
      const response = await fetchImpl(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
          Accept: 'application/json',
          'Accept-Language': 'es-GT,es;q=0.9',
        },
        signal: AbortSignal.timeout(8000),
      });

      if (!response.ok) {
        lastError = `HTTP ${response.status} en "${queryTerm}"`;
        continue;
      }

      const payload = (await response.json()) as { products?: VtexProductLike[] };
      const products = Array.isArray(payload.products) ? payload.products : [];
      scannedProducts += products.length;
      successfulQueries += 1;

      for (const product of products) {
        const deal = extractDealFromVtexProduct(product, store, queryTerm);
        if (!deal) continue;
        const dedupeKey = `${deal.supermarketId}:${normalizeText(deal.productName)}`;
        if (seenKeys.has(dedupeKey)) continue;
        seenKeys.add(dedupeKey);
        deals.push(deal);
      }
    } catch (err) {
      lastError = err instanceof Error ? err.message : 'Error de red';
    }
  }

  return {
    deals,
    summary: {
      storeId: store.id,
      storeName: store.name,
      ok: successfulQueries > 0,
      scannedProducts,
      dealsFound: deals.length,
      latencyMs: Date.now() - startedAt,
      ...(successfulQueries === 0 && lastError ? { error: lastError } : {}),
    },
  };
}

export async function scrapeAllSupermarkets(
  fetchImpl: typeof fetch = globalThis.fetch
): Promise<SalesSnapshotPayload> {
  const results = await Promise.all(
    SUPERMARKETS.map((store) => scrapeStore(store, fetchImpl))
  );

  const deals = results
    .flatMap((r) => r.deals)
    .sort((a, b) => b.discountPercent - a.discountPercent || b.savingsGtq - a.savingsGtq);

  return {
    fetchedAt: new Date().toISOString(),
    deals,
    stores: results.map((r) => r.summary),
  };
}

async function writeSnapshotToBlob(
  snapshot: SalesSnapshotPayload,
  token: string
): Promise<string> {
  const body = JSON.stringify(snapshot);
  try {
    const result = await put(BLOB_PATHNAME, body, {
      access: 'public',
      addRandomSuffix: false,
      allowOverwrite: true,
      contentType: 'application/json',
      token,
    });
    return result.url;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    if (message.toLowerCase().includes('private') || message.toLowerCase().includes('access')) {
      const result = await put(BLOB_PATHNAME, body, {
        access: 'private',
        addRandomSuffix: false,
        allowOverwrite: true,
        contentType: 'application/json',
        token,
      });
      return result.url;
    }
    throw err;
  }
}

/**
 * Scheduled / manual backend endpoint to refresh supermarket sales and persist
 * the normalized GTQ snapshot into Vercel Blob (`sales-snapshot.json`).
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET' && req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Solo se acepta GET o POST' });
  }

  const cronSecret = readEnvValue('CRON_SECRET');
  if (cronSecret) {
    const authHeader = String(req.headers.authorization || '');
    if (authHeader !== `Bearer ${cronSecret}`) {
      return res.status(401).json({ success: false, error: 'No autorizado' });
    }
  }

  try {
    const snapshot = await scrapeAllSupermarkets();
    const blobToken = readEnvValue('BLOB_READ_WRITE_TOKEN');

    if (snapshot.deals.length === 0) {
      return res.status(200).json({
        success: false,
        persisted: false,
        message: 'No se obtuvieron ofertas en vivo; se mantiene el snapshot previo o respaldo.',
        stores: snapshot.stores,
      });
    }

    let blobUrl: string | null = null;
    if (blobToken) {
      blobUrl = await writeSnapshotToBlob(snapshot, blobToken);
    }

    return res.status(200).json({
      success: true,
      persisted: Boolean(blobUrl),
      blobUrl,
      fetchedAt: snapshot.fetchedAt,
      dealsCount: snapshot.deals.length,
      stores: snapshot.stores,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Error al actualizar ofertas';
    return res.status(500).json({ success: false, error: message });
  }
}
