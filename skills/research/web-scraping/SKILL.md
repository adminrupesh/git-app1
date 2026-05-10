---
name: web-scraping
description: "Extract structured data from websites using curl, grep, and HTML parsing when browser automation is unavailable or blocked."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [web, scraping, curl, price, data-extraction]
    related_skills: []
---

# Web Scraping: curl-Based Data Extraction

## Overview

When browser automation is unavailable (Chrome not installed, headless mode blocked, or dynamic pages timing out), use curl + text extraction as a fallback to pull structured data from websites. This skill covers common patterns for e-commerce pricing, product metadata, and page content extraction.

## When to Use

- `browser_navigate` fails with "Chrome not found"
- Pages render via JavaScript and return empty/404 to curl (need alternative endpoints)
- You need only a specific datum (price, title, availability) rather than full page interaction
- Rate limits or bot detection block headless browsers

## Workflow

### Step 1: Try Direct curl

```bash
curl -sL 'https://example.com/product' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
```

- Always set a realistic `User-Agent`. Some sites block default curl agents.
- Save to a temp file for repeated grepping: `-o /tmp/page.html`

### Step 2: Check for JavaScript-rendered emptiness

If the response contains only `<script>` tags, `__next_f`, or `window.__INITIAL_STATE__`, the page is dynamically rendered. Strategies:

1. **Look for JSON blobs inside `<script>` tags** — grep for `"price"`, `"product"`, `"variant"`
2. **Check for a separate API endpoint** — search the HTML for `https://` URLs containing `api`, `product`, `json`
3. **Try the mobile or AMP version** — append `?amp=1` or use `m.example.com`
4. **Check regional subdomains** — e.g., `in.sennheiser-hearing.com` vs `sennheiser.com/en-in`

### Step 3: Extract Price / Product Data

#### Technique A: Open Graph Meta Tags

Many e-commerce sites (Shopify, WooCommerce, custom) expose price in OG tags:

```bash
curl -sL 'https://example.com/product' -H 'User-Agent: ...' | \
  grep -i 'og:price' -A1 -B1
```

Common tags:
- `<meta property="og:price:amount" content="21,990.00">`
- `<meta property="og:price:currency" content="INR">`
- `<meta property="product:price:amount" content="399.95">`

#### Technique B: JSON-LD Schema.org

```bash
curl -sL 'https://example.com/product' -H 'User-Agent: ...' | \
  grep -oP '(?<=<script type="application/ld+json">).*?(?=</script>)'
```

Parse the JSON for `@type: Product` → `offers` → `price` and `priceCurrency`.

#### Technique C: Inline JavaScript Product Objects

```bash
curl -sL 'https://example.com/product' -H 'User-Agent: ...' | \
  grep -oE 'window\.__INITIAL_STATE__\s*=\s*\{.*\};' | head -c 5000
```

Look for `product`, `variant`, `price`, `sku` fields inside the JSON payload.

#### Technique D: Jina.ai Reader — Primary Proxy for JS-Heavy E-Commerce

The `r.jina.ai/http://URL` endpoint is often the **fastest and most reliable** way to extract product listings, prices, ratings, and delivery info from JavaScript-heavy e-commerce sites (Amazon, Flipkart, Decathlon, Shopify). It returns clean Markdown, bypasses bot detection, and requires no browser.

```bash
# Direct curl
curl -sL 'https://r.jina.ai/http://www.amazon.in/s?k=pull+up+bar'

# Or via Python requests for programmatic parsing
python -c "
import requests, re
url = 'https://r.jina.ai/http://www.flipkart.com/search?q=product'
resp = requests.get(url, timeout=25)
# Extract prices, ratings, titles from markdown output
"
```

**Why it works:** Jina.ai fetches the page with a full browser backend and extracts the rendered DOM into Markdown. Prices, ratings, review counts, and availability that are invisible to plain curl often survive intact.

**Pitfall:** Extremely dynamic pages (infinite scroll, heavy React hydration) may still return truncated content. If so, try adding a specific product PDP (product detail page) URL rather than a search-results page.

#### Technique E: DuckDuckGo HTML Search

```bash
curl -sL 'https://html.duckduckgo.com/html/?q=product+price+site:example.com'
```

Useful when the site blocks all direct access but DuckDuckGo has a cached/indexed copy.

### Step 4: Verify Currency and Regional Variants

- Prices vary by region. Check `hrefLang` tags or alternate links in `<head>`.
- Shopify stores often use separate subdomains per country: `us.store.com`, `in.store.com`.
- Look for `Shopify.currency = {"active":"INR"}` in page source.

## Pitfalls

