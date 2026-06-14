# Pre-Commit Code Verification (absorbed from standalone `requesting-code-review` skill)

## Core Principle
No agent should verify its own work. Fresh context finds what you miss.

## Step 1 — Get the diff
```bash
git diff --cached  # staged changes
```

## Step 2 — Static security scan
```bash
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token|passwd)\s*=\s*['\"][^'\"]{6,}['\"]"
git diff --cached | grep "^+" | grep -E "os\.system\(|subprocess.*shell=True|eval\(|exec\(|pickle\.loads?\("
```

## Step 3 — Baseline tests and linting
Stash changes, run tests/lint, pop. Only NEW failures block commit.

## Step 4 — Self-review checklist
- No hardcoded secrets
- Input validation on user-provided data
- Parameterized SQL queries
- Path traversal checks on file operations
- Error handling on external calls (try/catch)
- No debug print left behind
- No commented-out code
- New code has tests

## Step 5 — Independent reviewer subagent
Use delegate_task with only the diff + static scan results. The reviewer runs with zero shared context.

## Step 6-7 — Evaluate & Auto-fix
- All passed → commit with `[verified]` prefix
- Failures → fix agent (max 2 cycles), then re-verify
- After 2 failed cycles → escalate to user

## Safety Patterns
- SQL injection: parameterized queries, never string formatting
- Shell injection: subprocess.run with list, not shell=True
- XSS: textContent not innerHTML
