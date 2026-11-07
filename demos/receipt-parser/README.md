# Demo 2: Supermarket Receipt / Invoice Parser (Food Friend POC)

Demo de factibilidad y extracción visual para comprobantes de compra y facturas de supermercados de Guatemala (Walmart, Despensa Familiar, Maxi Despensa, Paiz, La Torre) utilizando `gemini-3.8-flash`.

## Características Principales
- **Modelo:** `gemini-3.8-flash` con esquema de salida estructurada JSON (`responseSchema`).
- **Interpretación de Abreviaturas:** Interpreta códigos típicos de cajas registradoras de supermercados guatemaltecos (`AR/BLA`, `FJOL/NG`, `ACTE/VEG`, `CH/MEIN`, `JAM/FAM`, `TREBOL CREMA`, `MALHER CONS. RES`, etc.).
- **Mapeo Canónico a Despensa:** Mapea el texto crudo del ticket a nombres estandarizados de ingredientes listos para el inventario de la despensa de cocina.
- **Filtro de Ingredientes vs. Artículos de Limpieza/Hogar:** Separa automáticamente los alimentos de artículos no comestibles (papel higiénico, fósforos, toallitas, jabón, etc.).
- **Consolidación Inteligente de Duplicados:** Permite agrupar líneas idénticas repetidas en el ticket o ver el desglose original.
- **Moneda Local:** Extracción de totales y precios unitarios en Quetzales (GTQ / Q).
- **Simulador de Despensa:** Selección de ingredientes con checkboxes y simulación de guardado al estado de inventario de cocina.
- **Muestras de Prueba:** Incluye 3 recibos reales de Guatemala en `samples/` (`sample01.jpg`, `sample02.jpg`, `sample03.jpg`).

## Instrucciones para Ejecutar

1. Verifica que la variable `GEMINI_API_KEY` se encuentre en `.env.local` en la raíz del proyecto.
2. Desde la terminal, inicia el servidor:

```powershell
node demos/receipt-parser/server.js
```

3. Abre en tu navegador:
```
http://localhost:3001
```

