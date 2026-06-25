---
name: development-workflow
description: "Complete development lifecycle: TDD, subagent-driven execution, pre-commit review gates. Write tests first, execute via subagents with two-stage review, verify before commit."
tags: [development, workflow, tdd, subagent, code-review, verification, quality]
---

# Development Workflow

The complete software development lifecycle: from writing tests through subagent execution to pre-commit verification.

## Core Principle: TDD First

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.** Write the test. Watch it fail. Write minimal code. Watch it pass. Refactor.

See the full TDD playbook in `references/test-driven-development.md`.

## Lifecycle Overview

```
Plan (writing-plans)
  → TDD cycle (test-first, minimal code, refactor)
  → Subagent-driven execution (fresh agent per task)
  → Pre-commit verification (static scan + reviewer)
  → Commit
```

## 1. Test-Driven Development (TDD)

### The Iron Law
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

### Red-Green-Refactor Cycle

**RED** — Write one minimal failing test:
```python
def test_retries_failed_operations_3_times():
    attempts = 0
    def operation():
        nonlocal attempts
        attempts += 1
        if attempts < 3:
            raise Exception('fail')
        return 'success'
    result = retry_operation(operation)
    assert result == 'success'
    assert attempts == 3
```

**VERIFY RED** — Run the test, confirm it fails for expected reason.

**GREEN** — Write minimal code to pass. Cheating is OK in GREEN (hardcode, copy-paste, duplicate). Fix in REFACTOR.

**VERIFY GREEN** — Test passes. All other tests still pass.

**REFACTOR** — Clean up while keeping tests green.

### Anti-Patterns

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Deleting X hours is wasteful" | Sunk cost. Keeping unverified code is debt. |

If you catch yourself writing code before a test: delete the code. Start over with TDD.

---

## 2. Subagent-Driven Development (SDD)

Execute implementation plans by dispatching a fresh subagent per task with systematic two-stage review.

### Process

1. **Read and parse the plan** — extract all tasks, create a todo list
2. **Per-task workflow** (for EACH task):

   a. **Dispatch implementer** via `delegate_task` with full context including the exact code, file paths, and TDD instructions
   
   b. **Dispatch spec compliance reviewer** — verify the implementation matches the plan spec exactly
   
   c. **Dispatch code quality reviewer** — review for correctness, security, edge cases, style

   d. Only proceed to the next task when both reviews pass.

3. **Final integration review** — all tasks combined, consistency and test suite check
4. **Verify and commit**

### Efficiency Notes

- **Fresh subagent per task** prevents context pollution
- **Two-stage review** (spec compliance first, code quality second) catches issues early
- **Red flags**:
  - Starting implementation without a plan
  - Skipping reviews
  - Dispatching multiple implementation subagents for tasks touching the same files
  - Letting implementer self-review

### Handling Issues

- If a subagent asks questions: answer clearly and completely
- If a reviewer finds issues: implementer fixes, reviewer re-reviews
- If a subagent fails a task: dispatch a new fix subagent

Full details: `references/subagent-driven-development.md`

---

## 3. Pre-Commit Verification Review

Before any code lands: static scan, baseline tests, independent reviewer, auto-fix loop.

### Pipeline

```
1. Get the diff (git diff --cached)
2. Static security scan (secrets, SQL injection, shell injection, eval)
3. Baseline tests + linting (compare failures before vs after changes)
4. Self-review checklist
5. Independent reviewer subagent (returns JSON verdict)
6. Evaluate: pass or fail
7. Auto-fix loop (max 2 cycles)
8. Commit with [verified] prefix
```

### Static Scan Commands

```bash
# Hardcoded secrets
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token)\s*=\s*['\"][^'\"]{6,}['\"]"
# SQL injection
git diff --cached | grep "^+" | grep -E "execute\(f\"|\.format\(.*SELECT"
# Dangerous eval/exec
git diff --cached | grep "^+" | grep -E "\beval\(|\bexec\("
```

### Independent Reviewer

Call `delegate_task` with the full diff — the reviewer has NO shared context with the implementer. Returns JSON:

```json
{
  "passed": true/false,
  "security_concerns": [],
  "logic_errors": [],
  "suggestions": [],
  "summary": "one sentence verdict"
}
```

**Fail-closed**: security_concerns or logic_errors non-empty → passed must be false.

### Auto-Fix Loop

Max 2 fix-and-reverify cycles. Spawn a THIRD agent context that fixes ONLY reported issues. Re-run full verification after each fix cycle.

Full details: `references/pre-commit-review.md`

---

## References

- `references/test-driven-development.md` — Full TDD methodology with rationalizations and anti-patterns
- `references/subagent-driven-development.md` — Full SDD process with two-stage review examples
- `references/pre-commit-review.md` — Full verification pipeline with static scan, reviewer, and auto-fix
- `references/gates-taxonomy.md` — The four canonical gate types (Pre-flight, Revision, Escalation, Abort)
- `references/context-budget-discipline.md` — Context degradation model for large multi-phase runs