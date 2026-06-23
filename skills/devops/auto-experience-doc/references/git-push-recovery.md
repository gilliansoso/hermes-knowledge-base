# Git Push Recovery for Automated Sync Scripts

## The Problem

Automated scripts pushing to `~/.hermes-kb/` (daily skills sync, experience docs)
can hit `! [rejected] main -> main (fetch first)` when the remote has new commits
from another device/session. The script falls through to "No changes" but the
branch stays ahead of origin — commits pile up and never reach GitHub.

## Root Cause

Multiple Hermes sessions (cron jobs, cli sessions) all push to the same repo.
Whoever pushes second gets rejected because `git push` requires a fast-forward.

## Recovery Sequence (full)

```bash
# 1. See where we stand
cd ~/.hermes-kb
git status
git log --oneline origin/main..HEAD   # unpushed commits

# 2. Commit any dirty files
git add -A
git commit -m "working changes"

# 3. Pull remote changes, rebasing local commits on top
git pull --rebase origin main

# 4. Push
git push origin main

# 5. Verify
git log --oneline -5   # should show origin/main at the tip
```

## Notes for cron scripts

- `git pull --rebase` is preferred over `git pull` (merge commit) for linear history.
- Add `git pull --rebase origin main` before `git push` in any automated sync script.
- If the cron script writes to a tracked log file (like `sync-skills.sh` does), that
  log file's modification can interfere with `git diff --quiet` logic. The script
  should either redirect to a path outside the git tree, or handle the log
  file explicitly (e.g., `git update-index --assume-unchanged`).
- The `sync-skills.sh` script at `~/.hermes-kb/scripts/sync-skills.sh` has this exact
  fragility: it `exec > "$LOG_FILE" 2>&1` before running git status checks, and the
  log is inside the git tree. It also lacks a `git pull --rebase` before `git push`.