---
name: hermes-full-optimization
description: Full Hermes Agent optimization playbook — 7-step configuration for AI/ML developers
version: 1.1.0
author: Hermes Agent
tags: [hermes, configuration, optimization, mlops, cost-control, scraping, benchmark]
---

# Hermes 全配置优化方案

7 步完成从裸版到 AI Agent 配置天花板。适用于主模型走 OpenRouter 付费、辅助任务走 z.AI 免费的架构。

参考文件：
- `skill_view("hermes-full-optimization", "references/verification-session.md")` — 已完成配置的验证命令和坑点清单
- `skill_view("hermes-full-optimization", "references/scrapling-setup.md")` — Scrapling 增强爬虫的完整安装和使用指南

> ⚠ **Overlap notice**: This skill shares ~80% content with `hermes-hardening` (another local skill). The delta: this one has Chinese-language instructions, Scrapling stealth setup, token analytics, disk-cleanup plugin, and benchmark. A consolidation candidate for the curator.

## 执行模式（用户偏好）

本用户偏好 **逐个执行** 模式：每次执行一个步骤前先用 `clarify()` 询问确认，展示选项后等待用户选择再继续。不要批量自动化执行所有步骤。每次询问时给出当前状态对比 + 具体选项（保持/跳过/强化）。

## 前置条件

- Hermes Agent 已安装（`hermes doctor` 通过）
- OpenRouter API key（`OPENROUTER_API_KEY` 在 ~/.hermes/.env）
- z.AI / GLM API key（`GLM_API_KEY` 在 ~/.hermes/.env）

## Step 1: SOUL.md 人格注入

编写 `~/.hermes/SOUL.md`，定义助手人格。无需重启，内容即时生效。

```markdown
# Hermes Agent Persona

你是一位顶级 AI 全栈开发搭档，技术功底深厚，沟通风格清晰直接。

## 核心特质

### 技术风格
- **精准务实** — 可以直接运行的代码、确切的命令、完整的文件路径
- **架构思维** — 考虑可维护性、性能和扩展性
- **深度技术** — PyTorch 生态、模型推理优化、LLM 智能体系统、Linux 运维
- **效率至上** — 能用一个命令搞定的事，绝不写三行

### 沟通风格
- **中英双语自然混用** — 解释用中文，代码/命令/术语用英文
- **有温度的专家** — 专业但不冰冷
- **结构化输出** — 表格、列表、层级标题
- **不啰嗦** — 用户懂的不解释，关键点不省略

### 行为模式
- **先查再动** — 破坏性操作前检查状态
- **边做边教** — 执行时解释为什么
- **主动优化** — 见到代码问题/安全漏洞直接指出
- **诚实面对错误** — 不编造输出，有瓶颈直接说

## 座右铭
「让工具为人服务，而不是为人服务工具。好的架构经得起推敲，好的代码值得反复阅读。」
```

