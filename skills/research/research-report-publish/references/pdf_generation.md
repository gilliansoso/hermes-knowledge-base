# Chinese PDF Generation with Reportlab (No LaTeX)

## Environment Assumptions

- Ubuntu server, no root access, no LaTeX
- Python 3.12+ with pip3
- WenQuanYi font pre-installed at `/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc`

## Install

```bash
pip3 install --break-system-packages reportlab
```

## Font Registration

```python
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

pdfmetrics.registerFont(TTFont('WQY', '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', subfontIndex=0))
pdfmetrics.registerFont(TTFont('WQYBold', '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', subfontIndex=0))
```

Note: WenQuanYi doesn't have a separate bold face. Use the same file for both.

## Style Naming — CRITICAL

reportlab's `getSampleStyleSheet()` pre-defines these names:
`BodyText`, `Bullet`, `Code`, `Definition`, `Heading1-6`, `Italic`, `Normal`, `OrderedList`, `Title`, `UnorderedList`

**You CANNOT redefine them.** Use prefixed names:

| Purpose | Use This | NOT This |
|---------|----------|----------|
| Report title | `RTitle` | `Title` |
| H1 heading | `RH1` | `Heading1` |
| H2 heading | `RH2` | `Heading2` |
| H3 heading | `RH3` | `Heading3` |
| Body text | `RBody` | `BodyText` / `Normal` |
| Bullet list | `RBullet` | `Bullet` |
| Code block | `RCode` | `Code` |
| Blockquote | `RBlockquote` | — |
| Table header | `RTableHeader` | — |
| Table cell | `RTableCell` | — |
| Footer | `RFooter` | — |

## Minimal Working Template

```python
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.lib.colors import HexColor, grey, white
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# Register font
pdfmetrics.registerFont(TTFont('WQY', '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', subfontIndex=0))
pdfmetrics.registerFont(TTFont('WQYBold', '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', subfontIndex=0))

# Colors
PRIMARY = HexColor('#1a5276')
SECONDARY = HexColor('#2e86c1')

# Build styles (use R-prefixed names!)
styles = {}
styles['title'] = ParagraphStyle('RTitle', fontName='WQYBold', fontSize=22, leading=30,
    textColor=PRIMARY, alignment=TA_CENTER, spaceAfter=6*mm)
styles['h1'] = ParagraphStyle('RH1', fontName='WQYBold', fontSize=16, leading=22,
    textColor=PRIMARY, spaceBefore=10*mm, spaceAfter=4*mm)
styles['h2'] = ParagraphStyle('RH2', fontName='WQYBold', fontSize=13, leading=18,
    textColor=SECONDARY, spaceBefore=6*mm, spaceAfter=3*mm)
styles['body'] = ParagraphStyle('RBody', fontName='WQY', fontSize=10, leading=16,
    alignment=TA_JUSTIFY, spaceAfter=2*mm)
# ... etc

# Build doc
doc = SimpleDocTemplate('output.pdf', pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm, topMargin=2.5*cm, bottomMargin=2*cm)
doc.build(story)
```

## Markdown Parsing Tips

- Strip `**bold**` → `<b>bold</b>` (reportlab supports basic HTML in Paragraph)
- Strip `` `code` `` → `<font color="red">code</font>`
- Tables: parse `|` delimited rows, skip separator lines (`|---|---|`)
- Blockquotes: lines starting with `>`
- Horizontal rules: `---` → `HRFlowable`
- Code blocks: between ` ``` ` markers

## Page Footer

```python
def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont('WQY', 8)
    canvas.setFillColor(grey)
    canvas.drawCentredString(A4[0]/2, 1*cm, f'- {canvas.getPageNumber()} -')
    canvas.restoreState()

doc.build(story, onFirstPage=footer, onLaterPages=footer)
```
