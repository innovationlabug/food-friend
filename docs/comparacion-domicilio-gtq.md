# Comparación Económica: Cocina en Casa vs. Pedir a Domicilio (`GTQ`)

## Origen de los precios

- **Costo en casa (`Q / porción`):** Se calcula localmente sumando cada ingrediente de la receta usando, en orden de prioridad:
  1. Precios reales en Quetzales (`GTQ`) extraídos de **recibos escaneados** por el usuario (`IngredientPriceStorageService`).
  2. Ofertas vigentes o en caché de **supermercados en Guatemala** (`La Torre` / `Walmart` vía `/api/sales` y respaldo local).
  3. **Tabla base local** (`BaselineGtqPriceCatalog`) con precios promedio de supermercado en Guatemala.
- **Costo a domicilio (`~Q / porción`):** Son **valores de referencia curados localmente** en `BaselineGtqPriceCatalog.resolveTakeoutBenchmark` (no provienen de *scraping* de aplicaciones de entrega). Representan el costo promedio por porción de un platillo equivalente en restaurantes o apps de entrega a domicilio en Guatemala (incluyendo tarifa típica de envío/servicio).

## Tabla de referencias a domicilio (`GTQ`)

| Categoría de referencia en la app | Precio de referencia (`GTQ`) | Ejemplos de recetas comparadas |
| :--- | :---: | :--- |
| **Desayuno de avena o panqueques a domicilio** | `Q 38.00` | *Avena Fresca con Yogur Griego, Fresa y Banano*, *Panqueques Saludables de Avena, Banano y Huevo* |
| **Desayuno típico o con huevos a domicilio** | `Q 42.00` | *Desayuno Típico Saludable*, *Omelet de Espinaca y Queso de Capas*, *Huevos Rancheros con Salsa de Tomate y Frijoles Negros* |
| **Sopa o crema casera a domicilio** | `Q 44.00` | *Sopa Nutritiva de Lentejas y Espinaca*, *Crema Natural de Ayote y Zanahoria con Garbanzos* |
| **Plato vegetariano o tazón a domicilio** | `Q 46.00` | *Frijoles Negros Parados con Epazote y Queso*, *Tazón de Arroz Integral con Garbanzos y Espinaca* |
| **Ensalada fresca o ceviche a domicilio** | `Q 48.00` | *Ensalada Chapina de Aguacate y Tomate*, *Ceviche Vegetariano de Aguacate y Pepino* |
| **Caldo o sopa con proteína a domicilio** | `Q 52.00` | *Caldo de Pollo con Verduras Frescas*, *Caldo Ligero de Pescado con Perulero y Apio* |
| **Plato de pasta a domicilio** | `Q 55.00` | *Pasta Cremosa con Queso Gouda y Espinaca*, *Pasta con Pollo y Queso Parmesano* |
| **Plato típico guatemalteco a domicilio** | `Q 56.00` | *Pepián de Pollo Tradicional*, *Arroz con Pollo y Verduras Casero*, *Guiso de Pollo con Perulero y Güisquil* |
| **Ensalada con pollo o atún a domicilio** | `Q 58.00` | *Ensalada Completa de Pollo a la Plancha, Berro y Aguacate*, *Ensalada Fresca de Atún con Pepino y Garbanzos* |
| **Plato de pollo a domicilio** | `Q 58.00` | *Pechuga a la Plancha con Verduras al Vapor*, *Pechuga al Curry Cremoso con Maní* |
| **Plato de pescado a domicilio** | `Q 62.00` | *Filete de Pescado al Vapor con Limón y Cilantro*, *Filete de Tilapia a la Plancha con Tomate y Limón* |
| **Plato de res o cerdo a domicilio** | `Q 64.00` | *Hilachas de Res Saludables*, *Lomo de Cerdo al Achiote con Camote y Ejotes* |
| **Ensalada con mariscos a domicilio** | `Q 68.00` | *Ensalada Tropical de Camarones, Mango y Aguacate* |
| **Plato de mariscos o salmón a domicilio** | `Q 82.00` | *Salmón al Horno con Camote, Brócoli y Romero*, *Camarones al Ajillo con Brócoli y Limón* |
| **Plato similar a domicilio** *(respaldo externo)* | `Q 54.00` | Recetas externas o generadas por IA sin coincidencia en las categorías anteriores |
