---
name: research-report-publish
description: "Use when generating market research reports and publishing to multiple platforms (PDF, GitHub, messaging). Covers: multi-source web research, structured report writing in Chinese/English, PDF generation without LaTeX (reportlab + WenQuanYi), GitHub repo creation via API, and WeChat delivery."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, report, pdf, github, publish, chinese]
    related_skills: [auto-experience-doc, github-repo-management]
---

# Research Report Generation & Multi-Platform Publishing

## Overview

End-to-end workflow for producing professional market research reports and distributing them across platforms. Born from a session producing the "亚太市场命理风水与八字咨询服务需求空间调研报告".

## When to Use

- User asks for a "调研报告", "market research", "industry analysis", or similar
- Report needs to be delivered as PDF + source + pushed to GitHub
- Report contains Chinese text (requires special font handling)
- Multi-source web research needs to be synthesized into structured output

## Workflow

### 1. Research Phase

- Use `web_search` with targeted queries per market/segment
- Run **parallel searches** — fire 3-5 queries simultaneously using multiple tool calls in one turn
- For each market, search: market size, growth rate, key players, regulation
- Extract data from results; note source credibility (high/medium/low)
- **Merge commands**: When checking server status, combine multiple checks into one SSH call rather than separate calls

### 2. Writing Phase

- Write in Markdown first (easier to edit and convert)
- Structure: Executive Summary → Sections → SWOT → Strategic Recommendations → Appendix
- For Chinese reports: use Chinese headings, keep technical terms in English
- Mark all estimates clearly as "估算值" or "行业共识区间"
- Include a data source table at the end

### 3. PDF Generation

**Server environment has no LaTeX** (no xelatex, no wkhtmltopdf). Use reportlab + WenQuanYi font.

Key technical details:
- Font: `/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc` (register with `TTFont`, subfontIndex=0)
- Install reportlab: `pip3 install --break-system-packages reportlab`
- **Style name conflicts**: reportlab's sample stylesheet already defines `Bullet`, `Code`, `Heading1-3`, `Title`, `BodyText`, `Normal`. Use custom names like `RTitle`, `RH1`, `RBody`, `RBullet`, `RCode`, `RTableHeader`, `RTableCell`, `RBlockquote`.
- Page setup: A4, 2cm margins, page numbers in footer
- Tables: Use `Table` + `TableStyle` with alternating row colors
- See `references/pdf_generation.md` for the working script template

### 4. GitHub Publishing

- Create new repo via GitHub API: `curl -X POST https://api.github.com/user/repos`
- Use git credential helper (already configured at `~/.git-credentials`)
- Push: `git push -u origin main`
- If `gh` CLI is not authenticated, use `curl` + token from `~/.git-credentials`

### 5. Messaging Delivery

- Use `send_message` to deliver summary + links
- For WeChat: include GitHub link and local file path
- Keep message concise — bullet points, not paragraphs

## Common Pitfalls

1. **PDF style name collision** — reportlab sample styles conflict with common names. Always prefix custom styles (e.g., `RTitle` not `Title`).
2. **No LaTeX on server** — don't waste time trying pandoc+xelatex or installing texlive. Use reportlab directly.
3. **Font not found** — check `fc-list :lang=zh` for available CJK fonts. WenQuanYi is usually pre-installed on Ubuntu.
4. **gh CLI not authenticated** — use `curl` + GitHub API with token from `~/.git-credentials` instead.
5. **Over-optimization** — user may say "算了" (forget it) if you present too many options. Offer the top 1-2 choices, not exhaustive lists.
6. **Memory tool instability** — `memory` tool may return errors for `list`/`probe`/`search` actions. Use `add`/`replace`/`remove` only. For cross-session recall, use `session_search` instead.

## Reference Files

- `references/pdf_generation.md` — Working reportlab script template for Chinese PDF generation
