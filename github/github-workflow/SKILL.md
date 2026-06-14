---
name: github-workflow
description: "Complete GitHub workflow: auth setup, PR lifecycle, issues, code review, repo management — via gh CLI or REST API fallback."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [GitHub, Authentication, Pull-Requests, Issues, Code-Review, Repositories, CI/CD, Git, gh-cli]
---

# GitHub Workflow

Complete guide for working with GitHub from Hermes — authentication, pull requests, issues, code review, and repository management. Every section shows `gh` first, then the `git` + `curl` fallback for machines without `gh`.

## Auth Detection (run this first for any GitHub task)

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

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

### Setting Up Auth

**gh CLI (recommended):**
```bash
gh auth login                          # Interactive browser login
echo "$TOKEN" | gh auth login --with-token  # Token-based (headless)
gh auth setup-git                      # Configure git credentials through gh
```

**Git-only (no gh, no sudo):**
```bash
git config --global credential.helper store  # Save credentials to ~/.git-credentials
git config --global user.name "Name"
git config --global user.email "email@example.com"
```

**SSH keys:** Generate with `ssh-keygen -t ed25519`, add public key at https://github.com/settings/keys.

**Extract token from .env or git credentials:**
```bash
if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
  export GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
  export GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
fi
```

Full auth setup details: `references/github-auth.md`

---

## PR Lifecycle

### Branch & Commit
```bash
git checkout main && git pull origin main
git checkout -b feat/description
# ... make changes ...
git add src/file.py tests/test_file.py
git commit -m "feat: add feature description"
```

### Create PR
```bash
# gh
gh pr create --title "feat: add feature" --body "## Summary\n..." --draft

# curl
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls \
  -d '{"title":"feat: add feature","body":"...","head":"branch","base":"main"}'
```

### Monitor CI
```bash
gh pr checks              # One-shot
gh pr checks --watch      # Poll until done
gh run list --branch $(git branch --show-current) --limit 5
gh run view <RUN_ID> --log-failed
```

### Merge
```bash
gh pr merge --squash --delete-branch
gh pr merge --auto --squash --delete-branch  # Auto-merge when green
```

### Auto-Fix CI Failures
1. `gh run view <ID> --log-failed` → read error
2. Fix code with `patch`/`write_file`
3. `git add . && git commit -m "fix: ..." && git push`
4. Re-check CI status, repeat up to 3 times

Full PR workflow details: `references/github-pr-workflow.md`

---

## Issues

### View & Search
```bash
gh issue list --state open --label "bug"
gh issue view 42
gh issue list --search "authentication error" --state all
```

### Create

**CRITICAL — search for duplicates first.** Every issue filed is noise if a duplicate exists. Run several searches with different keyword angles before creating:

```bash
# Search open issues for core keywords
gh issue list -R owner/repo -s open -S "keyword1 keyword2" --limit 10

# Search with broader / alternate terms
gh issue list -R owner/repo -s open -S "alternate search terms" --limit 10

# Also search closed issues — they may have been closed as duplicate
gh issue list -R owner/repo -s closed -S "keyword" --limit 10
```

Use `-R owner/repo` when working outside a local git clone. If the issue is about a UI/UX bug, also browse the repo's issues page with `browser_navigate` to visually check for related open issues.

**Multi-line body via heredoc:**
```bash
cat << 'ISSUE_EOF' | gh issue create -R owner/repo -t "Bug: login fails" -F -
## Environment
- macOS 26, Hermes vX.Y.Z

## Steps to reproduce
1. ...
2. ...

## Expected
...

## Actual
...
ISSUE_EOF
```

**Verify after creation:**
```bash
gh issue view <number> -R owner/repo
```

### Manage
```bash
gh issue edit 42 --add-label "priority:high" --add-assignee username -R owner/repo
gh issue comment 42 --body "Investigated — root cause found." -R owner/repo
gh issue close 42 -R owner/repo
```

