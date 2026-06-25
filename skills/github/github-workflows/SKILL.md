---
name: github-workflows
description: "Complete GitHub workflows: auth, repo management, PR lifecycle, code review, issues, releases, CI/CD, secrets."
tags: [GitHub, Git, CI/CD, Pull-Requests, Code-Review, Issues, Automation, Authentication]
---

# GitHub Workflows

Consolidated guide for all GitHub operations. Each section shows `gh` first, then the `git` + `curl` fallback for machines without `gh`.

## Shared Auth Detection

All sections below use the same auth detection. Run this block first:

```bash
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

# Extract owner/repo from git remote (when inside a repo)
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -n "$REMOTE_URL" ]; then
  OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
  OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
  REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
fi

# Get GitHub username
if [ "$AUTH" = "gh" ]; then
  GH_USER=$(gh api user --jq '.login' 2>/dev/null)
else
  GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))" 2>/dev/null)
fi

echo "Auth: $AUTH | User: $GH_USER | Repo: $OWNER/$REPO"
```

---

## 1. Authentication Setup

Two paths:

- **`git` (always available)** — HTTPS personal access tokens or SSH keys
- **`gh` CLI (if installed)** — richer GitHub API access with simpler auth flow

### Detection Flow

Run the check from the shared auth block above. Decision tree:
1. `gh auth status` shows authenticated → use `gh` for everything
2. `gh` installed but not authenticated → use `gh auth login --with-token`
3. No `gh` → use git credential store

### Token-Based Auth (git-only)

Create a token at https://github.com/settings/tokens with `repo` + `workflow` + `read:org` scopes.

```bash
# Store credentials
echo "https://<username>:<token>@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
git config --global credential.helper store
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

### SSH Auth

```bash
ssh-keygen -t ed25519 -C "email@example.com" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub  # Add at https://github.com/settings/keys
git config --global url."git@github.com:".insteadOf "https://github.com/"
ssh -T git@github.com  # Verify
```

### gh CLI Auth

```bash
echo "<token>" | gh auth login --with-token
gh auth setup-git
gh auth status
```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `git push` asks for password | Use personal access token, not GitHub password |
| `Permission to X denied` | Token lacks `repo` scope |
| `error validating token: missing scope read:org` | Token needs `read:org` scope. Fallback to git credential store |
| `remote: Invalid username or token` | Token-embedded URLs deprecated. Use `~/.git-credentials` instead |
| Multiple GitHub accounts | SSH with different keys per host alias in `~/.ssh/config` |

---

## 2. Repository Management

### Cloning

```bash
# HTTPS (with credential helper)
git clone https://github.com/owner/repo-name.git
# Shallow clone for speed
git clone --depth 1 https://github.com/owner/repo-name.git
# Specific branch
git clone --branch develop https://github.com/owner/repo-name.git
# gh shorthand
gh repo clone owner/repo-name
```

### Creating Repositories

**With gh:**
```bash
gh repo create my-project --public --clone
gh repo create my-org/my-project --private --clone --description "A useful tool"
gh repo create my-project --source . --public --push
```

**With curl:**
```bash
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos \
  -d '{"name": "my-project", "private": false, "auto_init": true, "license_template": "mit"}'
```

### Forking

```bash
gh repo fork owner/repo-name --clone

# Keep fork in sync
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### Repository Settings

```bash
gh repo edit --description "Updated" --visibility public --enable-wiki=false
```

### Releases

```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release list
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/releases
```

### GitHub Actions Workflows

```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID> --failed
gh workflow run ci.yml --ref main
```

### Secrets Management

```bash
gh secret set API_KEY --body "your-secret-value"
gh secret list
```

### Branch Protection

```bash
curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  -d '{"required_status_checks": {"strict": true, "contexts": ["ci/test"]}, "required_pull_request_reviews": {"required_approving_review_count": 1}}'
```

### Gists

```bash
gh gist create script.py --public --desc "Useful script"
```

---

## 3. Pull Request Workflow

### Branch Creation

```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b feat/description  # or fix/, refactor/, docs/, ci/
```

### Commits (Conventional Commits)

```bash
git add src/auth.py
git commit -m "feat: add JWT-based user authentication"
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`

### Creating PRs

**With gh:**
```bash
gh pr create --title "feat: add auth" --body "## Summary\nAdds login endpoints." --draft
```

**With curl:**
```bash
BRANCH=$(git branch --show-current)
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls \
  -d "{\"title\": \"feat: add auth\", \"head\": \"$BRANCH\", \"base\": \"main\"}"
```

### Monitoring CI

```bash
gh pr checks --watch

# curl fallback
SHA=$(git rev-parse HEAD)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status
```

