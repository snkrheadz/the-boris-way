# claude-skills — maintainer's map

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
```

## File map

```
.claude-plugin/marketplace.json   # the catalog: lists PACKS (not skills)
<pack>/.claude-plugin/plugin.json # per-pack manifest: name + description + version
<pack>/skills/<name>/SKILL.md     # skills are AUTO-DISCOVERED from here — not enumerated anywhere
<pack>/agents/<name>.md           # agents, same idea
core/hooks/                       # pre-tool-guard.sh + hooks.json (the only hook pack)
shared/CLAUDE.md                  # DISTRIBUTED philosophy (payload, not for this repo)
scripts/validate.sh              # the gate
```

Packs: `core` (install-first, role-agnostic) · `pm` · `eng` · `research` · `strategy` ·
`writing`. README has the per-pack skill lists.

## Conventions (the *why* — mechanics are in README → Authoring conventions / Maintenance)

- **A skill's `description:` is the autonomy surface.** It is the only thing that lets
  Claude auto-select the skill without being told. So every description ends with
  `Triggers:` and, where a sibling skill is close, names the boundary (`For X use Y
  instead`). `validate.sh` fails a description with no `Triggers:`. This is the single
  highest-leverage field in the repo — treat it as such.
- **Pin `model:` explicitly** (`haiku`/`sonnet`/`opus`). Unpinned skills inherit the
  main-session model, which on a Fable 5 session silently buys top-tier cost. Omit the
  pin *only* for a skill deliberately meant to run on the main session — `validate.sh`
  warns (not fails) so the choice stays visible.
- **Bump the version in BOTH** the pack's `plugin.json` and its `marketplace.json`
  entry on every content change. Installed caches are keyed by version; disagree and
  consumers serve stale skills forever. `validate.sh` fails a mismatch.
- **Built-in surface keeps growing** — run `/eng:prune-redundant-skills` periodically
  to catch drift before shipping a skill that duplicates a new native command.

