# Spikes — Throwaway Experiments

Use when validating feasibility, comparing approaches, or surfacing unknowns that research alone can't answer.

## When NOT to use
- Answer is knowable from docs/code — just research
- Production path — write a plan instead
- Idea already validated — jump to implementation

## Core Loop
```
decompose → research → build → verdict
```

## 1. Decompose
Break the idea into 2-5 feasibility questions (Given/When/Then). Order by risk — the spike most likely to kill the idea runs first.

Example table:
| # | Spike | Validates | Risk |
|---|-------|-----------|------|
| 001 | websocket-streaming | WS connection streams tokens < 100ms | High |
| 002a | pdf-parse-pdfjs | Multi-page PDF extracts structured text | Medium |
| 002b | pdf-parse-camelot | Same, different approach | Medium |

## 2. Research (per spike, before building)
- Brief it (2-3 sentences: what, why, risk)
- Surface competing approaches (table with pros/cons/status)
- Pick one. Build quick variants if 2+ are credible.

## 3. Build
- One directory per spike under `spikes/` or `.planning/spikes/`
- Self-contained, disposable
- **Depth over speed** — test edge cases, follow surprising findings
- Each spike's `README.md` ends with a verdict: VALIDATED | PARTIAL | INVALIDATED

## 4. Verdict Format
```markdown
## Verdict: VALIDATED | PARTIAL | INVALIDATED
### What worked
### What didn't
### Surprises
### Recommendation for real build
```

## Comparison Spikes
For parallel approaches (002a/002b), build back-to-back and produce a head-to-head table at the end.

## Tools
- `web_search`, `web_extract`, `terminal` — research
- `write_file`, `terminal`, `browser_navigate`, `browser_vision` — build and verify
- `delegate_task` — fan out parallel comparison spikes