---
name: tune-claude-md
description: "Tune a repo's CLAUDE.md the Boris Cherny way — drive it to a high rubric score, then apply the context-not-rules lens (cut what the model already knows, split auto vs on-demand, route the 4 channels) and verify. Works on any repo, iteratively. Triggers: /core:tune-claude-md, tune CLAUDE.md, improve CLAUDE.md, Boris tune, context-not-rules audit, prune CLAUDE.md. For pure rubric scoring use /claude-md-management:claude-md-improver instead; this orchestrates that pass and layers Boris's philosophy on top."
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion
model: sonnet
---

# Tune CLAUDE.md (the Boris Way)

You tune a repository's `CLAUDE.md` so Claude operates **autonomously and optimally**.
The governing idea is one line:

> **More context = better performance. Supply context; don't add rules.**

A good rubric score is table stakes — the official `claude-md-improver` already gives
you that. Your value-add is the **Boris lens**: a CLAUDE.md earns its keep by carrying
*knowledge, a file map, and reasons* the model can't infer — not by repeating
general-purpose rules it already follows. You drive the score up, then prune and
re-route everything that fails the lens, then verify the score held.

If the user passed an argument, treat it as the target path (file or repo dir). Default
target: `./CLAUDE.md`. Only touch `~/.claude/CLAUDE.md` if the user explicitly asks.

---

## Stage 0 — Locate & baseline

1. Find the target `CLAUDE.md` (project root by default). If none exists, say so and
   offer to bootstrap a minimal one (Overview / Commands / File map) rather than tune.
2. Record a baseline: line count, section list, and whether it's committed
   (`CLAUDE.md`) or personal (`CLAUDE.local.md`).
3. **Never tune `shared/`-style distributed philosophy files as if they were a
   maintainer map** — if the repo separates the two (like this one), confirm which file
   you're tuning before editing.

## Stage 1 — Rubric pass (delegate; don't reimplement)

The scoring rubric is the official tool's job. Do **not** write your own scorer.

- If `/claude-md-management:claude-md-improver` is available, run it and apply its
  improvements. Repeat until the score plateaus near 100 (structure, conciseness,
  formatting — the table-stakes layer).
