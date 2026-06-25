---
name: baoyu-skills
description: "Baoyu visual content generation: article illustrations, knowledge comics, infographics. Common workflow: analyze → confirm → prompts → image_generate → download."
tags: [baoyu, creative, image-generation, illustration, comic, infographic, visual-summary]
---

# Baoyu Skills — Visual Content Generation

Consolidated skills from the [baoyu-skills](https://github.com/JimLiu/baoyu-skills) suite. All three sub-skills share the same core pipeline: **analyze content → confirm settings → generate prompts → run image_generate → download results**.

## Common Principles (All Sub-Skills)

1. **Data integrity** — never summarize or paraphrase source statistics. "73% increase" stays "73% increase".
2. **Strip secrets** — scan source content for API keys, tokens, or credentials before writing any output file.
3. **Prompt files are mandatory** — save every prompt before calling `image_generate`. Prompt files are the reproducibility record.
4. **Download generated images** — `image_generate` returns a URL, not a local file. Always download via `curl -fsSL` with an **absolute path** to avoid CWD drift.
5. **Aspect ratio mapping** — `landscape` (16:9), `portrait` (9:16), `square` (1:1). Custom ratios map to nearest named option.
6. **No backend selection** — `image_generate` uses the user-configured backend. Do not write model names into prompts expecting them to route.
7. **Use absolute paths for `curl -o`** — never rely on persistent-shell CWD across batches. Files land in wrong directory with no error message.

## Sub-Skill A: Article Illustrator

**Trigger**: User asks to illustrate an article, add images, or "为文章配图".

**Three dimensions**:
| Dimension | Controls | Examples |
|-----------|----------|----------|
| Type | Information structure | infographic, scene, flowchart, comparison, framework, timeline |
| Style | Rendering approach | notion, warm, minimal, blueprint, watercolor, elegant |
| Palette | Color scheme (optional) | macaron, warm, neon |

**Workflow**:
1. Detect reference images (vision_analyze for style extraction)
2. Analyze content → analysis.md
3. Confirm settings (clarify: preset/type, density, style, palette, language)
4. Generate outline → outline.md
5. Generate prompts → prompts/*.md (one per illustration)
6. Generate images via image_generate + download with absolute path
7. Insert image references into article

**Output**: {article-dir}/imgs/ or illustrations/{topic-slug}/

Full details: references/article-illustrator/

## Sub-Skill B: Knowledge Comic

**Trigger**: User asks to create a comic, "知识漫画", educational comic, biography comic.

**Options**:
| Option | Values |
|--------|--------|
| Art | ligne-claire (default), manga, realistic, ink-brush, chalk, minimalist |
| Tone | neutral, warm, dramatic, romantic, energetic, vintage, action |
| Layout | standard, cinematic, dense, splash, mixed, webtoon, four-panel |
| Aspect | 3:4 (default), 4:3, 16:9 |
| Language | auto, zh, en, ja, etc. |

**Presets**: ohmsha, wuxia, shoujo, concept-story, four-panel

**File structure**: comic/{topic-slug}/ with characters/, prompts/, refs/ subdirs

**Workflow**:
1. Setup & Analyze → analysis.md, source-{slug}.md
2. Confirm style/focus/audience (Step 2 confirmation is required — do not skip)
3. Generate storyboard + characters → storyboard.md, characters/characters.md
4. Review outline (conditional)
5. Generate prompts → prompts/*.md (one per page)
6. Review prompts (conditional)
7. Generate images: character sheet (optional) + pages
8. Completion report

**Important**: Character consistency is driven by text descriptions in characters.md, not by the PNG. Embed character descriptions inline in every page prompt.

Full details: references/comic/

## Sub-Skill C: Infographic Generator

**Trigger**: User asks to create an infographic, "信息图", "可视化".

**Two dimensions**: layout x style — freely combinable.

**Layouts** (21): linear-progression, binary-comparison, comparison-matrix, hierarchical-layers, tree-branching, hub-spoke, structural-breakdown, bento-grid, iceberg, bridge, funnel, isometric-map, dashboard, periodic-table, comic-strip, story-mountain, jigsaw, venn-diagram, winding-roadmap, circular-flow, dense-modules

**Styles** (21): craft-handmade, claymation, kawaii, storybook-watercolor, chalkboard, cyberpunk-neon, bold-graphic, aged-academia, corporate-memphis, technical-schematic, origami, pixel-art, ui-wireframe, subway-map, ikea-manual, knolling, lego-brick, pop-laboratory, morandi-journal, retro-pop-grid, hand-drawn-edu

**Workflow**:
1. Analyze content → analysis.md, source-{slug}.{ext}
2. Generate structured content → structured-content.md
3. Recommend layout x style combinations (or use keyword shortcuts)
4. Confirm with user
5. Generate prompt → prompts/infographic.md
6. Generate image via image_generate + download
7. Summary report

Full details: references/infographic/