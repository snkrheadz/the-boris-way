---
name: prune-redundant-skills
description: "Audit this marketplace's skills/agents against Claude Code's official built-in commands and plugins, remove the ones whose real value is already covered, then fix every dependent file (README, plugin.json, marketplace.json, cross-skill links). Triggers: /eng:prune-redundant-skills, prune redundant skills, audit skills against official commands, remove duplicate skills, drop skills covered by official commands"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, AskUserQuestion
---

# /eng:prune-redundant-skills

This marketplace exists to ship **only the gaps** the official Claude Code commands don't
cover. The official surface grows over time, so a skill that was a genuine gap-filler last
quarter can quietly become a duplicate of a now-shipping built-in. This skill is the
recurring audit that keeps the repo lean: it compares every local skill/agent against the
current official baseline, removes what's redundant, and repairs every file that referenced
the removed item.

It is **conservative by design**: when in doubt, keep. A redundant skill is a minor wart;
deleting a skill the user still relies on is a real regression. Deletion is `git`-reversible,
but the bar for "redundant" is high.

## Usage

```
/eng:prune-redundant-skills            # audit the whole repo, propose removals, confirm, apply
/eng:prune-redundant-skills create-pr  # audit only the named skill(s)/agent(s)
```

This skill **stops after the working tree is clean and consistent**. It does not commit,
push, or open a PR — chain `/eng:create-pr` for that, so the audit and the publish step
stay independently reviewable.

## Procedure

### 1. Inventory the repo
List every skill and agent, and write down — in one line each — the skill's **non-trivial
core**: what it actually contributes *after* you strip away plain `gh`/`git`/shell
one-liners that any model would write inline.

```bash
find . -name SKILL.md | sort                       # skills
find . -path '*/agents/*' -name '*.md' | sort       # agents (if any)
```

### 2. Derive the *current* official baseline — do not trust a hardcoded list
The set of official commands/skills is a **moving target**; re-derive it every run from,
in priority order:
1. The **live list of available skills/commands** in this session (the system surfaces
   built-ins like `/code-review`, `/simplify`, `/verify`, `/run`, `/init`,
   `/security-review`, `update-config`, the `claude-code-guide` agent, and the official
   `commit-commands` / `document-skills` / `frontend-design` plugins).
2. The repo's own **"Covered by official Claude Code"** table in `README.md`.
3. Official docs (`WebFetch`/`WebSearch`) only when (1) and (2) leave you unsure whether a
   built-in covers the skill.

### 3. Classify each skill with the "non-trivial core" test
For each local skill, compare its non-trivial core against the baseline:

- **Redundant → remove.** The official command/skill performs the *same non-trivial work*.
  A thin wrapper over `gh`/`git` plus an official command counts as redundant — e.g. a
  "merge PR + clean worktree" skill is just `gh pr merge --delete-branch` + the official
  `/clean_gone`.
- **Builds on top of → keep.** It composes or extends a built-in rather than re-implementing
  it — e.g. `review-inbox` triages reviewer-assigned PRs and posts confirmed comments
  *using* `/code-review`. Keep these and make sure their docs say *how* they extend it.
- **Unique → keep.** No official equivalent.

When a removal would orphan a workflow, identify the **official replacement path** now —
you'll need it for the docs in step 6.

### 4. Confirm before deleting
Present findings as a table (`skill | non-trivial core | official equivalent | verdict`)
and use `AskUserQuestion` to confirm the removal set. Removing a skill changes the published
marketplace; never delete without explicit confirmation, even though git can undo it.

### 5. Remove confirmed-redundant skills
```bash
git rm -r <plugin>/skills/<name>          # or the agent path
```

### 6. Repair every dependent file — this is half the job
A removed skill leaves dangling references. Find them all, then fix each:

```bash
grep -rn "<removed-name>" . --include='*.md' --include='*.json' | grep -v '.git/'
```

Update, at minimum:
- **`README.md`** — the skill **count** (`Skills (N)`), the name list, the repository-layout
  blurb, and the Maintenance notes if they enumerate skills.
- **`<plugin>/.claude-plugin/plugin.json`** — drop the name from the `description`.
- **`.claude-plugin/marketplace.json`** — drop the name from that plugin's `description`
  (watch for the two descriptions drifting out of sync between the files).
- **Other `SKILL.md` files** — repoint any `Pairs with /…` or `[[link]]` that named the
  removed skill to the **official replacement** (don't just delete the sentence; tell the
  reader where the capability went).

### 7. Verify clean and consistent
```bash
grep -rn "<removed-name>" . --include='*.md' --include='*.json' | grep -v '.git/'   # expect: no hits
git status --short                                                                  # only intended changes
```
The re-grep returning nothing is the gate. Then hand back a summary: what was removed, the
official replacement, and every file touched.

## Notes

- **Conservative default**: unsure ⇒ keep. False deletion costs more than a redundant skill.
- **Counts and lists drift** — `README.md` and both JSON descriptions each carry their own
  copy of the skill list. Updating one and missing the others is the most common bug here;
  the step-7 re-grep is what catches it.
- **The baseline moves** — re-derive the official set each run; last audit's "gap" may now
  be a built-in.
- Pairs with `/eng:create-pr` to publish the pruning as a reviewable PR.
