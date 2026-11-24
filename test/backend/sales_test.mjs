import test from 'node:test';
import assert from 'node:assert/strict';
import salesHandler, {
  CURATED_FALLBACK_DEALS,
  getSalesResponse,
  resetSalesMemoryCacheForTests,
} from '../../api/sales.ts';
import refreshHandler, {
  extractDealFromVtexProduct,
  isFoodProduct,
  scrapeAllSupermarkets,
} from '../../api/refresh-sales.ts';

function createMockReqRes(options = {}) {
  const req = {
    method: options.method || 'GET',
    url: options.url || '/api/sales',
    headers: options.headers || {},
    body: options.body || {},
  };

  const headers = {};
  let statusCode = 200;
  let responseData = null;

  const res = {
    statusCode,
    setHeader: (name, value) => {
      headers[name.toLowerCase()] = value;
    },
    status: (code) => {
      statusCode = code;
      res.statusCode = code;
      return res;
    },
    json: (data) => {
      responseData = data;
      return res;
    },
    end: () => res,
    _getData: () => responseData,
    _getStatus: () => statusCode,
    _getHeaders: () => headers,
  };

  return { req, res };
}

test('FEAT-5 /api/sales: responds 200 to OPTIONS for CORS', async () => {
  const { req, res } = createMockReqRes({ method: 'OPTIONS' });
  await salesHandler(req, res);
  assert.equal(res._getStatus(), 200);
  assert.equal(res._getHeaders()['access-control-allow-origin'], '*');
});

test('FEAT-5 /api/sales: rejects non-GET methods with 405', async () => {
  const { req, res } = createMockReqRes({ method: 'POST' });
  await salesHandler(req, res);
  assert.equal(res._getStatus(), 405);
  assert.equal(res._getData().success, false);
});

test('FEAT-5 /api/sales: falls back to curated GTQ deals when Blob snapshot is unavailable', async () => {
  resetSalesMemoryCacheForTests();
  const payload = await getSalesResponse({
    token: 'test-token',
    bypassMemoryCache: true,
    blobGet: async () => null,
  });

  assert.equal(payload.success, true);
  assert.equal(payload.sourceMode, 'fallback');
  assert.equal(payload.deals.length, CURATED_FALLBACK_DEALS.length);
  assert.ok(payload.deals.every((d) => d.salePriceGtq > 0 && d.regularPriceGtq > d.salePriceGtq));
});

test('FEAT-5 /api/sales: reads cached snapshot from Blob stream and caches in memory', async () => {
  resetSalesMemoryCacheForTests();
  let blobReads = 0;
  const mockSnapshot = {
    fetchedAt: '2026-11-24T12:00:00.000Z',
    deals: [
      {
        id: 'latorre-1',
        supermarketId: 'latorre',
        supermarketName: 'La Torre',
        productName: 'Milanesa Pollo Rey',
        brand: 'POLLO REY',
        category: 'Congelados',
        regularPriceGtq: 23.45,
        salePriceGtq: 17.55,
        discountPercent: 25,
        savingsGtq: 5.9,
        queryTerm: 'pollo',
        productUrl: 'https://www.latorre.com.gt/milanesa-pollo-rey/p',
      },
    ],
  };

  const mockBlobGet = async () => {
    blobReads += 1;
    const bytes = new TextEncoder().encode(JSON.stringify(mockSnapshot));
    const stream = new ReadableStream({
      start(controller) {
        controller.enqueue(bytes);
        controller.close();
      },
    });
    return {
      statusCode: 200,
      stream,
      headers: new Headers(),
      blob: {},
    };
  };

  const first = await getSalesResponse({
    token: 'test-token',
    blobGet: mockBlobGet,
  });
  assert.equal(first.sourceMode, 'live-cache');
  assert.equal(first.deals.length, 1);
  assert.equal(first.deals[0].productName, 'Milanesa Pollo Rey');
  assert.equal(blobReads, 1);

  const second = await getSalesResponse({
    token: 'test-token',
    blobGet: mockBlobGet,
  });
  assert.equal(second.sourceMode, 'live-cache');
  assert.equal(blobReads, 1);
});

test('FEAT-5 /api/refresh-sales: rejects unsupported methods with 405', async () => {
  const { req, res } = createMockReqRes({
    method: 'DELETE',
    url: '/api/refresh-sales',
  });
  await refreshHandler(req, res);
  assert.equal(res._getStatus(), 405);
});

test('FEAT-5 scraper: filters out non-food categories and zero-price items', () => {
  const store = {
    id: 'walmart',
    name: 'Walmart',
    baseUrl: 'https://www.walmart.com.gt',
  };

  const toothpaste = {
    productId: '1',
    productName: 'Pasta Dental Colgate',
    categories: ['/Higiene y Belleza/Cuidado Bucal/'],
    items: [{ sellers: [{ commertialOffer: { Price: 15, ListPrice: 21, AvailableQuantity: 100 } }] }],
  };
  assert.equal(isFoodProduct(toothpaste), false);
  assert.equal(extractDealFromVtexProduct(toothpaste, store, 'pasta'), null);

  const zeroPrice = {
    productId: '2',
    productName: 'Pollo Rostizado',
    categories: ['/Carnes/'],
    items: [{ sellers: [{ commertialOffer: { Price: 0, ListPrice: 0, AvailableQuantity: 0 } }] }],
  };
  assert.equal(extractDealFromVtexProduct(zeroPrice, store, 'pollo'), null);

  const valid = {
    productId: '3',
    productName: 'Frijol Negro Tierra Noble',
    brand: 'TIERRA NOBLE',
    link: '/frijol-negro/p',
    categories: ['/Abarrotes/Frijoles/'],
    items: [{ sellers: [{ commertialOffer: { Price: 38.4, ListPrice: 46.3, AvailableQuantity: 50 } }] }],
  };
  const extracted = extractDealFromVtexProduct(valid, store, 'frijol');
  assert.ok(extracted);
  assert.equal(extracted.salePriceGtq, 38.4);
  assert.equal(extracted.regularPriceGtq, 46.3);
  assert.equal(extracted.discountPercent, 17);
});

test('FEAT-5 scraper: handles HTTP errors gracefully without throwing', async () => {
  const snapshot = await scrapeAllSupermarkets(async () => ({
    ok: false,
    status: 403,
    json: async () => ({}),
  }));

  assert.equal(snapshot.deals.length, 0);
  assert.equal(snapshot.stores.length, 2);
  assert.ok(snapshot.stores.every((s) => s.ok === false));
});
