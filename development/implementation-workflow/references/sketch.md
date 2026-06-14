# Sketch — Throwaway HTML Mockups (absorbed from standalone `sketch` skill)

## Core Method
```
intake → variants → head-to-head → pick winner (or iterate)
```

## 1. Intake (skip if user gave enough)
Ask one question at a time: (1) Feel/adjectives, (2) References, (3) Core action.

## 2. Variants (2-3, never 1)
Each variant takes a DIFFERENT design stance, not different pixel values:
- **Density:** compact / airy / ultra-dense
- **Emphasis:** content-first / action-first / tool-first
- **Layout:** single-column / sidebar / split-pane

## 3. Make them real HTML
- Single self-contained HTML file
- Tailwind via CDN fine
- Realistic fake content, not lorem ipsum
- Interactive: links clickable, hovers real, at least one state transition

**Verify with browser tools:**
```javascript
browser_navigate(url="file:///path/to/variant/index.html")
browser_vision(question="Layout clean? Any visible bugs?")
```

## 4. Head-to-head
Opinionated comparison table with dimensions. Give "my take" recommendation.

## 5. Output
Create sketches/NNN-stance-name/ with index.html + README.md.
Keep disposable — promote to real code if it deserves preservation.
