# Comparación Económica: Cocina en Casa vs. Pedir a Domicilio (`GTQ`)

## Origen de los precios

- **Costo en casa (`Q / porción`):** Se calcula localmente sumando cada ingrediente de la receta usando, en orden de prioridad:
  1. Precios reales en Quetzales (`GTQ`) extraídos de **recibos escaneados** por el usuario (`IngredientPriceStorageService`).
  2. Ofertas vigentes o en caché de **supermercados en Guatemala** (`La Torre` / `Walmart` vía `/api/sales` y respaldo local).
  3. **Tabla base local** (`BaselineGtqPriceCatalog`) con precios promedio de supermercado en Guatemala.
- **Costo a domicilio (`~Q / porción`):** Son **valores de referencia basados en menús reales de restaurantes y plataformas de entrega en Guatemala** (Uber Eats, PedidosYa, San Martín, Patsy, Go Green, Wendy's, El Rancho y Denny's Guatemala), configurados localmente en `BaselineGtqPriceCatalog.resolveTakeoutBenchmark`. No incluyen cargos adicionales variables de envío (`~Q 25–35`).

## Tabla de referencias a domicilio (`GTQ`)

| Categoría de referencia en la app | Precio (`GTQ`) | Referencia real de mercado (Guatemala) | Ejemplos de recetas comparadas |
| :--- | :---: | :--- | :--- |
| **Desayuno de avena o panqueques a domicilio** | `Q 38.00` | Panqueques/avena en PedidosYa y Uber Eats (`Q 35–55` / `Q 20–35`) | *Avena Fresca con Yogur Griego, Fresa y Banano*, *Panqueques Saludables de Avena, Banano y Huevo* |
| **Desayuno típico o con huevos a domicilio** | `Q 48.00` | Desayuno típico en Wendy's (`Q 48`) y cafeterías locales (`Q 45–75`) | *Desayuno Típico Saludable*, *Omelet de Espinaca y Queso de Capas*, *Huevos Rancheros* |
| **Sopa o crema casera a domicilio** | `Q 38.00` | Sopa de frijol en Patsy (`Q 28`) y Sopa de Tortilla en San Martín (`Q 42`) | *Sopa Nutritiva de Lentejas y Espinaca*, *Crema Natural de Ayote y Zanahoria con Garbanzos* |
| **Caldo o sopa con proteína a domicilio** | `Q 48.00` | Caldo de Pollo en Patsy (`Q 48`) y San Martín (`Q 40`) | *Caldo de Pollo con Verduras Frescas*, *Caldo Ligero de Pescado con Perulero y Apio* |
| **Ensalada fresca o ceviche a domicilio** | `Q 45.00` | Ensaladas personales/estándar en Go Green (`Q 36–47`) | *Ensalada Chapina de Aguacate y Tomate*, *Ceviche Vegetariano de Aguacate y Pepino* |
| **Ensalada con pollo o atún a domicilio** | `Q 54.00` | Go Green *Go Zeus* (`Q 54`) y *Go Florencia* (`Q 47`) | *Ensalada Completa de Pollo a la Plancha, Berro y Aguacate*, *Ensalada Fresca de Atún* |
| **Ensalada con mariscos a domicilio** | `Q 65.00` | Bowls/ensaladas con camarón en Go Green (`Q 51+`) y restaurantes | *Ensalada Tropical de Camarones, Mango y Aguacate* |
| **Plato vegetariano o tazón a domicilio** | `Q 51.00` | Bowls saludables en Go Green (`Q 51`) | *Frijoles Negros Parados con Epazote y Queso*, *Tazón de Arroz Integral con Garbanzos y Espinaca* |
| **Plato típico guatemalteco a domicilio** | `Q 69.00` | Pepián de Pollo y Hilachas en San Martín (`Q 69`) | *Pepián de Pollo Tradicional*, *Hilachas de Res Saludables*, *Arroz con Pollo y Verduras Casero* |
| **Plato de pasta a domicilio** | `Q 75.00` | Combos de pasta en San Martín (`Q 70–97`) y Denny's (`Q 107`) | *Pasta Cremosa con Queso Gouda y Espinaca*, *Pasta con Pollo y Queso Parmesano* |
| **Plato de pescado a domicilio** | `Q 75.00` | Filete de pescado en El Rancho (`Q 75`) | *Filete de Pescado al Vapor con Limón y Cilantro*, *Filete de Tilapia a la Plancha* |
| **Plato de pollo a domicilio** | `Q 79.00` | Pollo a la plancha / platos de pollo en San Martín y Denny's (`Q 75–107`) | *Pechuga a la Plancha con Verduras al Vapor*, *Pechuga al Curry Cremoso con Maní* |
| **Plato de res o cerdo a domicilio** | `Q 89.00` | Platos de res en restaurantes locales (`Q 69–161`) | *Lomo de Cerdo al Achiote con Camote y Ejotes*, *Lomo de Res Asado con Coliflor* |
| **Plato de mariscos o salmón a domicilio** | `Q 115.00` | Platos de camarones/salmón en restaurantes (`Q 110–164`) | *Salmón al Horno con Camote, Brócoli y Romero*, *Camarones al Ajillo con Brócoli y Limón* |
| **Plato similar a domicilio** *(respaldo)* | `Q 60.00` | Promedio general de plato principal a domicilio | Recetas externas o generadas por IA sin coincidencia en las categorías anteriores |
