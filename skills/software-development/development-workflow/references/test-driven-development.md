# Test-Driven Development (TDD)

Full TDD methodology — absorbed into development-workflow umbrella.

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

## Red-Green-Refactor Cycle

### RED — Write Failing Test
Write one minimal test showing what should happen. One behavior per test. Clear descriptive name. Real code, not mocks.

### Verify RED — Watch It Fail
Run the specific test: `pytest tests/test_feature.py::test_specific_behavior -v`
Confirm it fails for expected reason (feature missing, not typo).

### GREEN — Minimal Code
Write the simplest code to pass. Cheating is OK in GREEN: hardcode, copy-paste, skip edge cases.

### Verify GREEN — Watch It Pass
Run the test. Then run all tests to check for regressions.

### REFACTOR — Clean Up
Remove duplication, improve names, extract helpers. Keep tests green throughout.

### Repeat
Next failing test for next behavior. One cycle at a time.

## Why Order Matters

Tests written after code pass immediately. Passing immediately proves nothing — they might test the wrong thing, test implementation not behavior, or miss edge cases.

Test-first forces you to see the test fail, proving it actually tests something.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |

## Testing Anti-Patterns

- **Testing mock behavior instead of real behavior** — mocks should verify interactions, not replace the system
- **Testing implementation details** — test behavior/results, not internal method calls
- **Happy path only** — always test edge cases, errors, and boundaries
- **Brittle tests** — tests should verify behavior, not structure

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without the user's explicit permission.