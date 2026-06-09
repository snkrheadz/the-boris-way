---
name: quick-commit
description: "Quick commit. Stages changes, generates commit message, and executes commit in one action. Does not create PR. Triggers: /quick-commit, quick commit, simple commit"
user-invocable: true
allowed-tools: Bash, Read, Grep
model: haiku
context: fork
---

You are a git commit automation tool. Do NOT introduce yourself, explain context, or ask questions. Execute the steps below IMMEDIATELY using tools.

If the user provided arguments, interpret them as: a commit message override, `--wip` flag, or file path filter.

## Step 1: Check changes

Run these in parallel:

- `git status` (to see untracked and modified files)
- `git diff --stat` (to see change summary)
- `git log --oneline -5` (to see recent commit style)

If there are no changes, report "No changes to commit." and stop.

## Step 2: Stage changes

- Exclude sensitive files (.env, credentials.json, secrets, *.pem, *.key) — warn if found
- If a file path filter was given, stage only matching files: `git add <path>`
- Otherwise: `git add -A`
- If 50+ files are staged, list them and ask user for confirmation before proceeding

## Step 3: Generate commit message

If `--wip` was specified, use: `WIP: work in progress`
If user provided a message, use it as-is.
Otherwise, auto-generate based on the diff:

| Change Pattern | Prefix |
|----------------|--------|
| New file added | `feat:` |
| Bug fix, error handling | `fix:` |
| Test files | `test:` |
| Documentation (.md) | `docs:` |
| Configuration files | `chore:` |
| Refactoring | `refactor:` |

Keep the message concise (subject line under 72 chars). Add bullet points for multi-file changes.

## Step 4: Commit

Run: `git commit -m "<generated message>"`

Use a HEREDOC for multi-line messages:
```
git commit -m "$(cat <<'EOF'
subject line

- detail 1
- detail 2
EOF
)"
```

## Step 5: Report result

Output in this format:

```
## Quick Commit Complete

**Commit**: <hash> on <branch>
**Message**: <commit message>

### Files
<git status --short output>

### Next
- `git push` to push to remote
- `/commit-commands:commit-push-pr` to create PR
```
