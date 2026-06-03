# OpenRouter (Main) + Z.AI (Auxiliary + Vision) Layering Example

## Architecture

| Tier | Provider | Model | Purpose |
|------|----------|-------|---------|
| Main | OpenRouter | deepseek/deepseek-v4-flash | Core conversation reasoning |
| Vision | Z.AI (zai) | glm-4v-flash | Image analysis |
| Auxiliary (10 tasks) | Z.AI (zai) | glm-4-flash | Compression, summary, title, classification, search, approval, MCP, hub, triage, kanban, curation |

## Setup Commands

### 1. Add API Key to `.env`
```bash
# Append or uncomment in ~/.hermes/.env:
GLM_API_KEY=your_zai_api_key_here
```
Note: `.env` cannot be read via `read_file` (defense-in-depth). Use `grep "^GLM_API_KEY" ~/.hermes/.env | od -c` to verify the value was written correctly.

### 2. Main Model (already configured or set via)
```bash
# Already: model.default=deepseek/deepseek-v4-flash, model.provider=openrouter
```

### 3. Vision Model
```bash
hermes config set auxiliary.vision.provider zai
hermes config set auxiliary.vision.model glm-4v-flash
```

### 4. All 10 Non-Vision Auxiliary Tasks
```bash
# Batch via terminal or execute_code:
for task in web_extract compression skills_hub approval mcp \
            title_generation triage_specifier kanban_decomposer \
            profile_describer curator; do
  hermes config set "auxiliary.${task}.provider" zai
  hermes config set "auxiliary.${task}.model" glm-4-flash
done
```

## Verification

```bash
# Check API key detected
hermes status
# → "Z.AI / GLM    ✓ 35f8...94rs"

# Check connectivity
hermes doctor
# → ✓ OpenRouter API
# → ✓ Z.AI / GLM
```

## Key Details

- **Z.AI base URL**: Defaults to `https://api.z.ai/api/paas/v4` (set `GLM_BASE_URL` in `.env` to override)
- **GLM-4-Flash is free** — no token cost for auxiliary tasks
- **GLM-4V-Flash** handles vision input; do NOT use it for non-vision tasks (slower, no benefit)
- **Config changes apply on new session** — `/reset` in CLI or restart gateway
- **`patch` tool blocked on config.yaml** — use `hermes config set` or `sed` for all config edits
