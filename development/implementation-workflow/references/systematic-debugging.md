# Systematic Debugging (absorbed from standalone `systematic-debugging` skill)

## The Iron Law
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

## Phase 1: Root Cause Investigation
1. Read error messages carefully — note line numbers, file paths, error codes
2. Reproduce consistently — if not reproducible, gather more data
3. Check recent changes — git diff, recent commits, new dependencies
4. Gather evidence in multi-component systems — log data at each boundary
5. Trace data flow — find where bad value originates, fix at source not symptom

## Phase 2: Pattern Analysis
1. Find working examples in same codebase
2. Compare against references — read completely, not skimmed
3. Identify ALL differences between working and broken
4. Understand dependencies

## Phase 3: Hypothesis and Testing
1. Form a single hypothesis: "I think X is root cause because Y"
2. Test minimally — ONE change at a time
3. Verify before continuing
4. When you don't know — say so

## Phase 4: Implementation
1. Create failing test case FIRST
2. Implement single fix addressing root cause
3. Verify (test passes, full suite no regressions)
4. Rule of Three: if 3+ fixes failed, STOP and question architecture

## Red Flags
- "Quick fix for now, investigate later" → STOP
- "Just try changing X and see if it works" → STOP
- "Multiple changes at once" → STOP
- "It's probably X, let me fix that" → STOP

## Hermes Integration
- search_files for tracing function calls and error strings
- read_file for precise source analysis
- terminal for running tests and git history
- web_search for error message research
- delegate_task for multi-component debugging investigations
