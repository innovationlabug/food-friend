# Demo 1: Refrigerator Product Recognition (Food Friend POC)

Demo de factibilidad y reconocimiento visual para identificar productos de refrigerador y alacena con foco en marcas locales de Guatemala y Centroamérica (ej. Trebolac, Malher, Incaparina, Ducal, Pollo Campero, Natura's, Naturalísimo, etc.).

## Características del Demo
- **Modelo:** `gemini-3.8-flash` con salida estructurada JSON (`responseSchema`).
- **Backend Ligero:** Servidor HTTP nativo en Node.js que consume la API de Gemini sin exponer la clave al cliente.
- **Frontend Interactivo:**
  - 3 muestras precargadas listas para probar con 1 clic (`sample01_freezer.jpeg`, `sample02_door.jpeg`, `sample03_refrigerator.jpeg`).
  - Zona de carga por arrastrar y soltar (drag & drop), selección de archivos o pegado directo desde el portapapeles (Ctrl+V).
  - Métricas en tiempo real: productos detectados, marcas locales identificadas, nivel de confianza y tiempo de respuesta.
  - Filtros dinámicos por categoría y buscador en vivo.
  - Indicador de marcas locales guatemaltecas / regionales.
  - Visor de JSON crudo para depuración y análisis.

## Instrucciones para Ejecutar

1. Asegúrate de tener tu clave `GEMINI_API_KEY` en el archivo `.env.local` en la raíz del proyecto.
2. Desde la terminal, navega a esta carpeta o ejecútalo directamente:

```powershell
node demos/fridge-detector/server.js
```

3. Abre en tu navegador:
```
http://localhost:3000
```

