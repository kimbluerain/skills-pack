# Parallel Independent Workstreams — Worked Example

## Real Session: FilmStrip Cutter Fix

Three fully independent workstreams dispatched simultaneously via `delegate_task(tasks=[...])`:

### Tasks

```python
delegate_task(tasks=[
    {
        "goal": "Fix core algorithm — gap detection and frame boundary refinement",
        "context": "..."  # full diagnostic: wrong gaps detected, smoothing too aggressive,
                         # brightness analysis showing real vs false gap positions
        "toolsets": ["terminal", "file"]
    },
    {
        "goal": "Add tests + improve GUI — frame adjustment sliders, preview window",
        "context": "..."  # test coverage gaps, GUI code location, desired features
        "toolsets": ["terminal", "file"]
    },
    {
        "goal": "Verify on all 4 test images — generate previews, check aspect ratios",
        "context": "..."  # expected results, rejection criteria, full environment setup
        "toolsets": ["terminal", "file", "vision"]
    },
])
```

### Results

| Workstream | Duration | Outcome |
|-----------|----------|---------|
| Core algorithm fix | ~521s | Smoothing window 207→103, weights adjusted, gap validation added, DP tolerance widened |
| GUI + tests | ~308s | 6 new tests (26 total), 872-line GUI rewrite with slider + preview + progress |
| Verification | ~281s | 4/4 images verified, produced 24 output frames, identified remaining 003 issue |
| **Total real time** | **521s** (bounded by slowest) | — vs ~1110s if sequential |

### Key Techniques

1. **Shared context document** — Write a `IMPROVEMENT_PLAN.md` or similar ground-truth doc that all agents can reference. Include diagnostic data, file paths, environment setup.

2. **Disjoint file sets** — No two agents touch the same file:
   - Agent 1: `cutter/profile.py`, `cutter/engine.py`
   - Agent 2: `tests/test_engine.py`, `gui/main_window.py`
   - Agent 3: read-only verification (no file writes to source code)

3. **Cross-check after merge** — After all agents report success, run the full test suite and verify on all test images yourself. Combined changes can cause subtle regressions that neither agent experienced in isolation.

4. **Use `toolsets` as a guard** — Give verification/vision agents only `terminal` + `file` + `vision` so they can't accidentally modify code. Give coding agents `terminal` + `file` but not `vision` (reduces token overhead).

5. **Subagent summaries are self-reports** — When a subagent claims "Frame 4/5 now correctly detected", verify it yourself by running the tool. The verification agent did catch that Algorithm agent's fix wasn't perfect and escalated it.

### When NOT to use this

- Tasks share files → use sequential or API Contract pattern
- One task's output is another's input → chain them sequentially
- Tasks are trivial (1-2 tool calls) → just do them inline