### Triage Workflow
1. List untriaged: `gh issue list -R owner/repo --label "needs-triage"`
2. Read and categorize each issue
3. Apply labels and priority
4. Assign if owner is clear

Full issues details + templates: `references/github-issues.md`

---

## Code Review

### Review Local Changes (Pre-Push)
```bash
git diff main...HEAD --stat              # Scope
git diff main...HEAD                     # Full diff
git diff main...HEAD | grep -n "print\|console\.log\|TODO\|FIXME"  # Red flags
```

### Review a PR
```bash
gh pr view 123
gh pr diff 123
git fetch origin pull/123/head:pr-123 && git checkout pr-123  # Local checkout
```

### Post Review
```bash
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "See inline comments."
gh pr comment 123 --body "## Code Review Summary\n..."
```

### Review Checklist
- **Correctness**: Edge cases, error handling
- **Security**: No hardcoded secrets, input validation, SQL injection, XSS
- **Quality**: Clear naming, DRY, single responsibility
- **Testing**: New paths tested, happy + error cases
- **Performance**: No N+1 queries, appropriate caching

Full review details + inline comment API: `references/github-code-review.md`

---

## Repository Management

### Clone & Create
```bash
git clone https://github.com/owner/repo.git
gh repo create my-project --public --clone
gh repo fork owner/repo --clone
```

### Settings & Releases
```bash
gh repo edit --description "Updated" --visibility public
gh release create v1.0.0 --title "v1.0.0" --generate-notes
```

### Secrets (GitHub Actions)
```bash
gh secret set API_KEY --body "value"
gh secret list
```

### Workflows
```bash
gh workflow list
gh run list --limit 10
gh run rerun <RUN_ID> --failed
```

Full repo management details: `references/github-repo-management.md`

---

## Quick Reference

| Action | gh | curl |
|--------|-----|------|
| List PRs | `gh pr list` | `GET /repos/{o}/{r}/pulls` |
| Create PR | `gh pr create` | `POST /repos/{o}/{r}/pulls` |
| Merge PR | `gh pr merge --squash` | `PUT /repos/{o}/{r}/pulls/N/merge` |
| List issues | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| Create issue | `gh issue create` | `POST /repos/{o}/{r}/issues` |
| Code review | `gh pr review N --approve` | `POST /repos/{o}/{r}/pulls/N/reviews` |
| Create repo | `gh repo create` | `POST /user/repos` |
| Create release | `gh release create` | `POST /repos/{o}/{r}/releases` |
| Set secret | `gh secret set` | `PUT /repos/{o}/{r}/actions/secrets/KEY` |

## Pitfalls

1. **GitHub disabled password auth** — use personal access token or SSH key
2. **Token lacks scopes** — regenerate with `repo`, `workflow`, `read:org`
3. **`gh` not installed** — all workflows have curl fallbacks above
4. **Multiple GitHub accounts** — use SSH with different keys per host alias in `~/.ssh/config`
6. **macOS proxy kills `gh auth login` device flow** — on macOS with ClashX/V2rayU/Surge (system proxy at 127.0.0.1:7892, check via `scutil --proxy`), the device flow times out because `gh` doesn't pick up system proxy settings. Fix: `export http_proxy=http://127.0.0.1:7892 https_proxy=http://127.0.0.1:7892` before running, OR skip device flow entirely: `echo "$TOKEN" | gh auth login --with-token` with a browser-generated PAT.
7. **`gh auth login` PTY hangs on interactive menus** — device flow spawns prompts like "Where do you use GitHub?" and "Authenticate Git?". In PTY mode these can be answered with `process(action='submit')`, but the PTY channel is unreliable. Safest approach: skip interactive flow entirely via `gh auth login --with-token`.
8. **`gh` targeting wrong repo from outside a git clone** — when working outside a local clone, pass `-R owner/repo` to every `gh` command (`issue list`, `issue create`, `issue view`, `pr list`, etc.). Without it, `gh` errors with "not a git repository" or targets the wrong repo if `$PWD` is inside a different clone.

