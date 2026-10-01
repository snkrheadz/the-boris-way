---
name: industry-ai-map
description: "Map how AI will reshape an industry in three waves (1-2y / 3-5y / 5-10y): what gets automated, how value chains rebuild, who wins and loses, the new roles, and a 90-day plan to lead rather than lag. Industry/sector level; for your own role's exposure use /strategy:career-ai-scan. Triggers: /strategy:industry-ai-map, how will AI change my industry, industry AI disruption, AI transformation roadmap, future of my industry"
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebSearch
model: sonnet
---

# Industry AI Map

A strategic map of how AI is likely to transform a specific industry, and where the user
can position to lead. Concise and decision-oriented.

> Honest framing: AI is compressing the pace of change in many industries, but **the
> timeline is uncertain and uneven across sectors**. Treat the waves below as scenarios to
> plan against, not forecasts. Tag soft calls with low confidence and ground claims in
> observable adoption, not a single source's authority.

## Step 1: Gather context

From the user's input or via `AskUserQuestion`: the industry, company size, the user's role
in it, and the current level of AI adoption they see around them.

## Step 2: Today's baseline

Where is the industry now on AI adoption — `nascent` / `developing` / `advanced`? Cite the
concrete signals (what's already deployed vs still manual).

## Step 3: The three waves

For each wave, name the specific tasks/roles/structures affected and tag a confidence level
(later waves are softer):

- **Wave 1 (1–2y)** — the first tasks and roles to be automated or heavily augmented.
- **Wave 2 (3–5y)** — business models and value chains that get restructured.
- **Wave 3 (5–10y)** — what the industry looks like once AI is the default.

## Step 4: Winners and losers

Who thrives and who erodes — by role, by business type, by position in the value chain —
and why.

## Step 5: New roles

The job titles and functions that don't exist yet but plausibly emerge.

## Step 6: How the money moves

How profit generation shifts: what gets commoditized, where new margin pools open.

## Step 7: Adaptation window and plan

How much time the user realistically has to adapt (a range, with uncertainty), then a
**90-day plan** to get ahead of the curve in their specific seat.

## Output

Default to a Markdown report (offer an HTML page / Artifact if the user wants to share it). For a file, resolve
`ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"` and save under `$ROOT/docs/`.

```
## Industry AI Map — <industry>

**Adoption today**: nascent / developing / advanced (signals: ...)

### Wave 1 (1-2y)   [confidence: ...]
### Wave 2 (3-5y)   [confidence: ...]
### Wave 3 (5-10y)  [confidence: ...]

### Winners / losers
### New roles emerging
### How value / margin shifts
### Adaptation window: ~<range>
### 90-day plan to lead
```

## Notes

- Specific beats sweeping: "underwriting triage automates first" is useful; "AI changes
  everything" is not.
- Distinguish explicitly what's already happening from what's speculative.
- If the industry has strong regulatory or physical constraints, weigh them — they often
  slow the waves materially.
