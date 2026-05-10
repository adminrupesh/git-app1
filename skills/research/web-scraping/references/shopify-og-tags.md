# Shopify Open Graph Price Tags

## Pattern

Shopify stores commonly expose price via standard Open Graph meta tags in the HTML `<head>`.

```html
<meta property="og:price:amount" content="21,990.00">
<meta property="og:price:currency" content="INR">
```

## Extraction

```bash
curl -sL 'https://store.com/products/item' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' | \
  grep -i 'og:price' -A1 -B1
```

## Also Look For

- `product:price:amount` and `product:price:currency` (Facebook Commerce extension)
- `og:availability` — `instock`, `oos`
- `og:title` — product name

## Pitfall

Some Shopify stores have stale OG prices from theme caching. If the OG price seems off, also check the JSON inside `window.Shopify` or the product's `.json` endpoint (e.g., `/products/item.json`).
