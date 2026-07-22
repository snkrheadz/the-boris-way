---
name: verify-work
description: "Closing-gate verification before declaring work done: run the repo's verify entrypoint (scripts/verify.sh by convention) and judge the diff for weakened tests or gates. Reports pass/fail with evidence; never fixes — for the repair loop after a FAIL use /eng:test-and-fix instead; to observe a change working in the running app use the official /verify. Triggers: /eng:verify-work, verify work, closing gate, verify before PR, done宣言前, 完了確認, PR前チェック"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
model: opus
context: fork
---

# verify-work — Closing Gate

"Done" means the gate was RUN and its result observed — not that the diff looks
right. The heavy lifting belongs to each repo's own verify entrypoint; this skill
only executes it and detects the one thing a script cannot judge about itself:
green reached by weakening the checks.

## Step 1: Locate the gate

- Convention: `scripts/verify.sh` at the repo root.
- Absent → check the repo's CLAUDE.md for a named closing-gate command.
- Still nothing → report "no closing gate found", list the checks you DID run
  (tests, lint — whatever the repo offers), and recommend creating a single
  entrypoint. Never invent a verdict.

## Step 2: Run it

`bash scripts/verify.sh` (or the CLAUDE.md-named command). A well-built
entrypoint reports SKIPs with reasons where tools are absent — never count a
SKIP as an implicit PASS. No FAIL = gate green.

## Step 3: Weakening check — don't trust green

Read the diff (working tree if uncommitted; `git diff origin/<default>...HEAD`
if committed) and judge whether the verification itself was weakened to reach
green. Typical shapes:

- test assertions deleted or relaxed
- checks removed from the verify entrypoint itself, or its SKIP conditions widened
- lint / scanner configs given new exclusions or relaxed rules
- tests commented out, marked skip, or quarantined as flaky
- fail-open scope of hooks/guards expanded beyond their documented spec

Also read the verify entrypoint's header comment: repos may document their own
weakening watch-list there — honor it as additional, repo-specific criteria.

## Step 4: Report

State each check's PASS/FAIL/SKIP, the weakening verdict, and the evidence
(verify output lines + the diff lines behind the judgement). Gate green AND no
weakening = pass. Either missing = fail, with the evidence.

## Repair

This skill never fixes. A FAIL hands off to `/eng:test-and-fix`; shell-script
deep dives go to the `verify-shell` agent.
