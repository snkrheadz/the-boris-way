---
name: create-pr
description: "Sync the base branch from origin, merge it into the current branch, then open a PR against the correct base. Prevents PRs created on a stale base from a git worktree. Triggers: /eng:create-pr, create PR, open pull request, gh pr create"
user-invocable: true
allowed-tools: Bash
---

# /eng:create-pr

Open a pull request **with the base branch already synced from origin**. This closes
the recurring failure where a PR is created from a git worktree without first merging
the latest base, so the PR targets a stale base and the branch is behind.

This skill is **self-contained**: it detects the base branch itself and does not depend
on any machine-local shell function. It works in any repo, with any default branch.

## Usage

```
/eng:create-pr                      # title/body inferred from commits
/eng:create-pr "feat: add X"        # explicit title
```

## Execution

What the flow does, in order:

1. Detect the base branch (never hardcode `main`; handle empty `gh` output too).
2. Guard: refuse if HEAD *is* the base branch.
3. Fetch the base from origin.
4. Guard: refuse if HEAD has **no commits ahead** of the fresh base.
5. Merge the fresh base into the current branch — this is the fix for problem 1
   (PR opened on a stale base). Merge preserves history, so no force-push is needed.
6. Push (plain `--set-upstream`; no force needed).
7. Open the PR against the detected base, explicitly.

**Run the whole flow as a single Bash invocation.** The steps share shell variables
(`base`, `cur`), and the Bash tool does **not** persist variables across separate calls —
splitting the block would leave `$base`/`$cur` empty and run `git fetch origin ""`, etc.
`set -e` makes a merge conflict (step 5) abort the script with the merge left in
progress; that is the intended **stop-and-hand-back** behaviour.

```bash
set -euo pipefail

# 1. Detect base — fall back on empty output, not only on non-zero exit.
base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null) || true
[ -n "${base:-}" ] || base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@') || true
[ -n "${base:-}" ] || base=main
cur=$(git rev-parse --abbrev-ref HEAD)
echo "base=$base cur=$cur"

# 2. Guard: must not be on the base branch.
if [ "$cur" = "$base" ]; then
  echo "On base branch ($base); nothing to PR."; exit 1
fi

# 3. Sync the base from origin.
git fetch origin "$base"

# 4. Guard: must have commits ahead of the freshly-fetched base.
if [ "$(git rev-list --count "origin/$base..HEAD")" -eq 0 ]; then
  echo "No commits ahead of origin/$base; nothing to PR."; exit 1
fi

# 5. Merge the fresh base into the current branch. On conflict, set -e aborts here
#    with the merge in progress: resolve, `git commit` (or `git merge --continue`),
#    then run steps 6-7 manually.
git merge --no-edit "origin/$base"

# 6. Push. No force needed — merge only adds commits, never rewrites history.
git push --set-upstream origin "$cur"

# 7. Open the PR against the detected base explicitly (never rely on the default).
gh pr create --base "$base" --fill   # or --title/--body when you have them
```

## Notes

- **Base is always detected, never assumed** — a repo on `master`/`develop` works as-is.
- **Merge, not rebase** — the current branch keeps its commit history and gains a merge
  commit from origin's base, so no `--force-with-lease` is ever required.
- Conflicts are a stop condition, not something to auto-resolve. Surface them and wait.
- After the PR merges, clean up with `gh pr merge <n> --merge --delete-branch` then the
  official `/clean_gone` command (removes the now-`[gone]` local branch and its worktree).
