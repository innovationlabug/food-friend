# FEAT-5 Technical Feasibility & Scheduled Sales Architecture

## Findings Summary

Fetching promotional grocery data from major Guatemalan supermarkets (**La Torre** `www.latorre.com.gt` and **Walmart Guatemala** `www.walmart.com.gt`) is **technically feasible** without headless browsers or LLM calls.

### What Worked
1. **Shared VTEX IO Storefront API:** Both La Torre and Walmart Guatemala (as well as Paiz) run on VTEX IO and expose the public Intelligent Search JSON endpoint:
   `GET /api/io/_v/api/intelligent-search/product_search/?query=<ingredient>&count=12&page=1&hideUnavailableItems=true`
2. **No Anti-Bot Blocks on Server Fetch:** Direct server-side HTTP `fetch` requests returned `HTTP 200 OK` without Cloudflare or CAPTCHA challenges.
3. **Structured `GTQ` Pricing:** Responses include `productName`, `brand`, `categories`, `ListPrice` (regular price in Quetzales), `Price` (discounted price in Quetzales), `AvailableQuantity`, and product links.

### Quirks & Mitigations
1. **Client-Rendered `/ofertas` HTML Pages:** Walmart's `/ofertas` page does not embed `__STATE__` in initial HTML, and La Torre's `/ofertas` HTML exceeds 2.6 MB. Using the Intelligent Search JSON endpoint avoids heavy HTML parsing.
2. **Zero-Price / Out-of-Stock Items:** Unfiltered responses can return `Price: 0` items; filtering `hideUnavailableItems=true` plus `Price > 0 && ListPrice > Price && AvailableQuantity > 0` eliminates invalid records.
3. **Non-Food Cross-Matches:** Queries like `"pasta"` can return `"Pasta Dental Colgate"`. Filtering out non-food VTEX category prefixes (`/Higiene`, `/Cuidado Personal`, `/Limpieza`, `/Ropa`, `/Autos`, `/Mascotas`, etc.) prevents non-food results.
4. **Multi-Query Latency:** Querying ~12 staple ingredients across two chains takes ~4.5–6.5 seconds total, confirming that scraping must **not** run on every client screen load.

## Production Vercel Architecture

- **`/api/refresh-sales` (`api/refresh-sales.ts`):** Triggered daily via Vercel Cron (`0 6 * * *` in `vercel.json`), scrapes the scoped staple ingredient list from La Torre and Walmart Guatemala, and writes `sales-snapshot.json` into **Vercel Blob** (`BLOB_READ_WRITE_TOKEN`).
- **`/api/sales` (`api/sales.ts`):** Read-only endpoint served to the Flutter app. Reads the persisted snapshot from Vercel Blob with CDN/memory caching (`s-maxage=3600`) and falls back to a curated `GTQ` dataset if Blob is empty or unreachable.
- **On-Device Matching (`lib/features/sales/`):** Cross-references deals locally against `"Por comprar"`, `Favorita` recipe ingredients, and frequently used pantry items (`timesUsed > 0`) with zero extra LLM calls.
