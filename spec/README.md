# spec — spec-driven development pipeline (the Boris way)

A pack of human-gated slash commands that take a change from a one-line idea (or a
repo audit) to a mergeable PR, one phase at a time. Verification-first: observable
acceptance criteria, per-task verification, and an isolated-context adversarial review
before any PR. Repo-agnostic — install it anywhere.

> Origin: distilled from snkrheadz's personal dotfiles workflow; an unofficial,
> personal systematization of practices popularized by Boris Cherny. Not an official
> Anthropic product.

## Install

```
/plugin install spec@<this-marketplace>
```

## The flow

```text
        ┌─ your one-line intent / a repo's problem
        │
/spec:scan          ← (optional) audit a repo, emit an ROI-ranked backlog of intents
        │  → specs/<date>-scan/scan.md
        ▼
/spec:requirement   ← intent → requirement with observable acceptance criteria (EARS)
        │  → specs/<id>/requirement.md     … Gate ① (human approves)
        ▼
/spec:design        ← requirement → design (DDD / clean architecture / boundaries)
        │  → specs/<id>/design.md          … Gate ② (human approves)
        ▼
/spec:tasks         ← design → ordered, independently-verifiable tasks
        │  → specs/<id>/tasks.md
        ▼
/spec:implement     ← implement the tasks, keeping running implementation notes
        │
/spec:review        ← isolated-context subagent reviews the diff against the spec
        │  → specs/<id>/review.md          … Gate ③ (pass → PR)
        ▼
/eng:create-pr      ← sync base, open PR (merge stays human).  [eng pack]
```

Each command runs ONE phase, writes one artifact under `specs/<id>/`, and stops for
your review. The last line of each command's output tells you the exact next command.

## Commands

| Command | Role | Input | Artifact | Stops at |
| --- | --- | --- | --- | --- |
| `/spec:scan [path]` | Audit agent-readiness, emit ROI-ranked intent backlog | repo (default cwd) | `scan.md` | scan done |
| `/spec:requirement "<intent>"` | Intent → requirement (EARS acceptance criteria) | intent text / intent.md | `requirement.md` | **Gate ①** |
| `/spec:design <id>` | Approved requirement → design | spec id | `design.md` | **Gate ②** |
| `/spec:tasks <id>` | Approved design → ordered verifiable tasks | spec id | `tasks.md` | ready to implement |
| `/spec:implement <tasks>` | Implement, keeping implementation notes | tasks.md path | code + notes | — |
| `/spec:review <id>` | Isolated-context adversarial review of the diff | spec id | `review.md` | **Gate ③** |

`/spec:scan` uses the portable rubric in `skills/scan/rubric.md` (the Honk three
pillars). PR creation and the closing gate are handled by the **eng** pack
(`/eng:create-pr`, `/eng:verify-work`) — install it alongside.

## The human gates

Approval = editing the `status:` line in the generated artifact. Commands refuse to
advance until the prior phase is approved.

| Gate | File | How to approve |
| --- | --- | --- |
| Gate ① | `requirement.md` | review, then `status: awaiting-human-gate-1` → `status: approved` |
| Gate ② | `design.md` | review, then `status: awaiting-human-gate-2` → `status: approved` |
| Gate ③ | `review.md` | `status: pass` → PR; `changes-requested` → send Blockers back to implement |

## Why this shape

- **One command = one phase**, always stopping at a gate; never mix altitude
  (no class names in requirements, no code in design).
- **Acceptance criteria must be observable** — if you can't state how to verify it,
  it isn't a requirement yet.
- **Tasks are independently verifiable** — each carries its own verification and keeps
  the tree green.
- **Review runs in an isolated context** — a subagent reads the diff and actually runs
  the verification, so review isn't a rubber stamp.
- **Merge stays human.** The pipeline goes up to PR creation.

## Artifact layout

```text
specs/<id>/
├── intent.md        # the original one-liner (verbatim), when applicable
├── requirement.md   # background / scope / acceptance criteria (EARS) / how to verify  ← Gate ①
├── design.md        # domain model / layers / decisions / criteria↔design map          ← Gate ②
├── tasks.md         # ordered tasks; each has "where / how to verify / origin"
└── review.md        # criteria coverage / findings (by severity) / verification log     ← Gate ③
```
