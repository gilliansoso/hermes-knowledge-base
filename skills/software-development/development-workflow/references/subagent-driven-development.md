# Subagent-Driven Development (SDD)

Execute implementation plans by dispatching fresh subagents per task with systematic two-stage review.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration.

## When to Use

- You have an implementation plan (from writing-plans skill)
- Tasks are mostly independent
- Quality and spec compliance are important
- You want automated review between tasks

## The Process

### 1. Read and Parse Plan

Read the plan once. Extract ALL tasks with full text. Create a todo list. Provide full task text in context — don't make subagents read the plan file.

### 2. Per-Task Workflow

For EACH task:

#### Step 1: Dispatch Implementer Subagent

```python
delegate_task(
    goal="Implement Task N: [name]",
    context="Full task text including file paths, code examples, TDD instructions",
    toolsets=['terminal', 'file']
)
```

Include: task spec from plan, project context, exact commands, expected output.

#### Step 2: Dispatch Spec Compliance Reviewer

```python
delegate_task(
    goal="Review if implementation matches the spec",
    context="List of requirements to check with CHECKLIST",
    toolsets=['file']
)
```

Pass/fail verdict. If fail, implementer fixes, reviewer re-reviews.

#### Step 3: Dispatch Code Quality Reviewer

```python
delegate_task(
    goal="Review code quality",
    context="Files to review with checklist: conventions, error handling, naming, test coverage, security",
    toolsets=['file']
)
```

Reports: Critical Issues (must fix), Important Issues (should fix), Minor Issues (optional), Verdict: APPROVED or REQUEST_CHANGES.

#### Step 4: Mark Complete

```python
todo([{"id": "task-N", "content": "...", "status": "completed"}], merge=True)
```

### 3. Final Integration Review

After ALL tasks complete, dispatch a final reviewer for component consistency and integration.

### 4. Verify and Commit

```bash
pytest tests/ -q
git diff --stat
git add -A && git commit -m "feat: complete [feature] implementation"
```

## Efficiency Notes

**Fresh subagent per task:** prevents context pollution. Each subagent gets clean, focused context. No confusion from prior tasks.

**Two-stage review:** spec review catches under/over-building early. Quality review ensures well-built code.

## Red Flags — Never Do These

- Start implementation without a plan
- Skip reviews (either stage)
- Proceed with unfixed critical issues
- Dispatch multiple implementation subagents that touch the same files
- Make subagent read the plan file (provide full text in context instead)
- Skip scene-setting context
- Accept "close enough" on spec compliance

## Handling Issues

- **Subagent asks questions**: answer clearly and completely
- **Reviewer finds issues**: implementer fixes, reviewer re-reviews
- **Subagent fails**: dispatch a new fix subagent with specific instructions