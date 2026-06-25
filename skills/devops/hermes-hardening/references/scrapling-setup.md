# Scrapling Enhanced Setup Reference

## Installation

### Step 1: Base install
```bash
~/.hermes/hermes-agent/venv/bin/pip install scrapling
```

### Step 2: Extended install (stealth + dynamic modes)
```bash
~/.hermes/hermes-agent/venv/bin/pip install "scrapling[all]"
```

### Step 3: Install browser (required for StealthyFetcher + DynamicFetcher)
```bash
~/.hermes/hermes-agent/venv/bin/python3 -m playwright install chromium
```

Downloads ~112MB Chromium headless shell to `~/.cache/ms-playwright/`.

## Verification

```bash
# Quick import check
~/.hermes/hermes-agent/venv/bin/python3 -c "
from scrapling.fetchers import Fetcher, DynamicFetcher, StealthyFetcher
print('All 3 fetchers available')
"

# Live HTTP test
~/.hermes/hermes-agent/venv/bin/python3 -c "
from scrapling.fetchers import Fetcher
page = Fetcher.get('https://httpbin.org/html')
h1 = page.css('h1::text').get()
print(f'Fetched: {h1}')
"
```

## The `scrapling-fetch.py` Script

Path: `~/.hermes/scripts/scrapling-fetch.py`

Three modes:
- **HTTP** (default): `Fetcher` — static pages, fast, no browser needed
- **Dynamic**: `DynamicFetcher` — JS-rendered pages, uses Playwright headless
- **Stealth**: `StealthyFetcher` — Cloudflare bypass, anti-bot, browser fingerprint spoofing

Usage:
```bash
# HTTP mode
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py "https://example.com"

# Stealth mode (for Cloudflare-protected sites)
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py "https://protected-site.com" --stealth

# Dynamic mode (for SPA/JS-rendered pages)
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py "https://spa-site.com" --dynamic

# Extract specific content
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py "https://example.com" --css-selector ".main-content"

# With proxy
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py "https://example.com" --proxy "http://user:pass@proxy:8080"

# Save to file
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py "https://example.com" --output result.md
```

## Performance Notes

| Mode | Speed | Anti-bot | JS Rendering | Deps |
|------|-------|----------|-------------|------|
| HTTP | Fast (~1-3s) | Low | No | None |
| Dynamic | Medium (~5-15s) | Medium | Yes | Playwright |
| Stealth | Slow (~10-30s) | High (Cloudflare) | Yes | Playwright |

## Related Article

百度开发者中心文章「从裸奔到满配：Hermes Agent深度配置指南」
https://developer.baidu.com/article/detail.html?id=6962622

This reference was created after a session (2026-06-03) where the user compared the Baidu article against their existing setup and executed each of the 7 optimization steps with confirmation.