---
name: promote-to-code
description: "Move a repo's deterministic prose rules out of CLAUDE.md and into an enforcement mechanism (hook / CI step / verify script) — the Boris Cherny principle of encoding domain knowledge into infrastructure instead of re-paying for it in tokens every run. A bundled audit.sh does the deterministic detection; this skill makes the promotion judgement and executes a move (delete the prose in the SAME change that adds the enforcement). Boundary: for CLAUDE.md wording quality and context tuning use /core:tune-claude-md; for spec-ifying the codebase itself use /spec:scan. This skill is ONLY the prose-rule → enforcement-mechanism move. Triggers: /core:promote-to-code, promote to code, encode this rule, move rule to a hook, enforce this in CI, stop re-solving this in tokens, CLAUDE.md rule to enforcement, audit rules for promotion."
user-invocable: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion
model: opus
---

# Promote to code

A CLAUDE.md rule is an instruction the model must re-read and re-obey every
session — knowledge you rent by the token. When a rule is **deterministic**
(its satisfaction can be checked mechanically), that rent buys nothing a hook,
CI step, or verify script wouldn't guarantee for free and forever. This skill
finds those rules and *moves* them into infrastructure.

**Move, not copy.** A promotion is only done when the enforcement mechanism
exists **and** the prose it replaces is deleted in the same change. Prose that
survives its own promotion is double bookkeeping — the exact rot this skill
exists to remove.

**Detection is code; judgement is yours.** The bundled `scripts/audit.sh` does
every deterministic check (it is the code half of Boris's split — a decision
made once, not re-reasoned each run). Your job is the half a script can't do:
deciding *which* candidates are worth promoting and *what invariant* each
enforcement should guard.

Target repo = the skill argument if given, else the current repo.

---

## Boundary (stay in your lane)

| If the real need is… | Use instead |
|---|---|
| CLAUDE.md is bloated / poorly worded / mis-routed context | `/core:tune-claude-md` |
| the *codebase* lacks tests / closed-loop verification | `/spec:scan` |
| **a deterministic prose rule should become an enforcement mechanism** | **this skill** |

If the audit surfaces work that belongs to a sibling, name it and hand it off —
don't do it here.

---

## Phase A — Audit (evidence only)

Run the detector against the target repo and present its findings **as
evidence**: `file:line` plus the check verdict, nothing more.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/promote-to-code/scripts/audit.sh" <target-repo>
```

- Report each check's PASS / FAIL / SKIP / WARN and its reason, and the
  `---CANDIDATES---` rows grouped by type (C1 expired, C2 double-bookkeeping,
  C4 imperative, C5 gate/CI drift).
- **No scoring.** Do not rate, grade, or assign points to rules or to the repo.
  "This rule is a candidate because audit flagged it at file:line" is the only
  form your Phase A claims take.
- A SKIP is a real result — surface it with its reason (a missing tool or absent
  input), never round it up to a pass.
- If `audit.sh` exits non-zero, a hard invariant is broken (an expired rule or a
  broken wired hook): call that out first — it is the most actionable finding.

## Phase B — Gate (human chooses)

Promotion changes how the repo is enforced; a human picks what gets promoted.

- Present the candidates and use **AskUserQuestion** to let the user select
  which to promote (and which to leave as prose or hand to a sibling skill).
- **Shared repo → branch + PR, never a direct commit to the default branch.**
  If the repo has other contributors (check `git log` authors / `.github`),
  the promotion goes through a branch and a pull request. Use `/eng:create-pr`
  so the PR opens against a fresh base.

## Phase C — Promote (the four-part set)

Each promotion is **incomplete unless all four hold** — if any is missing, the
rule is not promoted, it's just moved around:

1. **Enforcement body** — the hook, CI step, or verify script that makes the
   rule mechanical. Enforce the **invariant, not the procedure**: check that the
   guaranteed *state* holds, not that a particular tool was run. (Guard "the PR's
   base is not stale", not "the author ran /eng:create-pr" — a state a hook can
   verify, versus a habit it can't.)
2. **red → green demo** — a recorded run where the enforcement actually catches
   a violation (red), then passes once the violation is removed (green).
   Evidence it enforces, not just that it exists.
3. **Prose deletion in the same change** — remove the CLAUDE.md/`.claude` lines
   the enforcement now covers, in the same commit/PR (move semantics). The audit
   re-run should no longer surface those C2 candidates.
4. **Rollback note** — how to undo this promotion, written into the PR/commit
   body (revert the enforcement, restore the prose).

## Phase D — REVIEW.md (only what needs a human)

Harvest *why PRs get rejected in this repo* from the CLAUDE.md development notes
and recent review history:

```bash
gh pr list --state merged --limit 20
```

Sort each recurring rejection reason:

- **Mechanizable** (a check could catch it deterministically) → it is a Phase C
  promotion candidate, **not** a REVIEW.md line. Route it back to C.
- **Judgement-bound** (needs human taste — naming, API ergonomics, scope) →
  write it into `REVIEW.md` at the repo root.

REVIEW.md holds only what a script *can't* decide. If everything mechanizable
has been promoted, a short REVIEW.md is the correct outcome.

---

## Hard constraints

- **Deletion needs evidence.** Never propose removing a rule on the grounds that
  "the model already does this" without an eval result or a real transcript that
  shows it. An unbacked "the model knows this" is the one deletion rationale this
  skill forbids — cite proof or keep the rule.
- **Inapplicable checks are reported, not hidden.** If a check SKIPs (no CI, no
  hooks, no `.github`), say so with the reason, verify.sh-style — a SKIP is a
  finding.
- **Report evidence, not reasoning.** Present tool output and `file:line`
  citations; do not narrate an internal thought process.
- **One repo, one pass.** To sweep several repos, drive this skill per repo from
  a `/goal` or a routine — it is the primitive, not the loop.
