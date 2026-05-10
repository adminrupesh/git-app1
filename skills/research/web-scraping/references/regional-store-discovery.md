# Finding Regional / Country-Specific Storefronts

## Problem

The global brand site (e.g., `sennheiser.com/en-us/products/headphones/momentum-4`) may:
- Return 404 for a specific product in a specific region
- Use a separate e-commerce platform or Shopify subdomain per country
- Redirect away from product pages to regional homepages

## Techniques

### 1. Check `hrefLang` alternate links on the global homepage

```bash
# Linux (GNU grep)
curl -sL 'https://brand.com' | grep -oP 'https://[^"]+' | grep -E '\.(in|co\.in| co\.uk|com\.au)' | sort -u

# macOS / BSD fallback (no -P)
python3 -c "
import urllib.request, re
req = urllib.request.Request('https://brand.com', headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    html = r.read().decode('utf-8')
links = re.findall(r'https://[^\s<>\'\"]+', html)
for l in sorted(set(links)):
    if re.search(r'\.(in|co\.in|co\.uk|com\.au)', l):
        print(l)
"
```

Look for patterns like:
- `https://www.sennheiser.com/en-in`
- `https://in.brand-hearing.com`
- `https://brand.in`

### 2. Search for "brand name + India + price" via DuckDuckGo HTML

```bash
curl -sL 'https://html.duckduckgo.com/html/?q=brand+product+price+India' \
  -H 'User-Agent: Mozilla/5.0'
```

DuckDuckGo HTML search requires no JavaScript and often lists regional retailers or official stores.

### 3. Try common Shopify regional subdomains

Many brands use Shopify's multi-store setup:
- `us.brand.com`, `uk.brand.com`, `in.brand.com`
- `brand-hearing.com` (consumer audio) vs `brand.com` (pro audio)

### 4. Check for separate consumer / hearing portals

Audio brands often split:
- Pro/B2B: `sennheiser.com/en-in` (may not sell headphones directly)
- Consumer/B2C: `sennheiser-hearing.com/en-in` or `in.sennheiser-hearing.com`

### 5. Inspect the global site's source for store links

Even if the product page 404s, the homepage may contain navigation links to "Buy Now" or "Consumer Store" that point to a different domain.

## Real-World Example: Sennheiser India

- Main product URL: `sennheiser.com/en-in/products/headphones/momentum-4` → 404 / empty JS shell
- Consumer store: `in.sennheiser-hearing.com/products/momentum-4-wireless` → Shopify page with OG price tags
- Price found: `₹21,990.00` via `og:price:amount` + `og:price:currency`

## Pitfall

Don't assume the global `.com` path works in every region. Some brands completely separate their product catalogs by country. Always look for a regional subdomain or partner store when the global path fails.
