# Simplify Code — Parallel Review & Cleanup (absorbed from standalone `simplify-code` skill)

## Core Principle
Three narrow reviewers beat one broad reviewer. Each searches for a single class of problem.

## Phase 1 — Identify changes
```bash
git diff            # uncommitted working-tree changes
git diff HEAD       # includes staged
git diff --staged   # staged only
git diff HEAD~1     # last commit
```

## Phase 2 — Launch three reviewers in parallel
Use delegate_task batch mode (all three in one tasks array):

1. **Code Reuse** — finds functionality that duplicates existing utilities; requires file:line evidence
2. **Code Quality** — redundant state, parameter sprawl, copy-paste-with-variation, leaky abstractions
3. **Efficiency** — unnecessary work, N+1 patterns, TOCTOU, missed concurrency, memory issues

## Phase 3 — Aggregate and apply
- Deduplicate overlapping findings
- Discard false positives (you have most context)
- Resolve conflicts: correctness > user's focus > readability > micro-perf
- Apply fixes, verify tests/lint still pass
- Summarize what changed

## Pitfalls
- Give WHOLE diff to each reviewer, not fragments
- Reviewers must search codebase (grep/search_files), not guess
- Apply ≠ rewrite — scope edits to what the diff touched
- Large diffs blow context — scope down before delegating
