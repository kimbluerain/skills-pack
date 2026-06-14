# Spike — Throwaway Experiments (absorbed from standalone `spike` skill)

## Core Method
```
decompose → research → build → verdict
   ↑____________________________↓ iterate
```

## 1. Decompose
Break idea into 2-5 independent feasibility questions. Each is one spike.
Order by risk — hardest/riskiest spike first.

**Good spike:** "Given a WS connection, when LLM streams tokens, client receives chunks <100ms"
**Bad spike:** "Can we use websockets?" (too vague, no observable output)

## 2. Align
For multi-spike ideas, present table and ask user: "Build all in this order, or adjust?"

## 3. Research (per spike, before building)
Brief it, surface competing approaches, pick one. Use web_search, web_extract, terminal.

## 4. Build
One directory per spike under spikes/. Bias toward something interactive (CLI, HTML page, endpoint).
Test edge cases. Follow surprising findings.

## 5. Verdict
**VALIDATED** = core question answered yes with evidence
**PARTIAL** = works under constraints X, Y, Z
**INVALIDATED** = doesn't work — this is a SUCCESSFUL spike

## Comparison spikes
Build back-to-back, then head-to-head comparison table with dimensions and winner.

## Frontier mode
Look for integration risks, data handoffs, gaps, alternative approaches.
