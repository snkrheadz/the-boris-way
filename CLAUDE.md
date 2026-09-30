# the-boris-way — maintainer's map

Maintainer context for **working *on* this repo**. `shared/CLAUDE.md` carries the
distributed workflow philosophy (Channel B → consumer's `~/.claude/CLAUDE.md`).
Authoring details live in `README.md`; this file only carries what's needed every session.

## Overview

A Claude Code skill **marketplace**: packs of skills/agents/hooks installed via
`/plugin`. The bar for adding anything is one line — *"does a consumer get value the
official Claude Code commands don't already give them?"* If a built-in covers it, we
don't ship it (see README → *Covered by official Claude Code*).

## Commands

```bash
bash scripts/validate.sh      # closing gate (run before every PR) — JSON, version agreement, skill frontmatter; "done" = catalog installs & skills selectable
claude plugin validate .      # authoritative catalog check (also run inside validate.sh)
/eng:new-skill <pack> <name>  # scaffold SKILL.md + bump both versions; then run the gate
bash scripts/eval-init.sh     # scaffold a blank eval case into every local pack (idempotent).
                              # --bare templates only: a real suite needs `cd <pack> && claude plugin eval init`
                              # with a human in the loop — inside a session that command writes nothing.
```

## File map

```
.claude-plugin/marketplace.json   # the catalog: lists PACKS (not skills) + PROXY entries (third-party plugins, source = git-subdir + pinned sha)
<pack>/.claude-plugin/plugin.json # per-pack manifest: name + description + version
<pack>/skills/<name>/SKILL.md     # skills are AUTO-DISCOVERED from here — not enumerated anywhere
<pack>/agents/<name>.md           # agents, same idea
core/hooks/                       # pre-tool-guard.sh + stop-verify-gate.sh (+ *_test.sh) + hooks.json (the only hook pack)
.claude/agents/                   # maintainer team (NOT distributed): gap-analyst / quality / ops
.claude/skills/                   # /maintain-marketplace — the loop that runs the team
shared/CLAUDE.md                  # DISTRIBUTED philosophy (payload, not for this repo)
scripts/validate.sh              # the gate
```

Packs: `core` (install-first, role-agnostic) · `pm` · `eng` · `research` · `strategy` ·
`writing` · `spec` · `craft`. README has the per-pack skill lists.

## Conventions (the *why* — mechanics are in README → Authoring conventions / Maintenance)

- **A skill's `description:` is the autonomy surface.** It is the only thing that lets
  Claude auto-select the skill without being told. So every description ends with
  `Triggers:` and, where a sibling skill is close, names the boundary (`For X use Y
  instead`). `validate.sh` fails a description with no `Triggers:`. This is the single
  highest-leverage field in the repo — treat it as such.
- **Pin `model:` explicitly** (`haiku`/`sonnet`/`opus`). Unpinned skills inherit the
  main-session model, which on a Fable 5.x session silently buys top-tier cost. Omit the
  pin *only* for a skill deliberately meant to run on the main session — `validate.sh`
  warns (not fails) so the choice stays visible.
- **`context: fork` runs the skill in an isolated subagent.** Add it when the skill goes
  off to produce a bounded deliverable or finding and returns a summary — work whose
  intermediate tokens (file reads, query output, test logs) would otherwise flood the
  main thread (`db-query`, `techdebt`, `verify-work`, `craft:produce`).
  Omit it when the skill's output *is* the conversational answer or it needs the live
  session / user back-and-forth — the reasoning family (`deep-thinking`,
  `honest-reasoning`, `first-principles`, `life-decision`) and interactive/sequential
  skills (`create-pr`, `review-inbox`, the spec phases). When unsure, omit — main-session
  is the safe default.
- **Bump the version in BOTH** the pack's `plugin.json` and its `marketplace.json`
  entry on every content change. Installed caches are keyed by version; disagree and
  consumers serve stale skills forever. `validate.sh` fails a mismatch.
- **Proxy entries pin a full sha.** A third-party plugin we recommend is re-exported
  from the catalog (`source: { git-subdir, url, path, sha }`) rather than vendored or
  "add their marketplace too". Contents stay upstream; fresh installs get exactly the
  pinned commit. The version string is upstream's `plugin.json` (it wins over ours), so
  a pin bump lands for already-installed consumers only when upstream bumped its version
  too — otherwise they must uninstall + reinstall. `validate.sh` fails an unpinned proxy.
- **Built-in surface keeps growing** — run `/eng:prune-redundant-skills` periodically
  to catch drift before shipping a skill that duplicates a new native command.
- **A pilot eval run is where you check the graders, not the score.** When authoring a
  suite (`cd <pack> && claude plugin eval init`), read BOTH arms of every pilot. A grader
  that passed in the without arm too carries no Δ — so it may not be what decides the
  case. Either it is scoped wrong (a regex over the whole file matching for an unrelated
  reason — anchor it to the field it claims to test), or it is a **guard**, which is
  fine but must be named as one: a `file_exists` on a side-effect case passes in both
  arms on purpose, and it is what stops that case's `count:0` graders from passing
  vacuously on a file that was never written. Keep guards, weight template-fidelity
  checks at 0.5, and let an outcome grader that actually moves Δ carry the verdict.
  Read Δ, never the pass rate.
- **Then read the full run's firing rate per run, not the mean.** A pilot cannot show
  this — `runs: 3` can. What a case's Δ means depends on how often the skill actually
  fired: 3/3 → Δ measures answer quality; partial → Δ mixes quality with trigger luck;
  0/3 → that case measured nothing about the skill and the sign of its Δ is noise (core's
  `03-migration-call` read −0.22 this way). Per-run detail lives in
  `arms.<arm>[].graders[]`, not the summary line — a `FAIL FAIL FAIL` in the NOTES column
  is one run's three judge votes. **When a case reads 0/3, check whether `Triggers:` share
  a literal with the prompt before touching the graders** — that is what `validate.sh`
  check 4e warns about, and it was the cause both times here.

## Maintenance loop

Recurring upkeep is a team pass, not a hand-prompt: `/maintain-marketplace` runs
`philosophy-gap-analyst` · `marketplace-quality-auditor` · `marketplace-ops-manager`
(`.claude/agents/`, not distributed) — mechanics live in the skill itself. Run it
weekly or after a Claude Code release, or schedule it as a routine. The standing
rule: changes to `shared/CLAUDE.md` are always proposed, never auto-applied.

