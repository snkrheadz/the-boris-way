---
name: context-audit
description: "Audit a repo's .claude/ context (CLAUDE.md, skills, hooks) against the evolving principle checklist in principles.md — detect gaps, report with evidence, and route each fix to the right primitive. Sibling boundaries: for CLAUDE.md wording/routing use /core:tune-claude-md; for one prose-rule→enforcement move use /core:promote-to-code; for codebase agent-readiness (tests/CI) use /spec:scan. Triggers: /core:context-audit, context audit, コンテキスト監査, audit claude setup, 原則監査, verification coverage check, principles check"
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion
model: sonnet
---

# /core:context-audit

Audit the target repo's Claude context against `principles.md` (in this skill's
directory — the single source of truth, distributed to every repo through this pack).
The checkers check the repo; **this skill checks the checkers**. New lessons (a video,
a postmortem, a correction) become ONE new entry in `principles.md`; every repo's next
audit then inherits it. That is the update loop.

Target: the current repo, or the path passed as an argument.

## Steps

1. **Load the checklist.** Read `principles.md` from this skill's base directory.
   Each entry has: statement, why, detection, fix route.
2. **Inventory the target repo's context surfaces:**
   - `CLAUDE.md` (project root; also `CLAUDE.local.md` if present)
   - `.claude/skills/*/SKILL.md` — collect each `description:` frontmatter
   - hooks: `.claude/settings.json` / `settings.local.json` hook entries and any
     repo hook-script directories they reference
   - verification entrypoints: `scripts/verify*.sh`, `Makefile` verify/check targets,
     CI workflow gates
3. **Evaluate every principle** against the inventory using its Detection section.
   Verdict per principle: `PASS` / `GAP` / `N/A` (with one line of why — e.g. N/A
   when the repo has no code to verify). Always cite evidence: the file+line that
   satisfies the principle, or the absence you searched for (name the greps you ran).
4. **Report** a table: principle / verdict / evidence / fix route. GAPs first.
5. **Offer fixes, delegating — don't reimplement.** For each GAP, name the mapped fix
   route from `principles.md` and offer to run it (`/core:tune-claude-md`,
   `/core:promote-to-code`, a verification-skill edit, …). Apply only after the user
   picks. In an unattended run (routine/loop): report only, never edit.
6. **Bank repo-specific findings** that are not principle-worthy into that repo's
   `tasks/lessons.md`. A finding that would recur in OTHER repos is principle-worthy:
   tell the user to add it to this pack's `principles.md` (one entry + patch version
   bump) — never fork a per-repo copy of the checklist.

## Orchestration notes

- If the official `claude-code-setup` plugin (claude-automation-recommender) is
  installed, you may run it for discovery breadth — but `principles.md` remains the
  authority for PASS/GAP verdicts. Its absence never blocks the audit.
- This skill is the **primitive**, not the loop. Cross-repo cadence: a routine
  (weekly/monthly) that runs it per repo — same pattern as tune-claude-md's
  multi-repo section.
