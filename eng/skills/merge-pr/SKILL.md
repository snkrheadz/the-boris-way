---
name: merge-pr
description: "Merge PR and cleanup worktree and local branch. Triggers: /merge-pr, PR merge, worktree cleanup"
user-invocable: true
allowed-tools: Bash
---

# /merge-pr

Execute PR merge and worktree cleanup in one command.

## Usage

```
/merge-pr 42
```

## Execution Flow

1. Get current worktree path and branch name
2. Move to main repository
3. Remove worktree: `git worktree remove <path>`
4. Delete local branch: `git branch -D <branch>`
5. Merge PR: `gh pr merge <num> --merge --delete-branch`
6. Update main: `git pull origin main`

## Notes

- If executed from within a worktree (built-in `.claude/worktrees/` or manual), automatically detects and moves to main repo
- Ensure no uncommitted changes before merging
- Built-in worktreeの自動クリーンアップはディレクトリ削除のみ。PR merge・リモートブランチ削除・main更新はこのskillが担当
- Built-in worktree内から実行する場合、step 3 (`git worktree remove`) は自動クリーンアップ済みなら不要。削除前にworktreeの存在を確認する
