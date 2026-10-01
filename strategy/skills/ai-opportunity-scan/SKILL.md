---
name: ai-opportunity-scan
description: "Find where your expertise x AI opens unique opportunity: the bottlenecks AI now unlocks, the first-mover window, appreciating skills, new roles/products to create, and 30-day experiments aimed at 10x (not 10%). Triggers: /strategy:ai-opportunity-scan, AI opportunities for me, where to build with AI, AI opportunity, how do I use AI to get ahead"
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebSearch
model: sonnet
---

# AI Opportunity Scan

Find where the user's specific expertise intersects with AI to create outsized value. The
inverse of the career scan's defense — this is offense.

> Honest framing: AI is moving the bottlenecks of what's buildable, and people at the
> intersection of a domain and AI can create real value. But **first-mover windows are real
> yet hard to time precisely** — don't assert a specific countdown (e.g. "12–18 months") as
> fact; describe the window as finite and show the reasoning. Ground claims in observable
> capability, not hype.

## Step 1: Gather the position

From input or via `AskUserQuestion`: the user's skills/expertise, industry, network/assets,
and any opportunity they're already eyeing.

## Step 2: The intersection

Where does **their** expertise × AI create value a generalist-with-AI cannot? The edge is
domain depth AI lacks, paired with AI's leverage.

## Step 3: Unlocked bottlenecks

What was previously too slow / costly / skill-gated that AI now makes feasible — and which
of those sits inside the user's domain?

## Step 4: First-mover window

Where is there an opening before it crowds, and roughly how durable is it? Give the
reasoning for the window's size; present it as a range with uncertainty, not a deadline.

## Step 5: Appreciating skills

Which of the user's skills grow *more* valuable as AI handles the routine, and should be
leaned into now.

## Step 6: New roles and products

Roles, services, or products that don't exist yet but become possible at this intersection.

## Step 7: Leverage the network

How to use existing relationships and assets to move at the AI intersection faster than a
cold start would allow.

## Step 8: 30-day experiments

2–4 small, concrete experiments runnable within 30 days to test the best opportunities
cheaply. Each: hypothesis, the smallest test, and what result would justify going bigger.

## Step 9: Aim for 10x, not 10%

Bias recommendations toward step-changes (a new capability, a new market) over incremental
improvement. Name which ideas are 10x vs merely 10%.

## Output

Default to a Markdown report (offer an HTML page / Artifact if the user wants to share it). For a file, resolve
`ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"` and save under `$ROOT/docs/`.

```
## AI Opportunity Scan — <user / domain>

### Intersection map (expertise x AI)
### Bottlenecks AI now unlocks
### First-mover window: ~<range> (reasoning: ...)
### Skills to lean into
### New roles / products to create
### Network leverage
### 30-day experiments
1. <hypothesis> -> <smallest test> -> <signal to scale>
### 10x vs 10%
```

## Notes

- Concrete over grand: a runnable 30-day experiment beats a visionary essay.
- Tie every opportunity back to the user's actual edge — generic "build an AI startup"
  advice is worthless.
- Don't manufacture urgency; the window framing must be honest, with its reasoning shown.
