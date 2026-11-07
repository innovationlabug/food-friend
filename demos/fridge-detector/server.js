const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const SAMPLES_DIR = path.join(__dirname, 'samples');

// Load API Key from .env.local or process.env
function getApiKey() {
  const envPath = path.resolve(__dirname, '../../.env.local');
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    const match = content.match(/GEMINI_API_KEY=([^\r\n]+)/);
    if (match) return match[1].trim();
  }
  return process.env.GEMINI_API_KEY;
}

// System instruction tuned for Guatemalan / Central American kitchen recognition
const SYSTEM_INSTRUCTION = `Eres un asistente experto en reconocimiento visual de alimentos y despensas para la aplicación Food Friend en Guatemala.
Tu objetivo es identificar con alta precisión productos de refrigerador y alacena, reconociendo tanto marcas locales de Guatemala y Centroamérica (por ejemplo: Trebolac, Malher, Incaparina, Ducal, Sula, YaEstá, Pollo Campero, Don Lázaro, Foremost, B&B, Tortrix, Queso de Capas, crema de vaca local, embutidos Toledo o Perry, güisquil, aguacate criollo, hierbabuena, plátano) como marcas internacionales habituales (Hellmann's, French's, Heinz, etc.).

Examina minuciosamente la imagen por niveles, bandejas o compartimentos.
Devuelve siempre información veraz y estructurada en formato JSON estricto.`;

const PROMPT_TEXT = `Analiza detalladamente esta fotografía de refrigerador / alacena.
Identifica cada producto visible (lácteos, bebidas, salsas, condimentos, carnes, embutidos, verduras, frutas, sobras o comida preparada).

Genera un JSON con:
1. "resumen": Una descripción general concisa en español de lo que contiene el refrigerador/congelador y los productos destacados.
2. "items": Lista detallada de productos detectados, donde cada uno contenga:
   - "producto": Nombre claro del producto (ej. "Jugo de naranja", "Leche entera", "Salsa picante Campero").
   - "marca": Marca identificada o "Genérica / Sin marca visible" o "Casero / Preparado".
   - "categoria": Una de ["Lácteos", "Bebidas", "Condimentos y Salsas", "Carnes y Embutidos", "Frutas y Verduras", "Abarrotes", "Comida Preparada / Sobras", "Congelados", "Snacks / Otros"].
   - "cantidad_estimada": Cantidad y nivel visual estimado (ej. "1 botella de 1L (~80% llena)", "3 unidades", "1 refractario mediano tapado").
   - "confianza": "Alta", "Media" o "Baja".
   - "es_marca_local": booleano indicando si es una marca tradicionalmente guatemalteca o regional centroamericana (ej. Trebolac, Ducal, Malher, Pollo Campero, Natura's, Naturalísimo, B&B, Sula, Foremost, Perry, Toledo, etc.).
   - "observaciones": Notas de empaque, color de tapón o posición en el refrigerador.`;

