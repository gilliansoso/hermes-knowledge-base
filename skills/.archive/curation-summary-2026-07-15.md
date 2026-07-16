# Curation Summary — 2026-07-15

## Overview

Consolidated 10 narrow skills into 5 class-level umbrellas. The goal was to replace session- or tool-specific micro-skills with broader, discoverable umbrella skills organized by domain and workflow.

## Consolidations Performed

### 1. ASCII Art → ascii-video
- **from:** ascii-art (static ASCII tools: pyfiglet, cowsay, boxes, toilet, image-to-ascii)
- **into:** ascii-video (animated ASCII video production pipeline)
- **method:** Patched ascii-video SKILL.md with a "Static ASCII Art Tools" section + moved ascii-art's full content to `references/static-ascii-tools.md`
- **rationale:** Both serve the same class — "ASCII visual media." Static banners and borders are a natural subsection of an ASCII video pipeline; video projects often use static ASCII assets for title cards, overlays, and text elements.

### 2. Systematic Debugging → development-workflow
- **from:** systematic-debugging (4-phase root cause investigation)
- **into:** development-workflow (full software dev lifecycle)
- **method:** Added "Systematic Debugging" as section 6 of development-workflow, moved all reference files to `references/debugging/`
- **rationale:** Debugging is a natural phase of the development lifecycle. The same maintainer would write one "Software Development" skill with a debugging subsection rather than two separate skills.

### 3. Media Platform APIs → new umbrella
- **from:** gif-search, spotify, youtube-content
- **into:** media-platform-apis (new umbrella)
- **method:** Created new umbrella with labeled subsections for each platform
- **rationale:** All three wrap media content retrieval APIs with the same auth+query workflow pattern. A maintainer would write one "Media Platform APIs" skill with per-platform subsections, not three separate curl-reference skills.

### 4. Social Platform Integrations → new umbrella
- **from:** xurl, yuanbao, chinese-messaging-gateway
- **into:** social-platform-integrations (new umbrella)
- **method:** Created new umbrella with labeled subsections for X/Twitter, Yuanbao, and Chinese messaging platforms
- **rationale:** All three are social/messaging platform API integrations. A maintainer handling platform-specific integrations would write one umbrella covering all social platforms rather than three separate skills.

### 5. Gaming Setup & Play → new umbrella
- **from:** minecraft-modpack-server, pokemon-player
- **into:** gaming-setup-and-play (new umbrella)
- **method:** Created new umbrella with labeled subsections for Minecraft server setup and Pokemon headless emulation
- **rationale:** Both are gaming-related CLI-driven experiences. A maintainer organizing gaming-related agent skills would group them under one umbrella rather than scattering them.

## Skills Left Unchanged

The following skills were evaluated and kept as-is because they are already class-level umbrellas or genuinely distinct from their neighbors:

- **hermes-* skills** (hermes-agent, hermes-hardening, hermes-model-routing, etc.) — already well-structured as a knowledge base + specialized sub-skills
- **kanban-orchestrator + kanban-worker** — already designed as a coordinated pair
- **creative/design tools** (architecture-diagram, claude-design, design-md, excalidraw, p5js, pretext, popular-web-designs, baoyu-skills, manim-video, pixel-art) — each is a genuinely different medium with distinct toolchains
- **research tools** (arxiv, blogwatcher, polymarket, scrapling, research-paper-writing, research-report-publish) — different data sources with different APIs and workflows
- **MLOps/ML tools** (dspy, chroma, guidance, outlines, llama-cpp, obliteratus, weights-and-biases, huggingface-hub) — each is a distinct framework/product with its own CLI and API surface
- **productivity tools** (google-workspace, himalaya, maps, linear, notion, airtable, ocr-and-documents, powerpoint) — each is a different service integration
- **smart home** (openhue) — standalone
- **note-taking** (obsidian, llm-wiki) — different tools with different workflows
- **data science** (chinese-futures-data, jupyter-live-kernel) — different domains
- **misc** (godmode, dogfood, humanizer, songsee, songwriting-and-ai-music, teams-meeting-pipeline, webhook-subscriptions, native-mcp, comfyui, touchdesigner-mcp, proxy-server-setup, claude-code, codebase-inspection, github-workflows, auto-experience-doc, duckduckgo-search, etc.) — class-level or standalone