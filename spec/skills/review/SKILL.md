---
name: review
description: "Critically review an implementation against its spec via an isolated-context subagent, and write review.md before the PR gate. Triggers: /spec:review, spec review, review implementation, adversarial review, review.md"
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob, Task, Skill
model: opus
---


You are the **review** phase. The critique must be adversarial and free of the implementer's reasoning — so you do NOT review inline. A slash command runs inside the current (often implementation-tainted) conversation; to get a genuinely fresh context you **delegate the reading to a subagent** (公理2: a subagent exists precisely to isolate context). Your job here is to orchestrate that review and record its verdict.

Spec: $ARGUMENTS

## Steps

1. **Read the contract:** `specs/<id>/requirement.md`, `design.md`, `tasks.md`.
2. **Precondition:** `tasks.md` must be `status: ready` AND the diff (step 3) must be non-empty. If either fails, stop — there is nothing implemented to review yet.
3. **Determine the diff range.** Base = the repo's default branch from origin (match `/eng:create-pr`'s detection: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, fall back to `origin/HEAD`, then `main`). Review range is `git diff origin/<base>...HEAD`.
4. **Delegate the adversarial read to subagents (isolated context):**
   - `eng:architecture-reviewer` on the diff — it is the verify-half for diffs/PRs (boundary violations, coupling, leaky abstractions, contract breaks). Pass it the spec paths + the diff range.
   - A `general-purpose` (or `Explore`) reviewer to map each acceptance condition to observed evidence, **actually running** the 検証 commands from `tasks.md`. Optionally also run the official `/code-review` for a second lens.
5. **Write `specs/<id>/review.md`** from the subagents' findings, in the format below.
6. Print the verdict and the next command.

## review.md format

```markdown
---
id: <id>
phase: review
status: <pass | changes-requested>   # ← the gate reads THIS field
---

> verdict: <one human-readable line>

## 受け入れ条件の充足
| 受け入れ条件 | 状態 (✅/⚠️/❌) | 根拠（実際に観測したこと） |
| --- | --- | --- |

## 設計との整合（eng:architecture-reviewer より）
<layer/dependency-rule respect, service boundaries, leaks>

## 指摘（重大度順）
- [Blocker] <issue> — 場所: <file:line> — なぜ問題か / 直し方
- [Major] / [Minor] ...

## 検証ログ
<commands run and their actual results — test output, type-check, lint>

## スコープ外で気づいた負債
<pre-existing issues — mention, do not fix unless asked>
```

## Rules

- `status: pass` requires **every** acceptance condition at ✅ with observed evidence. Any ❌, or any condition the subagents could not run, forces `changes-requested`.
- Separate "violates the spec" (Blocker/Major) from "I'd have done it differently" (Minor, non-blocking).
- Do not fix the code here — review only. Hand Blockers back to the implementation step.

When done, end with exactly:

> Gate ③: `review.md` の `status` が pass なら `/eng:create-pr` で PR を作成（マージは人間）。changes-requested なら Blocker を実装フェーズに差し戻してください。
