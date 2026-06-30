---
name: design
description: "Turn an approved requirement.md into a design.md (DDD / clean architecture / service boundaries), then stop at the human gate. Triggers: /spec:design, write design, spec design, architecture design, design.md"
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob
model: opus
---


You are the **design** phase. Input is an approved requirement. Produce the architecture. Do NOT write implementation code or break work into tasks yet.

Spec: $ARGUMENTS

## Steps

1. **Read only `specs/<id>/requirement.md`.** This is your contract — do not invent requirements not present there.
2. **Precondition check:** the requirement front-matter must be `status: approved`. If it is still `awaiting-human-gate-1`, stop and tell the user to approve Gate ① first.
3. **Understand the existing codebase before designing.** Use `codegraph_explore` (not raw file reads) to survey the modules, boundaries, and patterns this change touches. Design *with* the current architecture, not against it.
4. **Write `specs/<id>/design.md`** in the format below.
5. **Stop at the gate.** Print the path, the key design decisions (and the alternatives rejected), and the next command. Do not start tasks or code.

## design.md format

```markdown
---
id: <id>
phase: design
status: awaiting-human-gate-2   # → approved (set by human)
---

## ドメインモデル（DDD）
<entities, value objects, aggregates, domain events; ubiquitous language>

## レイヤ構成（クリーンアーキテクチャ）
<domain / use-case / interface-adapter / infra — dependency direction inward>

## サービス境界 / 統合点
<bounded contexts, service split if any, sync/async, contracts at the seams>

## 主要な設計判断
- 判断: <choice> / 理由: <why> / 却下案: <alternative and why not>

## 既存コードへの影響（blast radius）
<modules/files affected, migrations, breaking changes — from codegraph>

## 受け入れ条件 → 設計 の対応表
| requirement の受け入れ条件 | それを満たす設計要素 |
| --- | --- |

## リスク / 未確定
<technical risks, things to validate during implementation>
```

## Rules

- **Dependency rule first.** Inner layers never depend on outer. If the design violates it, fix the design.
- Every acceptance condition in the requirement must map to at least one design element (fill the 対応表). A gap means the design is incomplete.
- Keep service boundaries justified by the requirement — do not split into microservices for fashion. Note when a monolith/module is the right call.
- This phase only produces `design.md` (no diff yet); the adversarial architecture pass happens later in `/spec:review`, where `eng:architecture-reviewer` runs against the real diff.

When done, end with exactly:

> Gate ② 待ち: `specs/<id>/design.md` をレビューしてください。承認後に `status: approved` へ変更し、`/spec:tasks <id>` を実行してください。
