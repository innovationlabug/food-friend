import test from 'node:test';
import assert from 'node:assert/strict';
import handler from '../../api/detect-fridge.ts';

function createMockReqRes(options = {}) {
  const req = {
    method: options.method || 'POST',
    url: '/api/detect-fridge',
    headers: options.headers || { 'content-type': 'application/json' },
    body: options.body || {},
  };

  const headers = {};
  let statusCode = 200;
  let responseData = null;
  let ended = false;

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
      ended = true;
      return res;
    },
    end: () => {
      ended = true;
      return res;
    },
    _getData: () => responseData,
    _getStatus: () => statusCode,
    _getHeaders: () => headers,
  };

  return { req, res };
}

test('US-3.1 detect-fridge: responds 200 to OPTIONS for CORS', async () => {
  const { req, res } = createMockReqRes({ method: 'OPTIONS' });
  await handler(req, res);
  assert.equal(res._getStatus(), 200);
  assert.equal(res._getHeaders()['access-control-allow-origin'], '*');
});

test('US-3.1 detect-fridge: rejects non-POST methods with 405', async () => {
  const { req, res } = createMockReqRes({ method: 'GET' });
  await handler(req, res);
  assert.equal(res._getStatus(), 405);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /Solo se acepta POST/);
});

test('US-3.1 detect-fridge: rejects missing image with 400', async () => {
  const { req, res } = createMockReqRes({ method: 'POST', body: {} });
  await handler(req, res);
  assert.equal(res._getStatus(), 400);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /No se proporcionó ninguna imagen/);
});

test('US-3.1 detect-fridge: rejects invalid mime-type with 400', async () => {
  const { req, res } = createMockReqRes({
    method: 'POST',
    body: {
      image: 'aW1hZ2VkYXRh',
      mimeType: 'application/pdf',
    },
  });
  await handler(req, res);
  assert.equal(res._getStatus(), 400);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /Formato de imagen no soportado/);
});

test('US-3.1 detect-fridge: rejects oversized image > 10MB with 413', async () => {
  // 14MB base64 string corresponds to ~10.5 MB binary
  const oversizedBase64 = 'A'.repeat(14 * 1024 * 1024);
  const { req, res } = createMockReqRes({
    method: 'POST',
    body: {
      image: oversizedBase64,
      mimeType: 'image/jpeg',
    },
  });
  await handler(req, res);
  assert.equal(res._getStatus(), 413);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /excede el límite de tamaño permitido de 10 MB/);
});

