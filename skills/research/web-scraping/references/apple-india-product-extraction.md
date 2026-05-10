# Apple India Product Extraction — Jina.ai Recipes

Target: Apple India official store pages (apple.com/in, apple.com/in-edu) for Mac pricing, configs, and variants.
Context: price checks, model comparison, education vs. consumer pricing extraction.

---

## Site-Specific URL Patterns

### Consumer Store (standard pricing)
Buy page (model listing):
```
https://r.jina.ai/http://www.apple.com/in/shop/buy-mac/mac-mini
```
Product landing:
```
https://r.jina.ai/http://www.apple.com/in/mac-mini/
```

### Education Store (discounted pricing)
```
https://r.jina.ai/http://www.apple.com/in-edu/shop/buy-mac/mac-mini
```
Education pages include the tag `# Buy Mac mini - Education - Apple (IN)` and list both consumer and education prices.

---

## Key Data Points Extractable

| Field | Pattern in Markdown |
|-------|---------------------|
| MRP (starting price) | `₹79,900` or `₹149,900` — usually right under the product hero |
| Education price | `₹69,900` or `₹139,900` — appears on the `-edu` subdomain pages |
| EMI per month | `From ₹12,650.00/mo.` or `From ₹3,422.00/mo.` — education EMI is lower |
| Chip / variant name | Lines like `Mac mini, M4 Chip, 10-core CPU, 10-core GPU` |
| Memory | `16GB memory`, `24GB memory` |
| Storage | `512GB storage`, `1TB storage` |

---

## Python Extraction Pattern

```python
import requests, re

urls = [
    {"label": "consumer", "url": "https://r.jina.ai/http://www.apple.com/in/shop/buy-mac/mac-mini"},
    {"label": "edu",      "url": "https://r.jina.ai/http://www.apple.com/in-edu/shop/buy-mac/mac-mini"},
]

for u in urls:
    try:
        text = requests.get(u["url"], timeout=20).text
        # Prices
        prices = re.findall(r'\u20b9[\d,]+', text)
        # Variants
        variants = re.findall(r'Mac mini, (M\d[^,]+, [^\n]+)', text)
        print(f"\n=== {u['label']} ===")
        print("Prices:", set(prices)[:10])
        for v in variants[:5]:
            print("  -", v)
    except Exception as e:
        print(f"{u['label']}: {e}")
```

---

## Worked Example: Mac mini M4 (May 2026)

**Consumer (`apple.com/in`):**
- M4 (10C CPU / 10C GPU / 16GB / 512GB): ₹79,900, EMI ₹12,650/mo
- M4 Pro (12C CPU / 16C GPU / 24GB / 512GB): ₹149,900, EMI ₹24,317/mo

**Education (`apple.com/in-edu`):**
- M4 (10C CPU / 10C GPU / 16GB / 512GB): ₹69,900, EMI ₹3,422/mo
- M4 Pro (12C CPU / 16C GPU / 24GB / 512GB): ₹139,900

Education discount is a flat **₹10,000** off both base and Pro models.

---

## Pitfalls

1. **Apple pages are heavily link-based.** The Jina.ai extractor returns mostly navigation links + hero pricing. The exact per-variant pricing is in the hero section of the buy page, not in a table. Regex on the first ~50 lines of the response is enough.
2. **No stock/availability info** in the Markdown extract. Apple shows delivery dates only after clicking Continue into the configurator (which requires a session), so extraction stops at listed price + variant names.
3. **Regional subdomain matters.** `apple.com/in` and `apple.com/in-edu` serve different prices. Always fetch both when answering price-comparison questions.
4. **EMI phrasing varies.** Consumer: "₹12,650.00/mo.Per Month with instant cashback and No Cost EMI". Education: "₹3,422.00/mo. per month with EMI". The education wording is shorter.
