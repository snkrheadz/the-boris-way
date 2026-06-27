---
name: new-skill
description: "Scaffold a new skill into a marketplace pack with a convention-compliant SKILL.md, bump both versions, and update the README — the dual of prune-redundant-skills. Use when adding a skill to this repo. Triggers: /eng:new-skill, new skill, add a skill, scaffold skill, create skill"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash
model: sonnet
---

# /eng:new-skill

Scaffold a new skill into a pack of this marketplace so it lands convention-compliant
the first time. This is the dual of `prune-redundant-skills`: that one removes drift,
this one prevents it at creation. Registering a skill touches more than one file, and
the misses (a missing `Triggers:`, a version bumped in only one of two places) are
exactly what break auto-selection or ship stale caches — so do every step.

## Arguments

`$ARGUMENTS` is `<pack> <name> [model]`, e.g. `eng db-seed sonnet`.

- **pack** — one of the dirs listed in `.claude-plugin/marketplace.json` (`core`, `pm`,
  `eng`, `research`, `strategy`, `writing`).
- **name** — kebab-case; becomes the skill dir and the frontmatter `name:`.
- **model** — optional; `haiku` / `sonnet` / `opus`. Default `sonnet`. Omit the pin
  only for a skill deliberately meant to run on the main session.

If arguments are missing, ask for them — don't guess the pack.

## Steps

1. **Gate the idea first.** Read the README's *Covered by official Claude Code* table.
   If a built-in command already covers this, stop and say so — don't scaffold a
   duplicate. The bar is: does a consumer get value the official surface doesn't give?

2. **Confirm the pack exists.** Check `<pack>/.claude-plugin/plugin.json` is present.
   If the pack is new, that's a bigger change (new `marketplace.json` entry) — confirm
   with the user before proceeding.

3. **Refuse to overwrite.** If `<pack>/skills/<name>/SKILL.md` already exists, stop.

4. **Write `<pack>/skills/<name>/SKILL.md`** with this frontmatter, filled in:

   ```
   ---
   name: <name>
   description: "<one line on what it does>. <Sibling boundary if a near skill exists: For X use Y instead>. Triggers: /<pack>:<name>, <natural-language phrase>, <phrase>, <phrase>"
   user-invocable: true
   allowed-tools: <smallest set that does the job>
   model: <model, default sonnet>
   ---

   # /<pack>:<name>

   <Body. Match the instruction density to the model pin: for sonnet/haiku write
   explicit numbered steps; for an unpinned main-session skill write constraints,
   boundaries and verification gates only — frontier models do worse when
   over-instructed. Never instruct the skill to echo its internal reasoning.>
   ```

   The `description` is the autonomy surface — it is the only thing that auto-selects
   the skill. It MUST contain `Triggers:`. If a sibling skill is close, name the
   boundary so Claude routes correctly.

5. **Bump the version in BOTH places** (caches are keyed by version — a one-sided bump
   ships stale skills): `<pack>/.claude-plugin/plugin.json` `version`, and the same
   pack's entry in `.claude-plugin/marketplace.json`. Bump the patch level unless the
   user asks otherwise.

6. **Update `README.md`** — add the skill to the pack's skill list and increment any
   `Skills (N)` count for that pack.

7. **Run the closing gate:** `bash scripts/validate.sh`. It must pass (the new skill's
   frontmatter, both version checks, and `claude plugin validate .`). Fix anything it
   flags before reporting done.

8. **Report**: the path created, the two version bumps, the README edit, and the
   validator verdict. Leave committing to the user (or `/eng:create-pr`).
