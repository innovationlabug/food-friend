import http from 'node:http';
import { URL } from 'node:url';
import recipeHandler from './api/recipes.ts';
import healthHandler from './api/health.ts';
import detectFridgeHandler from './api/detect-fridge.ts';
import parseReceiptHandler from './api/parse-receipt.ts';

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;

const server = http.createServer(async (req, res) => {
  // Always attach CORS headers for local web development
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.statusCode = 200;
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url ?? '/', `http://localhost:${PORT}`);
  const pathname = parsedUrl.pathname;

  // Collect request body
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  const rawBody = Buffer.concat(chunks).toString('utf-8');
  let body = {};
  if (rawBody.trim().length > 0) {
    try {
      body = JSON.parse(rawBody);
    } catch (e) {
      console.warn('[DEV SERVER] Failed to parse JSON body:', rawBody, e.message);
      body = {};
    }
  }

  console.log(`[DEV SERVER] ${req.method} ${pathname}`, body);

  const query = Object.fromEntries(parsedUrl.searchParams.entries());

  // Adapt to Vercel Serverless Function signature
  const vReq = {
    method: req.method,
    url: req.url,
    headers: req.headers,
    query,
    body,
  };

  const vRes = {
    statusCode: 200,
    setHeader: (name, value) => {
      res.setHeader(name, value);
    },
    status: (code) => {
      res.statusCode = code;
      return vRes;
    },
    json: (data) => {
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(data));
      return vRes;
    },
    end: () => {
      res.end();
      return vRes;
    },
  };

  try {
    if (pathname === '/api/recipes' || pathname === '/api/recipes/') {
      await recipeHandler(vReq, vRes);
    } else if (pathname === '/api/detect-fridge' || pathname === '/api/detect-fridge/') {
      await detectFridgeHandler(vReq, vRes);
    } else if (pathname === '/api/parse-receipt' || pathname === '/api/parse-receipt/') {
      await parseReceiptHandler(vReq, vRes);
    } else if (pathname === '/api/health' || pathname === '/api/health/') {
      await healthHandler(vReq, vRes);
    } else {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ error: `Ruta no encontrada: ${pathname}` }));
    }
  } catch (error) {
    console.error('Error handling request:', error);
    if (!res.headersSent) {
      res.statusCode = 500;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ error: error.message }));
    }
  }
});

server.listen(PORT, () => {
  console.log(`Food Friend Backend API listening on http://localhost:${PORT}`);
});