### Auto-Fixing CI Failures

1. Check CI status → read failure logs (`gh run view <ID> --log-failed`)
2. Fix code → `git add && git commit -m "fix: ..." && git push`
3. Re-check CI → repeat up to 3 attempts

### Merging

```bash
gh pr merge --squash --delete-branch
gh pr merge --auto --squash --delete-branch  # auto-merge when CI passes
```

---

## 4. Code Review

### Reviewing Local Changes (Pre-Push)

```bash
# Get the scope
git diff main...HEAD --stat
git log main..HEAD --oneline

# Read the diff
git diff main...HEAD
git diff main...HEAD -- src/auth/login.py  # file-specific

# Check for common issues
git diff main...HEAD | grep -n "print(\|TODO\|FIXME\|debugger\|password\|secret"
```

### Reviewing PRs

**With gh:**
```bash
gh pr view 123
gh pr diff 123
gh pr checkout 123   # check out locally
```

**With git + curl:**
```bash
git fetch origin pull/123/head:pr-123
git checkout pr-123
```

### Leaving Comments

**General PR comment:**
```bash
gh pr comment 123 --body "Overall looks good."
```

**Inline comment:**
```bash
HEAD_SHA=$(gh pr view 123 --json headRefOid --jq '.headRefOid')
gh api repos/$OWNER/$REPO/pulls/123/comments --method POST \
  -f body="Use parameterized queries here." \
  -f path="src/auth.py" -f commit_id="$HEAD_SHA" -f line=45 -f side="RIGHT"
```

**Submit formal review:**
```bash
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "See inline comments."
```

### Review Checklist

- **Correctness**: Edge cases, error handling, does what it claims
- **Security**: No hardcoded secrets, SQL injection, XSS, path traversal
- **Code Quality**: Clear naming, single responsibility, DRY
- **Testing**: Tests for new code, edge cases covered
- **Performance**: No N+1 queries, appropriate caching
- **Documentation**: Public APIs documented, README updated

---

## 5. Issues Management

### Viewing Issues

```bash
gh issue list
gh issue list --state open --label "bug"
gh issue list --assignee @me
gh issue view 42
```

### Creating Issues

```bash
gh issue create --title "Login redirect bug" \
  --body "## Description\nAfter login, users land on /dashboard instead of ?next= param." \
  --label "bug,backend" --assignee "username"
```

### Managing Issues

```bash
# Labels
gh issue edit 42 --add-label "priority:high" --remove-label "needs-triage"
# Assignment
gh issue edit 42 --add-assignee username
# Comment
gh issue comment 42 --body "Root cause found in auth middleware."
# Close/Reopen
gh issue close 42
gh issue reopen 42
```

### Issue Triage Workflow

1. List untriaged: `gh issue list --label "needs-triage"`
2. Read and categorize each issue
3. Apply labels and priority
4. Assign if owner is clear
5. Comment with triage notes

### Bulk Operations

```bash
gh issue list --label "wontfix" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"
```

### Feature Request Template

```
## Feature Description
<What you want>

## Motivation
<Why this would be useful>

## Proposed Solution
<How it could work>
```

### Bug Report Template

```
## Bug Description
<What's happening>

## Steps to Reproduce
1. <step>
2. <step>

## Expected Behavior
<What should happen>

## Actual Behavior
<What actually happens>
```

---

## Quick Reference Table

| Action | gh | curl endpoint |
|--------|-----|--------------|
| Clone | `gh repo clone o/r` | `git clone https://github.com/o/r.git` |
| Create repo | `gh repo create name` | `POST /user/repos` |
| Fork | `gh repo fork o/r --clone` | `POST /repos/o/r/forks` + git clone |
| List issues | `gh issue list` | `GET /repos/o/r/issues` |
| Create issue | `gh issue create ...` | `POST /repos/o/r/issues` |
| Label/assign | `gh issue edit N --add-label ...` | `POST /repos/o/r/issues/N/labels` |
| Create PR | `gh pr create` | `POST /repos/o/r/pulls` |
| Review PR | `gh pr review N` | `POST /repos/o/r/pulls/N/reviews` |
| Merge PR | `gh pr merge --squash` | `PUT /repos/o/r/pulls/N/merge` |
| CI status | `gh pr checks` | `GET /repos/o/r/commits/SHA/status` |
| Re-run CI | `gh run rerun ID` | `POST /repos/o/r/actions/runs/ID/rerun` |
| Release | `gh release create v1.0` | `POST /repos/o/r/releases` |
| Set secret | `gh secret set KEY` | `PUT /repos/o/r/actions/secrets/KEY` |
| Repo info | `gh repo view o/r` | `GET /repos/o/r` |