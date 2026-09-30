---
name: career-ai-scan
description: "Audit your role's exposure to AI: inventory tasks, classify each as replaceable / augmented / human-essential, estimate a timeline, and produce a survivability score with a concrete move-to-safety plan. This is the defense; for the offense (building outsized value at your expertise x AI) use /strategy:ai-opportunity-scan. Triggers: /strategy:career-ai-scan, will AI replace my job, AI career risk, am I going to be automated, future-proof my career"
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebSearch
model: sonnet
---

# Career AI Scan

A candid, structured assessment of how exposed the user's role is to AI, and what to do
about it. The deliverable is clarity and an action plan — not alarm.

> Honest framing (hold this throughout): AI is already changing many knowledge-work tasks,
> but **timelines are genuinely uncertain**. This is a probabilistic scenario to plan
> against, not a prediction. Ground claims in observable trends, never in a single pundit's
> authority, and flag low-confidence calls as such.

## Step 1: Gather the role

If the user passed a description, extract what you can. Ask (via `AskUserQuestion`) for
whatever is missing:

- Role / title and seniority (years of experience)
- Industry and company type
- Day-to-day responsibilities — the actual tasks, not the job title
- AI tools they already use, if any

## Step 2: Inventory the tasks

Break the role into its major recurring tasks (aim for 6–12), worked from real activities
rather than an idealized job description.

## Step 3: Classify each task

For every task, assign one label with a one-line rationale:

| Label | Meaning |
|---|---|
| `AI-REPLACEABLE` | AI can already do this at ≥80% of the user's quality today |
| `AI-AUGMENTED` | The user does it better/faster with AI, but the human is still core |
| `HUMAN-ESSENTIAL` | Depends on judgment, relationship, accountability, or presence AI can't supply |

## Step 4: Exposure score

Estimate what fraction of today's work AI could already perform at ≥80% quality. State the
assumption behind the number.

## Step 5: Timeline (with uncertainty)

For the replaceable/augmentable tasks, place each on a horizon — `now` / `1–2y` / `3–5y` /
`10y+` — and tag each with a confidence level. Be explicit that later horizons are softer.

## Step 6: Skill trajectory

- **Depreciating** — skills losing value as AI improves (the routine, the lookup-able).
- **Appreciating** — skills gaining value as AI commoditizes routine work (judgment, taste,
  relationships, cross-domain synthesis, accountability).

## Step 7: The centaur move

Where can the user's distinctly human strengths combine with AI so the pair is worth more
than either alone? ("Centaur" = a human + AI working as a team, a term from advanced
chess.) Give concrete pairings, not platitudes.

## Step 8: Irreplaceability audit

What does the user provide that no current AI can imitate — creativity, trusted
relationships, physical presence, ethical judgment, lived experience? This is the moat.

## Step 9: Score and plan

Produce a **survivability score (1–10)** with its reasoning, then a concrete plan to move
from at-risk toward irreplaceable: what to stop investing in, what to build, and a first
step for the next 30 days.

## Output

Default to a Markdown report (offer an HTML page / Artifact if the user wants to share it). If
writing to a file, resolve `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"` and
save under `$ROOT/docs/` — never a bare `./`.

```
## Career AI Scan — <role>

**Exposure**: ~X% of current tasks at-risk today (assumption: ...)
**Survivability**: N/10

### Task breakdown
| Task | Class | Horizon | Confidence |
...

### Skills to drop / double down on
### The centaur move
### Your moat (irreplaceability)
### 90-day move-to-safety plan
- Next 30 days: <first concrete step>
```

## Notes

- Be candid but constructive: the deliverable is agency, not anxiety.
- Don't overstate precision — a confident-sounding timeline you can't support is the main
  failure mode here. When unsure, say "uncertain" and give a range.
- Competitor reality check: it's fair to note peers who adopt AI may outpace those who
  don't — frame it as a trend, not a threat to inflame.