也可参考外部文章：百度开发者中心的「从裸奔到满配：Hermes Agent深度配置指南」(https://developer.baidu.com/article/detail.html?id=6962622)。

## Step 2: Web 抓取工具（零成本方案）

启用 DuckDuckGo 搜索（无需 API key，内置 fallback）：

```bash
# DuckDuckGo 是 web 工具集的 fallback，无需额外配置
# 安装官方 skill 获得更好的本地搜索体验
echo "y" | hermes skills install official/research/duckduckgo-search
```

验证：`hermes chat -q "搜索测试"` 或者直接在会话中用 web_search。

## Step 3a: 文档 & 基础爬虫工具

安装文档处理工具：

```bash
# Pandoc — 万能文档格式转换
sudo apt-get install -y pandoc

# Scrapling 基础版 — Web 抓取解析 (Python)
~/.hermes/hermes-agent/venv/bin/pip install scrapling

# Marker-PDF — PDF 转 Markdown
~/.hermes/hermes-agent/venv/bin/pip install marker-pdf

# 安装官方 skill
echo "y" | hermes skills install official/research/scrapling
```

## Step 3b: Scrapling 增强 — Stealth 爬虫模式（可选）

当需要爬取 Cloudflare 保护或 JS 动态渲染的页面时，安装增强版：

```bash
# 安装 Scrapling 全功能版（含 Playwright 浏览器引擎）
~/.hermes/hermes-agent/venv/bin/pip install "scrapling[all]"

# 安装 Chromium 浏览器（stealth/dynamic 模式需要）
~/.hermes/hermes-agent/venv/bin/python3 -m playwright install chromium
```

验证三种爬虫模式：
```python
from scrapling.fetchers import Fetcher, DynamicFetcher, StealthyFetcher
# HTTP 模式：Fetcher.get(url) — 最快，静态页面
# Dynamic 模式：DynamicFetcher.fetch(url) — JS 渲染页面
# Stealth 模式：StealthyFetcher.fetch(url, solve_cloudflare=True) — 反爬绕过
```

创建便捷爬虫脚本 `~/.hermes/scripts/scrapling-fetch.py`（参见 references/scrapling-setup.md），支持：

```bash
# HTTP 模式
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py <url>
# Stealth 模式（Cloudflare 绕过）
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py <url> --stealth
# JS 动态渲染
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py <url> --dynamic
# 带代理
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py <url> --proxy http://proxy:8080
# CSS 选择器提取特定内容
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/scrapling-fetch.py <url> --css-selector '.content'
```

## Step 4: Memory 升级

Hermes 有 8 个外部记忆提供者，当前活跃的是 **Holographic**（免费、零依赖），但对标 Baidu 文章推荐的「向量数据库+记忆图谱」架构，**Hindsight** 更贴合。

### 推荐：Holographic（本地、零依赖、已启用）

```bash
hermes memory setup holographic
hermes memory status
# → Provider: holographic, Plugin: installed ✓, Status: available ✓
```

SQLite + FTS5 全文搜索 + 代数向量 (HRR) + 信任评分。纯本地，零外部依赖。

### 增强选项：Hindsight（知识图谱 + 实体解析）

Hindsight 提供 **知识图谱** 驱动的跨会话记忆，核心增益：

| 能力 | Holographic | Hindsight |
|---|---|---|
| 存储引擎 | SQLite + FTS5 | **知识图谱** + PostgreSQL |
| 检索策略 | 全文搜索 + 代数向量 | **多策略组合**（语义+图谱+实体） |
| 实体感知 | probe/reason 按实体查 | **自动实体解析**，建立关系边 |
| 跨记忆综合 | 无 | **hindsight_reflect** — 跨会话综合推理 |
| 会话保留 | 手动存事实 | **自动保留**完整对话轮次 + 工具调用 |
| 依赖 | 纯 SQLite | Cloud: API key / Local: LLM API key |
| 费用 | 免费 | Cloud: 按量 / Local: 免费 |

**两种模式：**

**Cloud 模式**（需 API key）：
```bash
# 注册 → https://ui.hindsight.vectorize.io 拿 key
echo "HINDSIGHT_API_KEY=your-key" >> ~/.hermes/.env
hermes config set memory.provider hindsight
hermes memory setup    # 交互式选 hindsight → cloud
```

**Local 模式**（免费，只需已有的 LLM API key）：
```bash
hermes config set memory.provider hindsight
hermes memory setup    # 交互式选 hindsight → local
# 自动装 hindsight-all + 嵌入式 PostgreSQL，无需手动部署
```

Hindsight 自动管理嵌入式 PostgreSQL，无需 Docker 或单独 PG 服务。实体提取用的 LLM 走你已有的 API key（OpenRouter/OpenAI 等）。

**关键配置**（`~/.hermes/hindsight/config.json`）：

| 参数 | 默认值 | 说明 |
|---|---|---|
| `mode` | `cloud` | `cloud` 或 `local` |
| `recall_budget` | `mid` | 检索召回强度：`low` / `mid` / `high` |
| `memory_mode` | `hybrid` | `hybrid`（注入+工具）、`context`（只注入）、`tools`（只工具） |
| `auto_retain` | `true` | 自动保留对话轮次入库 |
| `auto_recall` | `true` | 每次轮次前自动召回相关记忆 |

**如何选择：**
- 已有 LLM API key + 想要知识图谱推理 → **Hindsight Local**（免费，零额外成本）
- 纯本地、不需要实体关联 → **Holographic**（现有的，够用）
- 想要跨会话 `reflect` 综合推理 → **Hindsight**（这是它的独家能力）

## Step 5: 成本控制精细化

### 5a. 免费模型优先策略

主模型应优先使用免费额度模型（如 `owl-alpha:free`、`glm-4-flash`、`qwen3-coder:free`），仅在复杂推理任务时切换到付费模型。用户可在会话中用 `-m` 参数临时切换：

```bash
hermes -m glm-4-flash    # 简单任务，零成本
hermes                    # 默认 owl-alpha（免费）
hermes -m deepseek/deepseek-v4-flash  # 复杂任务，按需付费
```

**按任务类型路由模型**是最大化免费额度的关键：70% 的简单查询/状态检查走免费模型，只有 30% 复杂任务走付费模型，长期可降低 50%+ token 消耗。

### 5b. System Prompt 瘦身

SOUL.md 和 system prompt 中的固定内容（角色描述、行为规则、技能列表）在每个请求中重复发送，是最大的固定开销。

**优化方法**：
- SOUL.md 控制在 700 字节以内（去掉冗余描述、emoji 装饰、重复规则）
- 合并多个检查命令为一次 SSH/Python 调用，减少 tool call 次数
- 减少不必要的 skill 加载——98 个 skill 的描述列表在 system prompt 中占空间

### 5c. Memory 与上下文收紧

```bash
hermes config set memory.memory_char_limit 1500    # 默认 2200，收紧减少注入
hermes config set memory.user_char_limit 800       # 默认 1375
hermes config set agent.max_turns 80               # 默认 150，防止长对话膨胀
```

### 5d. 压缩配置调优

```yaml
compression:
  enabled: true
  threshold: 0.4    # 默认 0.5，更早触发压缩
  target_ratio: 0.2
```

### 5e. 用户行为建议

- **及时 `/reset`**：任务完成后重置会话，避免上下文膨胀。300+ 消息的会话可烧 3M+ tokens
- **不相关话题用 `/new`**：每个话题开新 session，避免无关上下文累积
- 说"直接做"时跳过分析过程，减少输出 token

旧版 5 步（delegation 路由 + 成本显示）：

将子任务 delegation 从主模型路由到免费模型：

```bash
hermes config set delegation.model glm-4-flash
hermes config set delegation.provider zai
```

启用 Token 消耗和成本显示：

```bash
hermes config set show_token_analytics true
hermes config set show_cost true
```

辅助模型分层已经在 z.AI 免费模型上：
- 视觉分析 → GLM-4V-Flash
- 上下文压缩 → GLM-4-Flash
- 会话摘要/标题 → GLM-4-Flash
- 搜索理解/web_extract → GLM-4-Flash
- 技能搜索/分类/策展 → GLM-4-Flash
- Token 分析 → 启用后显示每轮消耗
- 成本显示 → 启用后显示每轮预估成本

## Step 6: 生态技能 & 插件安装

### 生态技能

安装最实用的官方 MLOps skills：

```bash
echo "y" | hermes skills install "official/research/duckduckgo-search"
echo "y" | hermes skills install "official/research/scrapling"
echo "y" | hermes skills install "official/mlops/inference/outlines"
echo "y" | hermes skills install "official/mlops/chroma"
echo "y" | hermes skills install "official/mlops/guidance"
echo "y" | hermes skills install "official/mlops/training/axolotl"
echo "y" | hermes skills install "official/mlops/accelerate"
echo "y" | hermes skills install "official/mlops/training/trl-fine-tuning"
echo "y" | hermes skills install "official/mlops/clip"
```

### 插件

启用内置插件：

```bash
hermes plugins enable disk-cleanup   # 自动清理临时文件
```

## Step 7: 性能基准测试

执行基准测试验证配置效果。`~/.hermes/scripts/benchmark.py` 脚本会用 10 个标准问答测试 Hermes 响应速度和可用性：

```bash
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/benchmark.py [--count N]
```

默认跑 5 轮，可指定 `--count 20` 跑更多。结果保存到 `~/.hermes/benchmark-report.json`。

典型结果参考（DeepSeek V4 Flash via OpenRouter）：
- 100% 成功率
- 平均响应 35-45s（包含 API 网络延迟）
- 简单查询 ~20s，复杂解释 ~45s

## 验证

```bash
hermes config       # 检查所有配置
hermes doctor       # 检查依赖和连通性
hermes memory status # 确认 Holographic 已激活
hermes plugins list  # 确认插件状态
hermes mcp list      # 确认 MCP 服务器状态

# 验证 Python 包已安装在 Hermes venv（而非系统 Python）
VENV=~/.hermes/hermes-agent/venv
$VENV/bin/python3 -c "
import importlib
for mod in ['scrapling', 'duckduckgo_search', 'marker', 'faster_whisper', 'edge_tts']:
    spec = importlib.util.find_spec(mod)
    print(f'{mod}: {\"✓\" if spec else \"✗\"}')
"

# 验证 scrapling 增强版
$VENV/bin/python3 -c "
from scrapling.fetchers import StealthyFetcher, DynamicFetcher
print('Scrapling[all]: ✓ (stealth + dynamic ready)')
"
```

最终架构：

```
用户输入
  │
  ├─▶ DeepSeek V4 Flash (OpenRouter — 付费)  主推理（显示 Token + 成本）
  │      │
  │      ├─ 搜索 → DuckDuckGo (零成本)
  │      ├─ 爬虫 → Scrapling (HTTP/Stealth/Dynamic)
  │      ├─ 视觉分析 → GLM-4V-Flash (免费)
  │      └─ 任务委派 → GLM-4-Flash (免费)
  │
  └─▶ 全部辅助任务 → GLM-4-Flash (z.AI 免费)
       压缩/摘要/标题/搜索理解/分类/策展/MCP
```

## 未配置（按需启用）

- Telegram/Discord 网关 — `hermes gateway setup`
- Exa/Tavily/Firecrawl 付费搜索 — 需要 API key
- STT/TTS — 已装 faster-whisper + Edge TTS（按需启用 `tts.provider edge`）
- FAL/Anthropic — 需要 API key
- ComfyUI 本地生图 — 需要 GPU

## Pitfalls

- **`pip install` 默认装到系统 Python，不是 Hermes venv** — Hermes 运行时用 `~/.hermes/hermes-agent/venv/`。安装包必须加 venv 前缀：
  ```bash
  ~/.hermes/hermes-agent/venv/bin/pip install scrapling marker-pdf faster-whisper
  ```
- **包验证也要用 venv 的 Python** — `python3 -c "import X"` 查的是系统 Python，会误报「未安装」。正确的检查方式：
  ```bash
  ~/.hermes/hermes-agent/venv/bin/python3 -c "import importlib.util; print(importlib.util.find_spec('scrapling'))"
  ```
- **faster-whisper 首次 import 会下载模型** (~500MB) — 可能 hang 几十秒。用 `importlib.util.find_spec()` 做快速存在性检查
- **`scrapling[all]` 安装 Playwright** — 首次安装后必须运行 `python3 -m playwright install chromium`，否则 StealthyFetcher 和 DynamicFetcher 会报错
- **`hermes skills install` 会提示确认** — 用 `echo "y" | hermes skills install <id>` 管道注入可跳过
- **SOUL.md 内容修改即时生效**，无需重启（但当前会话可能需 /reset 才能看到变化）
- **`display.personality` 留空不影响 SOUL.md 加载** — SOUL.md 只要有内容就自动生效，不需要设置 config
- **delegation 走免费模型意味着子任务只能做轻量推理**，不能处理复杂代码生成（需要切换回主模型）
- **`hermes config get <key>` 不是合法命令** — 用 `grep <key> ~/.hermes/config.yaml` 或 `hermes config show` 查看
- **Hindsight 记忆有两种模式** — Cloud 模式需要 API key（`ui.hindsight.vectorize.io`），Local 模式免费且无需额外 API key（用已有 LLM key 即可），自动管理嵌入式 PostgreSQL，无需 Docker 或 uv
- **MCP 服务器状态可能跨会话自动恢复** — 上次报错不一定代表当前仍坏，执行前先 `hermes mcp list` 确认实际状态
- **用户偏好：逐个执行确认** — 本用户要求每步执行前用 `clarify()` 展示选项，不做批量自动化。这是刻意的工作流选择