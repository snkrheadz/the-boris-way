# Context-audit principles

The evolving checklist `/core:context-audit` evaluates a repo against. This file is
the single source of truth — grow it here (one entry per lesson + patch version bump),
never in per-repo copies.

Entry format:

```
## P<n> — <statement>
- Why: <the reason, with source>
- Detect: <how to check — cheap and greppable where possible>
- Fix route: <which primitive repairs the gap>
```

---

## P1 — Verification fires from a skill description, not human memory

- Why: checking that depends on someone remembering to ask gets skipped, and bad
  changes slip through exactly once-in-a-while. A skill whose `description:` matches
  "work finished" fires on its own. (Anthropic, *Claude in Action* — verification
  skills lesson, 2026.)
- Detect: the repo has gate-shaped prose (a "run before declaring done / before
  PR" checklist in CLAUDE.md, a verify entrypoint script) **but no**
  `.claude/skills/*/SKILL.md` whose `description:` auto-triggers on completion
  (grep descriptions for done/完了/PR前/verify/gate-style trigger phrases). Prose
  pointer in CLAUDE.md + auto-firing skill = PASS; prose checklist alone = GAP.
- Fix route: `/core:tune-claude-md` — its Stage 2 routes the procedure to
  `.claude/skills/<name>/SKILL.md` and Stage 3 creates the file. Seed the new skill's
  content with P2's weakening judgement while you're there.

## P2 — Green gates are audited for weakening

- Why: a test can be quietly loosened so it passes no matter what; exit 0 and
  green lint close nothing on their own. "Done" = the gates ran AND the diff shows no
  check was weakened to get there. (Same source as P1.)
- Detect: the repo has a verification entrypoint (verify script, test suite, CI
  gate) **but no instruction anywhere** (verification skill, CLAUDE.md) to read the
  diff for weakened checks — assertions removed from tests, skips/comment-outs added,
  linter or secret-scanner exclusions widened, verify script's own checks deleted or
  its SKIP conditions broadened.
- Fix route: add a weakening-judgement step to the repo's verification skill
  (reference shape: laptop repo `.claude/skills/verify-work/SKILL.md`). If no
  verification skill exists, fix P1 first — this step lives inside it.

## P3 — Must-not-skip rules are hooks, not prose

- Why: CLAUDE.md and skills are instructions Claude follows; a hook is code that
  runs. If skipping the rule is unacceptable, don't leave it to instruction-following.
  (Same source; also the promote-to-code lens.)
- Detect: deterministic, gate-shaped imperatives in CLAUDE.md ("always X before
  Y", "never Z") with no corresponding hook wired in settings — cross-check
  `.claude/settings.json` hook entries against the prose. Exclude imperatives whose
  satisfaction is a human act ("get explicit human approval first") — those are P4,
  not gaps.
- Fix route: `/core:promote-to-code` — it judges promotability and deletes the
  prose in the same change that adds the enforcement.

## P4 — "A human approved this" cannot be guaranteed by anything inside the repo

- Why: the agent can write any file in the repo, so an approval marker, a PR-body
  approval field, an approval file, or a settings opt-in can all be produced by the
  agent itself and prove nothing about a human having approved. The most a repo-side
  mechanism buys is upgrading a *silent* change into a *visible, explicit bypass* —
  the same strength as the existing allow-marker family (`hardcoded-id-allow` etc.).
  Enough for the typo class, not for approval of irreversible operations. (medii-aws-infra
  audit, 2026-09-10: trying to hook the "human must explicitly approve Object Lock
  changes on the audit-archive bucket" rule showed every approval channel — pre-commit
  grep + marker, PreToolUse block + env-var opt-in, PR-body field + CodeRabbit check —
  was forgeable by the agent.)
- Detect: two stages. (1) Among the imperatives P3 picks up, any whose satisfaction
  depends on a human act ("必ず人間の明示承認を得る", "get explicit approval before
  running") is **excluded from P3** and never reported as GAP. (2) Search the target
  repo for where it declares the rule judgement-bound — a "needs human review" list,
  a section headed "judgement-only guardrails", an ADR deciding not to mechanise —
  and, if found, report `N/A` quoting that declaration.
- Fix route: none (close as `N/A`). If the same rule also carries an invariant that
  is machine-checkable independent of approval (a value range, a required structure),
  route only that part to `/core:promote-to-code`.
