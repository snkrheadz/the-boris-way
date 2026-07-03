---
name: maintain-marketplace
description: "Standing maintenance pass for this repo, run as an agent team: philosophy-gap-analyst, marketplace-quality-auditor, and marketplace-ops-manager in parallel, then synthesize, apply convention-backed fixes, and close with the gate. Run interactively or as a scheduled routine. Triggers: marketplace maintenance, メンテナンスパス, 定期監査, boris-way maintenance run"
user-invocable: true
# no model: pin — this skill deliberately orchestrates on the main session
---

Run the maintenance loop for the-boris-way. This is the standing replacement
for hand-prompted "Boris review" passes: the lead (you) coordinates the three
maintainer agents defined in `.claude/agents/` and owns the synthesis.

## Loop

1. **Fan out**: spawn `philosophy-gap-analyst`, `marketplace-quality-auditor`,
   and `marketplace-ops-manager` as parallel background teammates over a shared
   task list. Their charters are self-contained; pass nothing beyond "report
   against the current working tree".
2. **Synthesize**: collect the three reports, dedupe, then split findings into
   - **fix now** — mechanical and convention-backed (gate failures, missing
     `Triggers:`, doc drift, missed version bumps), and
   - **propose** — anything that changes distributed philosophy
     (`shared/CLAUDE.md`) or the authoring conventions. These always go to a
     human; never auto-apply them.
3. **Apply fix-now items** on a branch. Bump the pack version in BOTH
   `plugin.json` and `marketplace.json` whenever pack content changed.
4. **Close with the gate**: `bash scripts/validate.sh` must pass. Then open the
   PR via `/eng:create-pr` (it owns the base-sync guard — do not use a bare
   `gh pr create`), with a body carrying the findings table and the untouched
   "propose" list.

## Cadence

Weekly, or after a Claude Code release that grows the built-in surface. For
unattended runs, schedule this skill as a routine (`/schedule`); interactively,
just invoke it. A run with zero findings ends with "no findings" — do not
manufacture work.
