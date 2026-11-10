import test from 'node:test';
import assert from 'node:assert/strict';
import handler, { GUATEMALA_POS_ABBREVIATIONS } from '../../api/parse-receipt.ts';

function createMockReqRes(options = {}) {
  const req = {
    method: options.method || 'POST',
    url: '/api/parse-receipt',
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

test('US-3.3 parse-receipt: POS abbreviations dictionary includes essential Guatemalan staples', () => {
  assert.equal(GUATEMALA_POS_ABBREVIATIONS['AR/BLA'], 'Arroz blanco');
  assert.equal(GUATEMALA_POS_ABBREVIATIONS['FJOL/NG'], 'Frijol negro');
  assert.equal(GUATEMALA_POS_ABBREVIATIONS['ACTE/VEG'], 'Aceite vegetal');
  assert.equal(GUATEMALA_POS_ABBREVIATIONS['CH/MEIN'], 'Fideos chow mein');
  assert.equal(GUATEMALA_POS_ABBREVIATIONS['JAM/FAM'], 'Jamón familiar');
  assert.equal(GUATEMALA_POS_ABBREVIATIONS['QUES/CAP'], 'Queso de capas');
});

test('US-3.3 parse-receipt: responds 200 to OPTIONS for CORS', async () => {
  const { req, res } = createMockReqRes({ method: 'OPTIONS' });
  await handler(req, res);
  assert.equal(res._getStatus(), 200);
  assert.equal(res._getHeaders()['access-control-allow-origin'], '*');
});

test('US-3.3 parse-receipt: rejects non-POST methods with 405', async () => {
  const { req, res } = createMockReqRes({ method: 'GET' });
  await handler(req, res);
  assert.equal(res._getStatus(), 405);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /Solo se acepta POST/);
});

test('US-3.3 parse-receipt: rejects missing receipt image with 400', async () => {
  const { req, res } = createMockReqRes({ method: 'POST', body: {} });
  await handler(req, res);
  assert.equal(res._getStatus(), 400);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /No se proporcionó ninguna imagen del recibo/);
});

test('US-3.3 parse-receipt: rejects invalid mime-type with 400', async () => {
  const { req, res } = createMockReqRes({
    method: 'POST',
    body: {
      image: 'cmVjZWlwdGRhdGE=',
      mimeType: 'text/html',
    },
  });
  await handler(req, res);
  assert.equal(res._getStatus(), 400);
  const data = res._getData();
  assert.equal(data.success, false);
  assert.match(data.error, /Formato de imagen no soportado/);
});

test('US-3.3 parse-receipt: rejects oversized image > 10MB with 413', async () => {
  const oversizedBase64 = 'B'.repeat(14 * 1024 * 1024);
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
  assert.match(data.error, /excede el límite permitido de 10 MB/);
});

