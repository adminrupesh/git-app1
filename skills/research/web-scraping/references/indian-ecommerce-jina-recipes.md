# Indian E-Commerce Extraction — Jina.ai Recipes

Target: Amazon.in, Flipkart, Decathlon.in, and similar Indian storefronts.
Context: product research, price comparison, feature extraction across multiple vendors.

---

## Site-Specific URL Patterns

### Amazon.in
Search results (cleaner than PDP for multi-item):
```
https://r.jina.ai/http://www.amazon.in/s?k=<query>
```
Sort by relevance or price:
```
https://r.jina.ai/http://www.amazon.in/s?k=<query>&sort=review-rank
```

### Flipkart
Search results:
```
https://r.jina.ai/http://www.flipkart.com/search?q=<query>
```

### Decathlon.in
Search results:
```
https://r.jina.ai/http://www.decathlon.in/search?query=<query>
```
Product detail page:
```
https://r.jina.ai/http://www.decathlon.in/p/<product-id>/<slug>
```

### HealthKart
Search results:
```
https://r.jina.ai/http://www.healthkart.com/search?query=<query>
```

---

## Python Batch Extraction Pattern

Use `requests` with `timeout=25` and iterate over a list of URLs. Parse the Markdown response for prices, ratings, and product names.

```python
import requests

sites = [
    {"name": "Amazon.in", "url": "https://r.jina.ai/http://www.amazon.in/s?k=pull+up+bar"},
    {"name": "Flipkart", "url": "https://r.jina.ai/http://www.flipkart.com/search?q=pull+up+bar"},
    {"name": "Decathlon", "url": "https://r.jina.ai/http://www.decathlon.in/search?query=pull+up+bar"},
]

for site in sites:
    try:
        resp = requests.get(site["url"], timeout=25)
        text = resp.text
        # Extract key details: grep-like extraction of prices, titles, ratings
        print(f"\n=== {site['name']} ===")
        print(text[:3500])  # Truncate for inspection
    except Exception as e:
        print(f"{site['name']}: {e}")
```

---

## Known Pitfalls

1. **Amazon blocks Jina.ai on some PDPs.** Use search-result pages (`/s?k=`) instead of individual product pages when possible; search results have more metadata in the rendered DOM.
2. **Flipkart URLs redirect.** The extraction often resolves correctly, but raw `flipkart.com` links with tracking params can be stripped to the `pid=` and `lid=` form if needed.
3. **Decathlon is reliable.** Product pages and search pages both return clean Markdown with prices, ratings, and delivery info intact.
4. **Currency formatting:** Indian sites emit `₹2,599` with comma thousand-separators. Parse with locale-aware number handling if doing automated comparison.
5. **Availability and delivery dates** are embedded in plain text (e.g., "FREE delivery Wed, 13 May") — regex or simple string search is sufficient.

---

## Research-to-Recommendation Workflow

When the user asks "best X to buy in India":

1. Identify the product category and the user's constraints (height, weight limit, budget, install type).
2. Search 3–4 Indian sites simultaneously via Jina.ai.
3. Extract: price, capacity/specs, rating, review count, delivery info.
4. Compare and rank.
5. Present in a compact table with a clear recommendation tiered by budget.

---

## Reference URLs Used in This Research

- Amazon.in search: `https://r.jina.ai/http://www.amazon.in/s?k=boldfit+pull+up+bar+doorway`
- Flipkart search: `https://r.jina.ai/http://www.flipkart.com/search?q=pull+up+bar+doorway`
- Decathlon 70cm: `https://r.jina.ai/http://www.decathlon.in/p/8588490/pull-up-bar-70cm-door-lockable-supports-upto-120kg-black-blue`
- Decathlon 100cm: `https://r.jina.ai/http://www.decathlon.in/p/8588491/weight-training-door-lockable-pull-up-bar-supports-upto-100-120kg-100cm-long`
