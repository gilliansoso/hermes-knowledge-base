---
name: auto-experience-doc
description: "Use when ending a task session — auto-generate an experience document, commit it to ~/.hermes-kb/, and push to GitHub."
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [automation, github, knowledge-base, post-task]
    related_skills: [github-repo-management, github-auth]
---

# Auto-Experience Document

## Overview

User `gilliansoso` has a knowledge base repo at `https://github.com/gilliansoso/hermes-knowledge-base` synced to `~/.hermes-kb/`. After every major task session, auto-generate a detailed experience document, fill it with real content from the session, commit, and push.

## Core Rule — No Asking

User explicitly confirmed: **自动直接做** (auto-do, don't ask). Generate the experience document automatically at the end of every meaningful session. Do NOT ask "shall I generate an experience doc?" — just do it.

## When to Use

- **Always** at the end of a task session where meaningful work was done
- Especially after: debugging sessions, new integrations, configuration changes, or learning a new workflow
- Skip for: trivial Q&A, simple file edits, or interrupted sessions with no measurable outcome
- **Never ask the user** whether to generate — just generate and push

## Workflow

### 1. Generate the experience document (automatically, no prompt)

Determine the session topic (the main thing accomplished). Generate the file at:
`~/.hermes-kb/experience/<YYYY-MM-DD>-<short-topic>.md`

Fill in real content based on what happened in the session. Use the document template from `~/.hermes-kb/scripts/generate-experience.sh` as structure guidance, but write the actual content manually.

### 2. Sections to populate

| Section | What to write |
|---------|---------------|
| **Topic** | One-line session title |
| **Summary** | 2-3 paragraphs: what was accomplished, what approach was taken |
| **Key Learnings** | Specific technical insights, commands, configs discovered |
| **Skills Used / Created** | Skills loaded or created during the session |
| **Decisions Made** | Architecture/approach decisions and their rationale |
| **Pitfalls Encountered** | Errors, gotchas, and how they were fixed |
| **Next Steps / TODO** | Actionable follow-ups |

### 3. Commit and push

```bash
cd ~/.hermes-kb
git add -A
git commit -m "experience: add <YYYY-MM-DD>-<short-topic>"
git push origin main
```

### 4. Verify

Check that the repo on GitHub shows the new document:
`https://github.com/gilliansoso/hermes-knowledge-base/tree/main/experience/`

## Common Pitfalls

1. **Asking permission** — User explicitly confirmed: **never ask** whether to generate. Just do it automatically at session end and push.
2. **Empty template** — Don't just create the template with blank fields. Use knowledge from the session to write meaningful content in every section.
3. **Forgetting to push** — The commit alone doesn't upload it. Always run `git push`. If push fails, fix the error — don't silently drop the doc.
4. **Topic too vague** — "bug-fix" or "update" doesn't help future you. Use descriptive topics.
5. **Skipping on short sessions** — Even a 5-minute session with a useful config tweak deserves a doc. The smallest learnings compound fastest.

## Push Failure Recovery

### "rejected (fetch first)" — remote has diverged

This happens when another device/session pushed work while you had unpushed commits. **Never force push** — the remote may have valuable work.

```bash
# Step 1: commit any uncommitted changes first
cd ~/.hermes-kb
git add -A
git commit -m "changes before sync"

# Step 2: pull with rebase (linear history)
git pull --rebase origin main

# Step 3: push
git push origin main
```

If `git pull --rebase` fails with "Your index contains uncommitted changes":
→ Run `git add -A && git commit -m "..."` first, then retry.

### Git status reading guide

| Signal | Meaning | Action |
|---|---|---|
| ahead of origin/main by N commits | Local has unpushed commits | `git push` |
| rejected (fetch first) | Remote also has new commits | pull --rebase then push |
| ` M <file>` | Tracked, unstaged change | `git add` + commit |
| `?? <file>` | Untracked file | `git add -A` includes it |
| `A  <file>` | Staged, uncommitted | `git commit` |

## Reference Files

- `references/wechat-gateway-setup.md` — WeChat iLink Bot QR login flow for headless servers (from 2026-06-03 setup session)

## Related Artifacts

- `~/.hermes-kb/scripts/sync-skills.sh` — Daily cron script that pushes to same repo. Its git change-detection logic uses `git diff --quiet` after rsync; when the log file it redirects into is a tracked file, this can shadow the real skill-sync changes. If the script reports "No changes since last sync" but has a dirty git status, the log file self-modification is the probable cause.

## Verification Checklist

- [ ] File created at `~/hermes-kb/experience/<date>-<topic>.md`
- [ ] All sections populated with actual session content (not template placeholders)
- [ ] `git add`, `git commit`, `git push` all succeeded
- [ ] Verify on GitHub: https://github.com/gilliansoso/hermes-knowledge-base
