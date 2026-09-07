---
name: config-retest
description: "Empirically prune a repo's Claude config (CLAUDE.md, .claude/skills, hooks, agents): inventory what each item claims to enforce, delete it all in a worktree, re-run a real task in a fresh session, keep only what changed behavior or cannot be derived, and PR the pruned config with the evidence table — the 6-monthly delete-and-retest. Siblings: for a checklist audit use /core:context-audit; for CLAUDE.md wording use /core:tune-claude-md; for a prose-rule→hook move use /core:promote-to-code. Triggers: /core:config-retest, config retest, delete and retest, delete your CLAUDE.md and see, 設定の棚卸し, CLAUDE.md を消して試す, 不要な設定を切り分け, prune claude config"
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, Skill, SendMessage, AskUserQuestion
---

# /core:config-retest

"Every 6 months, delete your CLAUDE.md, your skills and your hooks. Then see what the
model does." This skill is that exercise made repeatable: the verdict on every config
item comes from a **transcript**, not from reading the item and guessing. Static audits
(`context-audit`, `tune-claude-md`) judge text; this one judges behavior.

Scope: the **repo's own** config — `CLAUDE.md`, `CLAUDE.local.md`, `.claude/` (skills,
hooks, agents, settings hook wiring). The user's global `~/.claude/` stays in place; it
is audited by running this skill on the dotfiles repo that owns it.

Arguments: `[path] [--task "<one line>"] [--peer] [--baseline]`
- `path` — target repo (default: cwd).
- `--task` — override the retest task (otherwise chosen in step 2).
- `--peer` — hand the retest to a second interactive session (`SendMessage`) instead
  of a headless `claude -p` run. Use when the user wants to watch, or when the headless
  run stalls on permissions.
- `--baseline` — also run the task WITH the config, for a side-by-side. Doubles the cost.

Cost: one retest run is a full session, roughly 100k–300k tokens. Say so before step 3.

## Steps

1. **Inventory and claims.** `git status` must be clean (stop otherwise). List every
   config file with its size. For each item write ONE line: *what it claims to enforce
   or supply* (from its header, description, or the rule text). Then bucket it:
   - **A** duplicate — the system prompt, a built-in command, or an installed plugin
     pack already says or does this. Name the replacement **and read it**: the file,
     the doc page, or the pack's SKILL.md/hooks.json. A setting whose *name* sounds
     right is not evidence (a `voice` setting was once cited as replacing a spoken
     notification hook; it was dictation input).
   - **B** derivable — the repo itself supplies it: a script header, a sibling file's
     convention, `git log`, a verify gate that fails on drift.
   - **C** policy gate — a rule the model is not expected to follow by default
     (review before PR, model routing for cost, a deny-list).
   - **D** script-backed tool — the item's value is a script it ships, not its prose.
   - **E** unknown — cannot tell without the retest.
   Save the table to the scratch dir (`${TMPDIR:-/tmp}/config-retest-<repo>-<date>/`).

2. **Pick the retest task and the observation points.** The task is a small, real
   change in this repo that touches what the config claims: it should need a test run,
   a convention, a review, and a PR-shaped ending. It ends at `git commit` on a branch
   plus *printing* the `gh pr create` command it would run — never a push, never a PR.
   From the claims table derive one yes/no observable per A/B/E item ("ran the test
   suite before committing?", "followed the commit template?", "ran /code-review
   before the PR command?", "called Agent without model?"). Write both down before
   running anything; the points are fixed before the evidence exists.

3. **Retest in a worktree.** `git worktree add <scratch>/wt -b config-retest/<date>`.
   Inside it, copy `.claude/settings.json`'s `permissions.allow` aside, then delete
   `CLAUDE.md`, `CLAUDE.local.md` and `.claude/` (all of it — hooks wired from
   `settings.json` die with it). Run:
   ```
   claude -p "<task>" --permission-mode acceptEdits \
     --allowedTools <the saved allow list, comma-joined> \
     --output-format stream-json --verbose > <scratch>/retest.jsonl
   ```
   The repo's own allow-list is the sandbox boundary; if the run stalls on a denied
   tool, record it and switch to `--peer`. With `--baseline`, run the same command in a
   second worktree that keeps the config. With `--peer`, send the task text plus the
   "commit, don't push" rule to the peer session and wait for its idle notice.

4. **Read the transcript against the points.** For each observation point: observed
   yes/no, and the transcript line (tool call or text) that proves it. Also record:
   tokens on the first turn (context size), tool-call count, `Agent` calls and whether
   each carried `model`, every test/lint command run, every convention followed or
   missed. Diff the worktree's commit against the repo's conventions by hand.

5. **Verdict per item.** Keep iff any of: its observation point flipped (behavior
   changed when it was gone), it is **C**, it is **D**. Drop **A**/**B** items whose
   point held. **E** items and any item the task never exercised stay, marked
   *unexercised* — absence of evidence is not evidence; name the task that would
   exercise them next time.

6. **Apply on a branch in the real repo.** Delete the dropped items. Rewrite
   `CLAUDE.md` to hold only kept rules the repo cannot supply (a closing gate, a PR
   sequence, a cost rule). Fix every reference: grep each dropped name across README,
   scripts, tests, settings, install scripts, CI. For every "covered by X" sentence you
   write, cite X's file or doc. Run the repo's verify gate (`scripts/verify.sh` or the
   equivalent) — all green, nothing weakened. Then `/code-review`, fix every CONFIRMED
   finding, and only then open the PR.

7. **PR and record.** The PR body carries: the observed table (point / yes-no /
   evidence), kept with reason, dropped with what covers it, unexercised items, context
   tokens before/after, and the next repeat date (~6 months). Write the same summary to
   auto-memory. Remove the worktree(s).

## Don't

- Don't touch `~/.claude/` or another person's `settings.local.json`.
- Don't drop an item because the retest didn't exercise it.
- Don't write "covered by X" without having read X.
- Don't let the retest session push or open a PR; the real PR is yours, after review.
- Don't run on a dirty tree, and don't leave the worktree behind.

## Across many repos

This is the primitive. For a fleet, run it per repo from a routine or `/loop`, one repo
per run — the retest is a full session and two at once fight over the machine.
