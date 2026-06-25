# Pre-Commit Code Verification

Automated verification pipeline before code lands. Static scans, baseline-aware quality gates, an independent reviewer subagent, and an auto-fix loop.

**Core principle:** No agent should verify its own work. Fresh context finds what you miss.

## When to Use

- After implementing a feature or bug fix, before `git commit` or `git push`
- After each task in subagent-driven-development (the two-stage review)

**Skip for:** documentation-only changes, pure config tweaks, or when user says "skip verification".

**This vs github-code-review:** This verifies YOUR changes before committing. github-workflows > Code Review reviews OTHER people's PRs.

## Step 1 — Get the Diff

```bash
git diff --cached
```
If empty, try `git diff` then `git diff HEAD~1 HEAD`. Split by file if >15,000 chars.

## Step 2 — Static Security Scan

```bash
# Hardcoded secrets
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token)\s*=\s*['\"][^'\"]{6,}['\"]"
# Shell injection
git diff --cached | grep "^+" | grep -E "os\.system\(|subprocess.*shell=True"
# Dangerous eval/exec
git diff --cached | grep "^+" | grep -E "\beval\(|\bexec\("
# SQL injection
git diff --cached | grep "^+" | grep -E "execute\(f\"|\.format\(.*SELECT|\.format\(.*INSERT"
```

## Step 3 — Baseline Tests and Linting

Detect project language, capture baseline failures BEFORE your changes (stash changes, run, pop). Only NEW failures block the commit.

## Step 4 — Self-Review Checklist

- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input validation on user-provided data
- [ ] SQL queries use parameterized statements
- [ ] External calls have error handling (try/catch)
- [ ] No debug print/console.log/breakpoint() left behind
- [ ] New code has tests

## Step 5 — Independent Reviewer Subagent

Call `delegate_task` with the diff. The reviewer gets ONLY the diff and static scan results — no shared context with the implementer.

**Fail-closed rules:**
- security_concerns non-empty → passed must be false
- logic_errors non-empty → passed must be false
- Cannot parse diff → passed must be false

Returns JSON:
```json
{
  "passed": true/false,
  "security_concerns": [],
  "logic_errors": [],
  "suggestions": [],
  "summary": "one sentence verdict"
}
```

## Step 6 — Evaluate Results

**All passed:** proceed to commit. **Any failures:** report what failed, then proceed to auto-fix.

## Step 7 — Auto-Fix Loop

Max 2 fix-and-reverify cycles. Spawn a fix agent that fixes ONLY the reported issues. Re-run full verification after each fix.

## Step 8 — Commit

```bash
git add -A && git commit -m "[verified] <description>"
```

The `[verified]` prefix indicates an independent reviewer approved this change.