- **Hardcoded 404 for bots**: Some Next.js / React sites return 404 HTML to curl even though the page works in a real browser. Try adding `-H 'Accept: text/html'` or using `r.jina.ai`.
- **BSD grep lacks `-P` on macOS**: The `grep -oP` recipes below use Perl-compatible regex, which fails on macOS/BSD with `grep: invalid option -- P`. Use the Python fallback versions shown in each recipe, or test with `echo 'test' | grep -oP 'test' 2>/dev/null || echo "use python fallback"` before relying on `-P`.
- **Currency formatting**: Indian prices often use `₹21,990.00` (INR) while US uses `$399.95` (USD). Confirm `og:price:currency`.
- **Stale prices in OG tags**: Some sites cache OG tags. Cross-check with the live PDP (product detail page) if possible.
- **Comma vs dot decimals**: `21,990.00` is Indian-style; `399.95` is US-style. Parse accordingly.

## Quick Recipes

### Recipe: Shopify Price Grab (portable — works on Linux & macOS)

```bash
URL="https://store.com/products/item"
HTML=$(curl -sL "$URL" -H 'User-Agent: Mozilla/5.0')

# --- Quick Linux-only path ---
PRICE=$(echo "$HTML" | grep -oP '(?<=<meta property="og:price:amount" content=")[^"]+')
CURRENCY=$(echo "$HTML" | grep -oP '(?<=<meta property="og:price:currency" content=")[^"]+')

# --- macOS/BSD fallback (same result, no -P) ---
if [ -z "$PRICE" ]; then
  PRICE=$(python3 -c "
import sys, re
html = sys.stdin.read()
m = re.search(r'<meta property=\"og:price:amount\" content=\"([^\"]+)\"', html)
print(m.group(1) if m else '')
" <<< "$HTML")
  CURRENCY=$(python3 -c "
import sys, re
html = sys.stdin.read()
m = re.search(r'<meta property=\"og:price:currency\" content=\"([^\"]+)\"', html)
print(m.group(1) if m else '')
" <<< "$HTML")
fi

echo "$CURRENCY $PRICE"
```

### Recipe: News Search & Article Extraction (DuckDuckGo → Python)

```bash
# 1. Search DDG HTML (JS-free, no API key)
QUERY="PCMC water supply STP society cut 2025 2026"
DDG_HTML=$(curl -sL "https://html.duckduckgo.com/html/?q=${QUERY// /+}" \
  -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

# 2. Extract DDG redirect URLs with Python (macOS-safe, no grep -P)
python3 -c "
import sys, re
html = sys.stdin.read()
links = re.findall(r'class=\"result__a\" href=\"([^\"]+)\"', html)
for l in links[:10]:
    print(l)
" <<< "$DDG_HTML" > /tmp/ddg_links.txt

# 3. Decode DDG redirects to real URLs (they contain uddg=...)
python3 -c "
import urllib.parse, sys
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    if line.startswith('//duckduckgo.com/l/?uddg='):
        real = urllib.parse.unquote(line.split('uddg=')[1].split('&')[0])
        print(real)
    else:
        print(line)
" < /tmp/ddg_links.txt > /tmp/real_urls.txt

# 4. Fetch article content (titles + first paragraphs)
python3 -c "
import urllib.request, re, html
for url in sys.stdin.read().strip().splitlines()[:5]:
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=15) as r:
            data = r.read().decode('utf-8')
        title = re.search(r'<title>([^<]+)</title>', data)
        paras = re.findall(r'<p[^>]*>(.*?)</p>', data, re.DOTALL)
        clean = ''
        for p in paras:
            t = re.sub(r'<[^>]+>', '', p)
            t = html.unescape(t).strip()
            if len(t) > 30 and 'cookie' not in t.lower():
                clean = t[:200]
                break
        print(f'--- {title.group(1).strip() if title else \"No title\"} ---')
        print(clean)
        print()
    except Exception as e:
        print(f'Error for {url}: {e}')
" < /tmp/real_urls.txt
```

**When this applies:**
- User asks for "latest news on X" and needs actual article links + snippets
- Browser automation unavailable (Chrome not found)
- No API keys for Google News / Bing News
- DDG HTML search works without JavaScript and usually returns news results within hours of publication

```bash
# --- Quick Linux-only path ---
curl -sL 'https://brand.com' | grep -oP 'https://[^"]+' | grep -E 'in|india|uk|us' | sort -u

# --- macOS/BSD fallback ---
python3 -c "
import urllib.request, re
req = urllib.request.Request('https://brand.com', headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    html = r.read().decode('utf-8')
links = re.findall(r'https://[^\s<>\'\"]+', html)
for l in sorted(set(links)):
    if re.search(r'in|india|uk|us', l, re.I):
        print(l)
"
```

## References

- `references/shopify-og-tags.md` — Shopify-specific meta tag patterns
- `references/regional-store-discovery.md` — Techniques for finding country-specific storefronts
- `references/indian-ecommerce-jina-recipes.md` — Amazon.in, Flipkart, Decathlon.in extraction patterns via Jina.ai
- `references/apple-india-product-extraction.md` — Apple India store pages (consumer & education pricing) via Jina.ai
- `references/grep-portability-and-python-fallback.md` — BSD/macOS grep `-P` failure & Python one-liner replacements
