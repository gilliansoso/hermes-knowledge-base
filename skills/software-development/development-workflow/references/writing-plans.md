# Writing Implementation Plans

**Core principle:** A good plan makes implementation obvious. If someone has to guess, the plan is incomplete.

## Bite-Sized Tasks
Each task = 2-5 minutes of focused work. Every step is one action.
- **Too big:** "Build authentication system" (50 lines across 5 files)
- **Right size:** "Create User model with email field" (10 lines, 1 file)

## Plan Document Structure
Every plan starts with: Goal, Architecture, Tech Stack, then numbered tasks.

Each task includes:
- **Objective** — one sentence
- **Files** — exact paths (Create: `src/model.py`, Modify: `src/app.py:45-67`)
- **Steps** — write failing test → run to fail → write minimal code → run to pass → commit
- **Complete code examples** — copy-pasteable, not placeholders
- **Exact commands** with expected output

## Writing Process
1. **Understand requirements** — feature spec, acceptance criteria, constraints
2. **Explore the codebase** — structure, patterns, existing tests
3. **Design approach** — architecture, file organization, dependencies
4. **Write tasks** — setup → core (TDD) → edge cases → integration → cleanup
5. **Add complete details** — exact paths, full code, verification steps
6. **Review** — sequential? bite-sized? copy-pasteable? DRY/YAGNI/TDD?
7. **Save** — `docs/plans/YYYY-MM-DD-feature-name.md`

## Principles
- **DRY** — extract shared logic, don't copy-paste
- **YAGNI** — implement only what's needed now
- **TDD** — every code task includes the full Red-Green-Refactor cycle
- **Frequent commits** — after every task

## Plan Mode (No-Execution)
When `/plan` is used: write to `.hermes/plans/YYYY-MM-DD_HHMMSS-<slug>.md`
Include: Goal, assumptions, approach, step-by-step tasks, files to change, verification steps, risks.