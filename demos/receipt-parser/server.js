const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3001;
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

const SYSTEM_INSTRUCTION = `Eres un asistente experto en procesamiento y digitalización de comprobantes de pago, facturas y recibos de supermercados en Guatemala (Walmart Guatemala, Paiz, Despensa Familiar, Maxi Despensa, Supermercados La Torre, Super del Barrio, etc.) para la aplicación Food Friend.

Tu misión es:
1. Extraer con precisión los datos de la factura: Establecimiento / Supermercado, fecha/hora y montos totales en Quetzales guatemaltecos (GTQ / Q).
2. Leer cada línea de producto e interpretar abreviaturas comerciales guatemaltecas (ej. "AR/BLA" -> Arroz blanco, "FJOL/NG" -> Frijol negro, "ACTE/VEG" -> Aceite vegetal, "CH/MEIN" -> Chow Mein, "JAM/FAM" -> Jamón familiar, "TREBOL CREMA" -> Crema Trebolac, "MALHER CONS. RES" -> Consomé de res Malher, "DAMA REAL" -> Harina de maíz Dama Real, etc.).
3. Mapear cada producto a un nombre canónico y limpio ("ingrediente_estandar") adecuado para ser registrado en el inventario de la despensa de cocina.
4. Identificar claramente la marca (ej. Malher, Trebolac, Ina, Ducal, Toledo, Ideal, Molinero, La Cosecha, Del Frutal, Petit, Mazola, etc.).
5. Clasificar con precisión si el ítem es comestible / ingrediente de cocina ("es_alimento": true) o si es un artículo de limpieza, higiene personal, ferretería o del hogar ("es_alimento": false, ej. detergentes, jabón de baño, fósforos, toallas húmedas, escobas, papel higiénico, gel para cabello).
6. Extraer las cantidades, peso y precio en Quetzales (Q).`;

const PROMPT_TEXT = `Analiza detalladamente esta fotografía de un recibo / factura de supermercado de Guatemala.

Extrae la información en un JSON estructurado con:
1. "supermercado": Nombre de la cadena o tienda (ej. "Walmart Villa Nueva", "Despensa Familiar", "Supermercados La Torre", "Maxi Despensa" o "Supermercado no identificado").
2. "fecha": Fecha y hora registradas en el ticket (en formato DD/MM/AAAA si es visible, o null si no se aprecia).
3. "total_factura_gtq": El total general de la factura en Quetzales (número decimal). Si está cortado o ilegible, calcula la suma de los ítems legibles.
4. "total_alimentos_gtq": La suma de los precios de todos los productos que sean alimentos / ingredientes de cocina en Quetzales (número decimal).
5. "items": Lista completa de ítems legibles en el recibo. Para cada ítem:
   - "nombre_ticket": Texto exacto o casi exacto tal como aparece impreso en el recibo (ej. "MOLINERO AR/BLA 400G").
   - "ingrediente_estandar": Nombre limpio, normalizado y legible para la despensa (ej. "Arroz blanco").
   - "marca": Marca del producto (ej. "Molinero", "Toledo", "Ina", "Great Value", "Desconocida/Genérica").
   - "categoria": Una de ["Granos y Abarrotes", "Lácteos y Huevos", "Carnes y Embutidos", "Bebidas y Jugos", "Condimentos y Salsas", "Pastas y Harinas", "Aceites y Grasas", "Frutas y Verduras", "Snacks y Dulces", "Higiene y Limpieza", "Hogar y Varios"].
   - "cantidad_o_peso": Cantidad o peso extraído de la descripción o línea (ej. "400 g", "1 lb", "750 ml", "1 unidad", "6 pack").
   - "unidades": Número entero de unidades compradas según el ticket (normalmente 1 salvo si indica multiplicador).
   - "precio_unitario_gtq": Precio por unidad en Quetzales (número decimal o null).
   - "precio_total_gtq": Precio total pagado por esa línea en Quetzales (número decimal).
   - "es_alimento": booleano (true si es ingrediente o alimento apto para despensa/cocina, false si es papel higiénico, fósforos, limpiador, etc.).
6. "resumen": Breve resumen en español del recibo, destacando la tienda, cantidad de alimentos identificados y total gastado en ingredientes.`;

async function callGeminiReceiptParser(imageBase64, mimeType = 'image/jpeg') {
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
          supermercado: { type: 'STRING' },
          fecha: { type: 'STRING' },
          total_factura_gtq: { type: 'NUMBER' },
          total_alimentos_gtq: { type: 'NUMBER' },
          resumen: { type: 'STRING' },
          items: {
            type: 'ARRAY',
            items: {
              type: 'OBJECT',
              properties: {
                nombre_ticket: { type: 'STRING' },
                ingrediente_estandar: { type: 'STRING' },
                marca: { type: 'STRING' },
                categoria: { type: 'STRING' },
                cantidad_o_peso: { type: 'STRING' },
                unidades: { type: 'INTEGER' },
                precio_unitario_gtq: { type: 'NUMBER' },
                precio_total_gtq: { type: 'NUMBER' },
                es_alimento: { type: 'BOOLEAN' }
              },
              required: [
                'nombre_ticket',
                'ingrediente_estandar',
                'marca',
                'categoria',
                'cantidad_o_peso',
                'unidades',
                'precio_total_gtq',
                'es_alimento'
              ]
            }
          }
        },
        required: ['supermercado', 'items', 'total_factura_gtq', 'total_alimentos_gtq', 'resumen']
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

    // 3. API: List available receipt samples
    if (pathname === '/api/samples' && req.method === 'GET') {
      const sampleDescriptions = {
        'sample01.jpg': {
          title: 'Walmart Guatemala (Villa Nueva)',
          description: 'Ticket estándar de Walmart con producto Naturalísimo.',
          store: 'Walmart'
        },
        'sample02.jpg': {
          title: 'Despensa Familiar (Guatemala)',
          description: 'Ticket completo con múltiples alimentos (Toledo, Ina, Molinero, etc.) y no comestibles.',
          store: 'Despensa Familiar'
        },
        'sample03.jpg': {
          title: 'Maxi Despensa / Paiz (Guatemala)',
          description: 'Ticket largo con variedad de ingredientes, pastas, harinas y refrescos Yus.',
          store: 'Maxi Despensa'
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
        store: sampleDescriptions[file]?.store || 'Supermercado'
      }));

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ samples }));
      return;
    }

    // 4. API: Parse receipt
    if (pathname === '/api/parse-receipt' && req.method === 'POST') {
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

      const result = await callGeminiReceiptParser(base64Data, mimeType);
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
  console.log(`===========================================================`);
  console.log(`Food Friend - Supermarket Receipt Parser (Gemini 3.8 Flash)`);
  console.log(`Servidor escuchando en: http://localhost:${PORT}`);
  console.log(`===========================================================`);
});

