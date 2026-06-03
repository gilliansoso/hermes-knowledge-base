# Verification Session Reference

Record of a completed Hermes full optimization (2026-06-03).

## Target Architecture

```
用户输入
  ├─▶ DeepSeek V4 Flash (OpenRouter — 付费)  主推理
  │     ├─ DuckDuckGo (零成本)
  │     ├─ GLM-4V-Flash (zai 免费视觉)
  │     ├─ GLM-4-Flash (zai 免费 delegation)
  │     └─ Context Compression (zai 免费)
  ├─▶ Holographic Memory (本地 SQLite+FTS5)
  ├─▶ MCP: fetch + filesystem
  └─▶ 98 skills 启用
```

## Current State (After Completion)

### SOUL.md
- **Path**: `~/.hermes/SOUL.md`
- **Size**: ~1.5KB
- **Content**: AI full-stack developer persona with bilingual communication style

### Web Backend
- `web.backend: ddgs` — DuckDuckGo zero-cost search active

### Python Packages (in Hermes venv)
```
duckduckgo_search         8.1.1
edge-tts                  7.2.7
faster-whisper            1.2.1
marker-pdf                1.10.2
scrapling                 0.4.8
```

### Hermes venv path
`~/.hermes/hermes-agent/venv/bin/python3`

### Memory
- Provider: holographic
- Plugin: installed ✓, Status: available ✓
- Hindsight: available but requires API key + uv — skipped

### Cost Control (delegation)
```yaml
delegation:
  model: glm-4-flash
  provider: zai
  max_iterations: 50
  max_concurrent_children: 3
  max_spawn_depth: 1
```

### Auxiliary Models (all zai, all free)
| Role | Model |
|------|-------|
| Vision | glm-4v-flash |
| Context compression | glm-4-flash |
| Web extract | glm-4-flash |
| Approval | glm-4-flash |
| Curator | glm-4-flash |

### MCP Servers
| Name | Transport | Status |
|------|-----------|--------|
| fetch | `python -m mcp_server_fetch` | ✓ enabled |
| filesystem | node `/path/to/server-filesystem` | ✓ enabled |

### Skills
- 98 skills enabled (85 builtin, 7 hub-installed, 6 local)
- Key MLOps: axolotl, clip, guidance, outlines, chroma, llama-cpp, vllm, trl
- Key research: arxiv, dspy, evaluating-llms-harness, weights-and-biases
- Key dev: tdd, plan, spike, systematic-debugging, writing-plans

## Verification Commands (Proven to Work)

```bash
# Check SOUL.md
cat ~/.hermes/SOUL.md

# Check config
hermes config show
grep -A15 "delegation:" ~/.hermes/config.yaml

# Check memory
hermes memory status

# Check MCP
hermes mcp list

# Check packages in Hermes venv
VENV=~/.hermes/hermes-agent/venv
$VENV/bin/pip list | grep -iE "scrapling|duckduckgo|marker|faster.whisper|edge.tts"

# Quick check without triggering model downloads
$VENV/bin/python3 -c "
import importlib
for mod in ['scrapling', 'duckduckgo_search', 'marker', 'faster_whisper', 'edge_tts']:
    spec = importlib.util.find_spec(mod)
    print(f'{mod}: {\"OK\" if spec else \"MISSING\"}')"
```

## Known Pitfalls (Verified)

1. **Hermes venv ≠ system Python** — Always use `~/.hermes/hermes-agent/venv/bin/python3` for package checks
2. **faster-whisper first import** triggers ~500MB model download — use `find_spec()` instead of bare import
3. **`hermes config get` doesn't exist** — use `grep` on the YAML or `hermes config show`
4. **MCP servers can auto-recover** between sessions — don't assume broken means still broken
5. **Hindsight memory** needs both `uv` and a free API key from `https://ui.hindsight.vectorize.io`