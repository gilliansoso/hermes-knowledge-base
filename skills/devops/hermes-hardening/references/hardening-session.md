# Full Hardening Session — Record of Applied Configuration

## Initial State
- Hermes v0.15.1, Python 3.11.15, Linux/Ubuntu
- Main model: DeepSeek V4 Flash (OpenRouter)
- Auxiliary: GLM-4-Flash (Z.AI) — configured in prior session
- Vision: GLM-4V-Flash (Z.AI) — configured in prior session
- SOUL.md: existed but was template-only (just comments)
- Web toolset: disabled (no Exa/Tavily/Firecrawl keys)
- Pandoc: not installed
- Memory: built-in only (no provider)
- Delegation: default (would use main model = OpenRouter DeepSeek)
- Skills hub: 0 hub-installed

## Completed Commands

### Step 1: SOUL.md
Wrote `~/.hermes/SOUL.md` with full Chinese-language personality:
- 精准务实, 架构思维, 深度技术, 效率至上
- 中英双语自然混用, 结构化输出, 不啰嗦
- 先查再动, 边做边教, 主动优化, 错误面前诚实
- 座右铭: "让工具为人服务，而不是为人服务工具"

No config change needed — SOUL.md auto-loads.

### Step 3: Document Tools
```bash
sudo apt install -y pandoc
echo "y" | hermes skills install "official/research/scrapling"
# marker-pdf not installed in this session (pip package)
```

### Step 4: Memory
```bash
hermes memory setup holographic
hermes memory status
# → Provider: holographic, Plugin: installed ✓, Status: available ✓
# Local SQLite + FTS5 + trust scoring — zero-cost
```

### Step 5: Cost Control
```bash
hermes config set delegation.model glm-4-flash
hermes config set delegation.provider zai
```

### Step 7: Hub Skills
```bash
echo "y" | hermes skills install "official/research/duckduckgo-search"
echo "y" | hermes skills install "official/mlops/inference/outlines"
echo "y" | hermes skills install "official/mlops/chroma"
echo "y" | hermes skills install "official/mlops/guidance"
echo "y" | hermes skills install "official/mlops/training/axolotl"
echo "y" | hermes skills install "official/mlops/accelerate"
echo "y" | hermes skills install "official/mlops/training/trl-fine-tuning"
echo "y" | hermes skills install "official/mlops/clip"
```

## Installed Skills (7 hub + 2 research)
```
duckduckgo-search  — Zero-cost web search
scrapling          — Stealth web scraping
outlines           — Structured LLM generation (JSON/Regex/Pydantic)
chroma             — Open-source embedding DB
guidance           — LLM output control (grammars/regex)
axolotl            — YAML LLM fine-tuning (LoRA/DPO/GRPO)
accelerate         — HF distributed training
trl-fine-tuning    — SFT/DPO/PPO/GRPO + reward modeling
clip               — OpenAI vision-language model
```

## Final Config

| Setting | Value |
|---------|-------|
| Main model | deepseek/deepseek-v4-flash (openrouter) |
| Auxiliary | glm-4-flash (zai) — all 10 tasks |
| Vision | glm-4v-flash (zai) |
| Delegation | glm-4-flash (zai) |
| Memory | Holographic (local) |
| Web search | DuckDuckGo (zero-cost fallback) |
| Context compression | glm-4-flash (zai), 50% threshold |
| Max turns | 150 |
| Personality | SOUL.md (Chinese, technical-deep) |

## Key Discoveries

1. **DuckDuckGo works without any API key** — Hermes' web_search falls back to DuckDuckGo when no Exa/Tavily/Firecrawl key is configured
2. **`echo "y" |` piping** — `hermes skills install` uses interactive `Confirm [y/N]` even for official skills; pipe yes for automation
3. **SOUL.md auto-loads** — just having content in the file is enough; no config key or `display.personality` setting needed
4. **Holographic memory is zero external deps** — SQLite + FTS5, works offline, no API key
5. **`display.personality: none` ≠ SOUL.md disabled** — the config display shows `Personality: none` when `display.personality` is empty, but SOUL.md is still active
