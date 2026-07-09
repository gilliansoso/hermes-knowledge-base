# Sketch Mode — Throwaway HTML Mockups

Use when the user wants to **compare design directions before committing** to one. Generate 2-3 interactive variants as disposable HTML so the user can compare visual directions side-by-side.

## When to Sketch vs Full Design

| Dimension | Sketch Mode | Full Design |
|-----------|-------------|-------------|
| Artifact | Throwaway HTML | Polished artifact |
| Fidelity | System fonts, CDN Tailwind, rough edges | Carefully crafted, custom type |
| Interactivity | One meaningful click/hover/toggle | Full state coverage |
| Output | 2-3 variants + comparison table | One consolidated direction |
| Lifespan | Deleted after decision | Preserved for production |

**Sketch when:** "show me what X could look like", "compare layout A vs B", "give me 2-3 takes", "mockup this before I build".

## Method

```
intake → variants → head-to-head → pick winner (or iterate)
```

### 1. Intake
Before generating, get three things (one question at a time):
1. **Feel** — "What should this feel like? Adjectives, emotions, a vibe."
2. **References** — "What apps, sites, or products capture the feel?"
3. **Core action** — "What's the single most important thing a user does on this screen?"

### 2. Variants (2-3)
Each variant is a standalone HTML file with a **different design stance**:

- **Density:** compact / airy / ultra-dense
- **Emphasis:** content-first / action-first / tool-first
- **Aesthetic:** editorial / utilitarian / playful
- **Layout:** single-column / sidebar / split-pane

Naming: describe the stance, not the number:
```
sketches/001-calm-editorial/index.html
sketches/001-utilitarian-dense/index.html
```

### 3. Make Them Real HTML
- Single self-contained HTML file per variant
- Inline `<style>`, system fonts or one Google Font
- Tailwind CDN fine for speed
- **Realistic content** — actual sentences, not Lorem ipsum
- **Interactive** — at least one click/hover/toggle/state transition
- Verify with `browser_navigate` + `browser_vision` to catch layout bugs

### 4. Head-to-Head Comparison
Present as a comparison table with opinions:

| Dimension | Calm editorial | Utilitarian dense |
|-----------|----------------|-------------------|
| Density | Low | High |
| Primary action | Low visibility | High visibility |
| Feel | Calm, trusted | Sharp, tool-like |

Let the user pick a winner, combine two, or ask for another round.

## Output Structure
```
sketches/
├── 001-calm-editorial/
│   ├── index.html
│   └── README.md
├── 002-utilitarian-dense/
│   ├── index.html
│   └── README.md
└── themes/tokens.css (optional shared tokens)
```