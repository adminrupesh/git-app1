# Grep Portability & Python Fallback

## Problem

`grep -oP` (Perl-compatible regex with `-o` match-only) works on **GNU grep** (Linux) but **fails on BSD grep** (macOS, FreeBSD) with:

```
grep: invalid option -- P
usage: grep [-abcdDEFGHhIiJLlMmnOopqRSsUVvwXxXxZz] ...
```

This session repeatedly hit this when extracting links, OG tags, and JSON blobs from HTML on a **macOS 26.4.1** host.

## Quick Machine Test

Before writing any `grep -oP` recipe, test the target machine:

```bash
if echo 'test' | grep -oP 'test' >/dev/null 2>&1; then
    echo "GNU grep — -P available"
else
    echo "BSD grep — use Python fallback"
fi
```

## Universal Python Fallback

The same regexes used in `grep -oP` work identically in Python `re.search` or `re.findall`. Use a one-shot Python inline script:

```bash
# Extract a single field (like og:price)
python3 -c "
import sys, re
html = sys.stdin.read()
m = re.search(r'pattern', html)
print(m.group(1) if m else '')
" <<< "$HTML"

# Extract all links
python3 -c "
import sys, re
html = sys.stdin.read()
for l in re.findall(r'pattern', html):
    print(l)
" <<< "$HTML"
```

## Common Translations

| Task | `grep -oP` recipe | Python fallback |
|------|-------------------|-----------------|
| OG price | `grep -oP '(?<=content=")[^"]+'` | `re.search(r'content="([^"]+)"', html).group(1)` |
| All href links | `grep -oP '(?<=href=")[^"]+'` | `re.findall(r'href="([^"]+)"', html)` |
| JSON-LD block | `grep -oP '(?<=<script type="application/ld+json">).*?(?=</script>)'` | `re.findall(r'<script type="application/ld+json">(.*?)</script>', html, re.DOTALL)` |
| hrefLang URLs | `grep -oP 'https://[^"]+'` | `re.findall(r'https://[^\s<>\'\"]+', html)` |

## Advantages of Python Fallback

- Works identically on Linux, macOS, WSL, Windows (with Python installed)
- `re.DOTALL` handles multi-line JSON/script blocks naturally
- `html.unescape()` handles `&amp;` and `&#39;` in attributes
- No dependency on `grep` flavor detection in the middle of a task

## When to Still Use grep

- Quick one-liners on a **known Linux** host
- Pipelines where spawning Python adds >500 ms overhead
- When the pattern is simple literal match (`grep -o` without `-P` works on both)

## Reference

- This file created from a session where `grep -oP` failed on macOS 26.4.1, and `python3 -c` with `urllib.request` + `re` was used to successfully extract DuckDuckGo redirect URLs, parse news article titles, and fetch article content.
