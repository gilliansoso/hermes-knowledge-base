---
name: chinese-futures-data
description: "Fetch, parse, and analyze Chinese commodity futures data from free public APIs for spread analysis, statistical modeling, and research reports."
category: data-science
triggers:
  - "fetch SHFE/DCE/CZCE futures data"
  - "analyze futures spread or basis"
  - "Chinese commodity market research report"
  - "RU/SC/TA/P/MA futures analysis"
---

# Chinese Futures Data Acquisition & Analysis

Fetch Chinese commodity futures (SHFE/DCE/CZCE) data from Sina Finance's free JSONP API, parse it, compute spreads, moving averages, and Z-scores.

## Data Sources

### Primary: Sina Finance Futures API

Endpoint:
```
https://stock.finance.sina.com.cn/futures/api/jsonp.php/var%20_=0/InnerFuturesNewService.getDailyKLine?symbol={CODE}&datalen={N}
```

Where `{CODE}` is the contract symbol (e.g., `RU2609`, `RU2701`, `SC2507`) and `{N}` is days of history.

Known symbols:
- RU = Shanghai rubber
- SC = Shanghai crude oil
- TA = Zhengzhou PTA
- MA = Zhengzhou methanol
- P = Dalian palm oil
- RB = Shanghai rebar
- HC = Shanghai hot-rolled coil
- I = Dalian iron ore
- J = Dalian coking coal
- JM = Dalian coke

### Response Format

The API returns JSONP with a JavaScript wrapper:
```
/*<script>location.href='//sina.com';</script>*/
var _=0([{...JSON array...}]);
```

Each item:
```json
{
  "d": "2026-06-18",      // date
  "o": "17885.000",       // open
  "h": "17910.000",       // high
  "l": "17640.000",       // low
  "c": "17785.000",       // close
  "v": "260826",          // volume
  "p": "154652",          // open interest (持仓量)
  "s": "17780.000"        // settlement price (结算价)
}
```

Note: `p` field is **open interest** (持仓量), not volume.

## Data Fetching & Parsing

```bash
# Raw fetch (150-200 datalen recommended for enough history)
curl -s --max-time 15 \
  "https://stock.finance.sina.com.cn/futures/api/jsonp.php/var%20_=0/InnerFuturesNewService.getDailyKLine?symbol=RU2609&datalen=200" \
  -H "Referer: https://finance.sina.com.cn" \
  -H "User-Agent: Mozilla/5.0"
```

### JSONP stripping (Python):
```python
import json, re

def parse_sina_futures(raw_text):
    """Extract JSON array from Sina's JSONP response."""
    m = re.search(r'\[.*\]', raw_text, re.DOTALL)
    if m:
        data = json.loads(m.group(0))
        return [{
            'd': item['d'],
            'o': float(item['o']),
            'h': float(item['h']),
            'l': float(item['l']),
            'c': float(item['c']),
            'v': int(item['v']),
            'oi': int(item['p']),    # open interest
            's': float(item['s'])    # settlement
        } for item in data]
    return []
```

### Merge two contracts by date & compute spread:
```python
d1 = {d['d']: d for d in data_contract1}
d2 = {d['d']: d for d in data_contract2}

spreads = []
for dt in sorted(set(d1.keys()) & set(d2.keys())):
    spread = d1[dt]['c'] - d2[dt]['c']
    spreads.append((dt, spread, d1[dt]['c'], d2[dt]['c']))
```

## Statistical Calculations

```python
import statistics

spread_values = [s[1] for s in spreads]

for period in [5, 10, 20]:
    if len(spread_values) >= period:
        recent = spread_values[-period:]
        ma = sum(recent) / period
        std = statistics.stdev(recent)
        z = (latest_spread - ma) / std if std > 0 else 0
        print(f"{period}d: MA={ma:.0f} STD={std:.0f} Z={z:.2f}")
```

## Supplementary Data Sources

When building a full market report, search for these additional data points:

| Data Type | Search Query Pattern |
|-----------|---------------------|
| Spot prices (全乳胶) | `site:yunken.com 天然橡胶 全乳胶 价格` or `生意社 天然橡胶 现货` |
| Thai raw materials (胶水/杯胶) | `泰国 胶水 杯胶 原料价格` + recent date |
| Inventory (青岛保税区) | `QinRex 青岛保税区 库存` or `天然橡胶 社会库存` |
| SHFE warehouse receipts (仓单) | `上期所 天然橡胶 仓单 日报` |
| Tire production (开工率) | `全钢胎 开工率 半钢胎 开工率` + recent week |
| Weather (产区天气) | Use weather API or search `泰国 海南 云南 橡胶 产区 天气` |

## Report Template Structure

For spread analysis reports, follow this structure:

1. **价差结构分析** — Current level, historical percentile (Z-score), technical support/resistance
2. **近月驱动** — Supply (new rubber release/imports), Demand (tire production/procurement), Inventory (de-stocking speed), Cost (raw material prices)
3. **远月驱动** — Weather expectations, new crop supply outlook, macro factors
4. **价差方向判断** — Tomorrow's trend (expand/consolidate/contract), key levels, risk notes

## Pitfalls

- **No June 19 data on June 21**: The API may not have data for the most recent 1-2 trading days. Always check the last date before reporting.
- **JSONP stripping**: The response varies — sometimes starts with `/*<script>*/` redirect, sometimes pure `var _=0(...)`. Always use regex `\[.*\]` to extract the JSON array.
- **Chinese holidays**: SHFE has different trading calendars. Always check if the last trading day matches expectations.
- **web_extract limitation**: DuckDuckGo backend cannot extract URL content from Chinese financial sites (yunken, 100ppi, qinrex). Use `browser` or `curl` instead.
- **Contract expiration**: Near-month contracts may have reduced liquidity. Check open interest (OI) to gauge activity.