async function callGeminiVision(imageBase64, mimeType = 'image/jpeg') {
  const apiKey = getApiKey();
  if (!apiKey) {
    throw new Error('No se encontró GEMINI_API_KEY en .env.local');
  }

  const model = 'gemini-3.8-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const payload = {
    system_instruction: {
      parts: [{ text: SYSTEM_INSTRUCTION }]
    },
    contents: [
      {
        parts: [
          { text: PROMPT_TEXT },
          {
            inline_data: {
              mime_type: mimeType,
              data: imageBase64
            }
          }
        ]
      }
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'OBJECT',
        properties: {
          resumen: { type: 'STRING' },
          items: {
            type: 'ARRAY',
            items: {
              type: 'OBJECT',
              properties: {
                producto: { type: 'STRING' },
                marca: { type: 'STRING' },
                categoria: { type: 'STRING' },
                cantidad_estimada: { type: 'STRING' },
                confianza: { type: 'STRING', enum: ['Alta', 'Media', 'Baja'] },
                es_marca_local: { type: 'BOOLEAN' },
                observaciones: { type: 'STRING' }
              },
              required: ['producto', 'marca', 'categoria', 'cantidad_estimada', 'confianza', 'es_marca_local']
            }
          }
        },
        required: ['items', 'resumen']
      }
    }
  };

  const startTime = Date.now();
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  const durationMs = Date.now() - startTime;

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`Gemini API error (${res.status}): ${errorText}`);
  }

  const json = await res.json();
  const textOutput = json.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!textOutput) {
    throw new Error('Respuesta vacía de Gemini');
  }

  const parsed = JSON.parse(textOutput);
  return {
    data: parsed,
    durationMs,
    modelUsed: model
  };
}

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      // 25MB safety limit for high-res images
      if (body.length > 25 * 1024 * 1024) {
        reject(new Error('Payload demasiado grande (>25MB)'));
      }
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        reject(new Error('JSON inválido en el cuerpo de la petición'));
      }
    });
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  // CORS headers for convenience
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  try {
    // 1. Serve index.html
    if (pathname === '/' || pathname === '/index.html') {
      const htmlPath = path.join(__dirname, 'index.html');
      const html = fs.readFileSync(htmlPath, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(html);
      return;
    }

    // 2. Serve sample image file
    if (pathname.startsWith('/samples/')) {
      const filename = path.basename(pathname);
      const filePath = path.join(SAMPLES_DIR, filename);
      if (fs.existsSync(filePath)) {
        const ext = path.extname(filename).toLowerCase();
        const mimeTypes = {
          '.jpeg': 'image/jpeg',
          '.jpg': 'image/jpeg',
          '.png': 'image/png',
          '.webp': 'image/webp'
        };
        const mime = mimeTypes[ext] || 'application/octet-stream';
        res.writeHead(200, { 'Content-Type': mime, 'Cache-Control': 'public, max-age=3600' });
        fs.createReadStream(filePath).pipe(res);
        return;
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Sample no encontrado' }));
        return;
      }
    }

    // 3. API: List available samples
    if (pathname === '/api/samples' && req.method === 'GET') {
      const sampleDescriptions = {
        'sample01_freezer.jpeg': {
          title: 'Congelador (Freezer)',
          description: 'Bolsas de alimentos congelados, carnes y recipientes.',
          badge: 'Congelador'
        },
        'sample02_door.jpeg': {
          title: 'Puerta del Refrigerador',
          description: 'Salsas, condimentos y bebidas (Campero, Natura\'s, etc.).',
          badge: 'Puerta / Salsas'
        },
        'sample03_refrigerator.jpeg': {
          title: 'Cuerpo Principal del Refrigerador',
          description: 'Estantes principales con refractarios, lácteos y alimentos diarios.',
          badge: 'Interior Principal'
        }
      };

      let files = [];
      if (fs.existsSync(SAMPLES_DIR)) {
        files = fs.readdirSync(SAMPLES_DIR).filter(f => /\.(jpe?g|png|webp)$/i.test(f));
      }

      const samples = files.map(file => ({
        fileName: file,
        url: `/samples/${file}`,
        title: sampleDescriptions[file]?.title || file,
        description: sampleDescriptions[file]?.description || '',
        badge: sampleDescriptions[file]?.badge || 'Muestra'
      }));

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ samples }));
      return;
    }

    // 4. API: Analyze image
    if (pathname === '/api/analyze' && req.method === 'POST') {
      const body = await parseJsonBody(req);
      let base64Data = '';
      let mimeType = 'image/jpeg';

      if (body.sampleName) {
        const filePath = path.join(SAMPLES_DIR, path.basename(body.sampleName));
        if (!fs.existsSync(filePath)) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: `La muestra ${body.sampleName} no existe.` }));
          return;
        }
        base64Data = fs.readFileSync(filePath).toString('base64');
        const ext = path.extname(filePath).toLowerCase();
        mimeType = ext === '.png' ? 'image/png' : 'image/jpeg';
      } else if (body.imageBase64) {
        base64Data = body.imageBase64.replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, '');
        if (body.mimeType) mimeType = body.mimeType;
      } else {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Debe proveer sampleName o imageBase64' }));
        return;
      }

      const result = await callGeminiVision(base64Data, mimeType);
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        ok: true,
        model: result.modelUsed,
        durationSeconds: (result.durationMs / 1000).toFixed(2),
        data: result.data
      }));
      return;
    }

    // Default 404
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Ruta no encontrada');
  } catch (err) {
    console.error('Server error:', err);
    res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ ok: false, error: err.message }));
  }
});

server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`Food Friend - Fridge Detector Demo (Gemini 3.8 Flash)`);
  console.log(`Servidor escuchando en: http://localhost:${PORT}`);
  console.log(`====================================================`);
});