- If it is **not installed**, skip this stage gracefully: do the Boris lens standalone
  (it stands on its own), and tell the user that installing
  `claude-md-management` (https://claude.com/plugins/claude-md-management) adds a
  rubric score on top. Never block on the dependency.

## Stage 2 — The Boris lens (your core work)

Walk the whole file and classify every block against these six tests. This is where a
high-scoring-but-bloated CLAUDE.md gets fixed.

1. **rules → context test.** For each imperative or prohibition, ask: *does a current
   model already do this well?* ("write tests", "find the root cause", "keep it
   simple", "don't hardcode secrets"). If yes, it's micromanagement — **cut it**. Keep
   only what the model *can't* infer: this repo's facts, commands, and the *why* behind
   non-obvious conventions.
2. **auto vs on-demand.** For each block, ask: *is this needed every session?* If it's
   only sometimes relevant, it doesn't belong in always-loaded CLAUDE.md — move a
   repeated procedure to a slash command (`.claude/commands/<name>.md`) and a specific
   file's detail to an `@`-mention at point of use. Keep CLAUDE.md lean.
3. **4-channel routing.** Route each surviving block by what it *is*, not where it sits
   today. The channel splits further than "command vs `@`":

   ```
   always needed every session?            → CLAUDE.md (auto)
   a procedure Claude executes (steps)?
     ├─ needs fan-out / multi-agent         → .claude/agents/<name>.md
     ├─ reusable in-context, no external dep → .claude/skills/<name>/SKILL.md
     └─ otherwise                           → .claude/commands/<name>.md  (/project:<name>)
   reference knowledge (facts, not steps)   → .claude/context/<topic>.md  (@-mention, lazy)
   learning that grows in-session           → tasks/lessons.md via #
   ```
4. **reasons, not generalities.** A convention stays only if it carries its *reason*
   ("why we do it this way here"). A generic best practice with no repo-specific reason
   is a rule — cut or rewrite it with the why.
5. **add ⇒ prune.** Flag bloat, contradictions, and duplication. CLAUDE.md is grown
   *and* pruned at the same rhythm, never just appended to.
6. **self vs team.** Check placement: shared facts belong in committed `CLAUDE.md`;
   personal/absolute-path/machine-specific notes belong in `CLAUDE.local.md`. Move
   anything that's in the wrong file.

## Stage 3 — Distill, apply & verify

1. Present the change as a **diff with rationale** before writing — for each removal,
   name *why* ("model already knows this" / "moved to on-demand" / "no repo-specific
   reason"). Let the user confirm direction before you edit (explore → plan → confirm →
   implement).
2. **Apply, and actually create the move targets.** A block "moved off CLAUDE.md" is only
   half done until its destination file exists — otherwise you've deleted context, not
   re-routed it:

   | moved block | create |
   |---|---|
   | repeated procedure | `.claude/commands/<name>.md` (kebab-case) → `/project:<name>` |
   | reusable in-context procedure | `.claude/skills/<name>/SKILL.md` |
   | fan-out / multi-agent procedure | `.claude/agents/<name>.md` |
   | reference detail | `.claude/context/<topic>.md` — first line a `<!-- read when: … -->` comment |

   - **Pruning is archival, not destruction**, especially in any unattended/loop run:
     move removed-but-maybe-useful blocks to a `CLAUDE.archive.md` (or a clearly marked
     trailing section) rather than deleting outright.
3. **Make the new artifacts discoverable from CLAUDE.md.** Add or refresh a routing table
   so the model knows what exists *and when to load it* — an `@`-path with no load trigger
   never gets read at the moment it's needed (writing time is the most dangerous gap to
   miss):

   ```markdown
   ## Context (`@` on-demand)
   | `@` path | read when |
   |---|---|
   | `@.claude/context/<topic>.md` | <trigger> |

   ## Commands / Skills
   | name | trigger |
   |---|---|
   | `/project:<name>` | <when> |
   ```

4. **Verify integrity before reporting:**
   - every `@.claude/...` reference in CLAUDE.md (and inside the context files) resolves
     to a file that exists; no other doc (README, etc.) links a section you just cut.
   - any existing artifact you now route *into* isn't **stale** — paths or var-names
     carried over from another repo. Flag conservatively: annotate `⚠️ not usable in this
     repo` rather than delete. A full `.claude/` staleness sweep is
     `/eng:prune-redundant-skills`' job, not this skill's — don't widen scope into it.
   - re-run the rubric pass (Stage 1) if available; a leaner file should not score worse.
     If it does, surface the tension.

## Stage 4 — Report

Output a short report:

```markdown
## CLAUDE.md tuning report — <target>

Score: <before> → <after>   (rubric: claude-md-improver | not installed)
Size:  <before> → <after> lines

### Cut (rules the model already knows / no reason)
- "<line>" — model already does this
- ...

### Moved off CLAUDE.md (auto → on-demand)
- "<block>" → slash command `.claude/commands/<name>.md`
- "<detail>" → use `@<path>` at point of need

### Re-placed (self vs team)
- "<note>" → CLAUDE.local.md (machine-specific)

### Created (new artifacts, now discoverable from CLAUDE.md)
- `.claude/commands/<name>.md` → `/project:<name>`
- `.claude/context/<topic>.md` → `@`-referenced with a load trigger

### Reference integrity
- ✅ all `@`-mentions in CLAUDE.md resolve   ⚠️ <stale artifact flagged, not deleted>

### Kept (earns its keep: facts / map / reasoned conventions)
- ...
```

---

## Driving it across many repos

This skill is the **primitive**, not the loop. To run it repeatedly:

- finish a single repo → `/goal "CLAUDE.md scores ≥95 and passes the Boris lens"`
- unattended periodic maintenance over several repos → a **routine** (the monthly/weekly
  pruning loop), running this skill per repo.

## Don't

- Don't reimplement the improver's scoring — orchestrate it.
- Don't add general-purpose rules. If you feel a rule is needed, first ask whether
  CLAUDE.md / a command / an `@`-mention can *supply the context* instead.
- Don't hard-delete in unattended runs — archive.
- Don't merge a distributed-philosophy file with a maintainer map; tune the right one.
