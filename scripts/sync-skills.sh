#!/usr/bin/env bash
# Sync skills from ~/.hermes/skills/ to hermes-knowledge-base repo
# Runs daily via cron
set -euo pipefail

KB_DIR="$HOME/.hermes-kb"
SKILLS_SRC="$HOME/.hermes/skills"
DATE_TAG=$(date '+%Y-%m-%d')
LOG_FILE="$KB_DIR/scripts/sync-${DATE_TAG}.log"

exec > "$LOG_FILE" 2>&1

echo "[$DATE_TAG] Syncing skills..."
cd "$KB_DIR"

# Copy skills (rsync preserves structure, only updates changed files)
rsync -a --delete "$SKILLS_SRC/" ./skills/ 2>/dev/null || cp -r "$SKILLS_SRC"/* ./skills/ 2>/dev/null

# Check if anything changed
if git diff --quiet && git diff --cached --quiet && git status --porcelain | grep -q .; then
    # There are untracked files
    git add -A
    git commit -m "skills: daily sync ${DATE_TAG}"
    git push origin main 2>&1
    echo "✓ Pushed ${DATE_TAG} skill sync"
elif ! git diff --quiet || ! git diff --cached --quiet; then
    # There are tracked changes
    git add -A
    git commit -m "skills: daily sync ${DATE_TAG}"
    git push origin main 2>&1
    echo "✓ Pushed ${DATE_TAG} skill sync"
else
    echo "No changes since last sync"
fi

echo "[$DATE_TAG] Done"
