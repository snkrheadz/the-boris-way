---
name: tasks
description: "Break an approved design.md into an ordered, independently-verifiable tasks.md (the implementation contract). Triggers: /spec:tasks, break into tasks, spec tasks, task breakdown, tasks.md"
user-invocable: true
---


You are the **task-breakdown** phase. Input is an approved design. Produce an ordered implementation plan where every task carries its own verification. Do NOT write implementation code here.

Spec: $ARGUMENTS

## Steps

1. **Read only `specs/<id>/requirement.md` and `specs/<id>/design.md`.**
2. **Precondition check:** `design.md` must be `status: approved`. Otherwise stop and ask the user to clear Gate ②.
3. **Write `specs/<id>/tasks.md`** — a checklist of small, ordered tasks. Each task must be independently verifiable and trace back to a design element / acceptance condition.
4. Print the task count and the next command. Implementation is a separate, explicitly-invoked step.

## tasks.md format

```markdown
---
id: <id>
phase: tasks
status: ready
---

## 実装タスク
- [ ] T1: <small, concrete change>
  - 触る場所: <module/file from design's blast radius>
  - 検証: <the command or observation that proves T1 works — test, run, type-check>
  - 由来: <design element / acceptance condition it satisfies>
- [ ] T2: ...

## 実装順序の根拠
<why this order; what unblocks what>

## 完了の定義（DoD）
- すべての受け入れ条件が requirement.md の「検証方法」で観測できる
- テスト緑 / 型チェック通過 / lint 通過
- 関係する `tasks/lessons.md` の教訓に反していない
```

## Rules

- **One task = one verifiable increment.** If a task has no concrete 検証 line, split it until it does (公理5: 各タスクが自分の検証を持つまで分割する).
- Order so each task leaves the tree green. No "big bang" tasks that only verify at the end.
- Do not exceed the design — if a task needs something not in `design.md`, stop and flag it back to Gate ②; don't quietly redesign here.

When done, end with exactly:

> 実装の準備完了: `/spec:implement specs/<id>/tasks.md` で実装し、`/eng:test-and-fix` で緑を確認、`/spec:review <id>` でレビュー、`/eng:create-pr` で PR を作成してください。並列でやるなら案件ごとに worktree を分けてください。
