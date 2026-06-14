# Test-Driven Development (absorbed from standalone `test-driven-development` skill)

## The Iron Law
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

## Red-Green-Refactor Cycle

### RED — Write Failing Test
- One behavior per test
- Clear descriptive name (no "and" in name)
- Real code, not mocks
- Name describes behavior, not implementation

### Verify RED — Watch It Fail (MANDATORY)
```bash
pytest tests/test_feature.py::test_behavior -v
```
Confirm: test fails for expected reason, not error from typos.

### GREEN — Minimal Code
Write simplest code to pass. Nothing more. Cheating is OK (hardcode, copy-paste, skip edge cases).

### Verify GREEN — Watch It Pass (MANDATORY)
```bash
pytest tests/ -q  # all tests, check for regressions
```

### REFACTOR — Clean Up
Remove duplication, improve names, extract helpers. Keep tests green throughout.

## Common Rationalizations (all invalid)
- "Too simple to test" — simple code breaks
- "I'll test after" — tests passing immediately prove nothing
- "Already manually tested" — ad-hoc ≠ systematic
- "Keep as reference, write tests first" — you'll adapt it
- "TDD will slow me down" — TDD is faster than debugging

## Integration
- Bug found? Write failing test reproducing it first, THEN fix
- Use dbugging skill alongside TDD when investigating failures
