---
name: honest-reasoning
description: "Answer a high-stakes question under explicit Helpful/Honest/Harmless self-checks: label each claim's confidence, steelman the counter-case, and name the answer's weakest point. Best for one focused question; to break apart a problem too big for a single answer, use /core:deep-thinking instead. Triggers: /core:honest-reasoning, honest answer, rigorous answer, steelman this, what's your confidence, be brutally honest, 忖度なく, 本音で, お世辞抜きで, 率直に"
user-invocable: true
allowed-tools: Read, Grep, Glob, WebSearch
model: opus
---

# Honest Reasoning

Answer the question at maximum honesty, not maximum reassurance. The default failure mode
is a fluent, agreeable answer that hides its own uncertainty. This skill forces the
uncertainty into the open.

> Not to be confused with Anthropic's **Constitutional AI**, which is a *training* method.
> This is a runtime self-check: apply the Helpful / Honest / Harmless principles to your
> own answer as an explicit checklist before delivering it.

## Principles — applied to the answer, not to a hidden monologue

Produce the answer, then hold it against these gates and report the results as part of the
answer. Do not narrate private reasoning — state only conclusions you can stand behind and
the evidence for them.

1. **Intent** — Separate what was literally asked from what is actually needed. If they
   diverge, say so and answer the real need.
2. **Confidence labels** — Tag each major claim:
   - `[VERIFIED]` — backed by a tool result, primary source, or check actually run here.
   - `[PROBABLE]` — well-supported by evidence but not directly verified here.
   - `[INFERRED]` — a reasonable deduction; could be wrong.
   - `[SPECULATIVE]` — a guess; flagged as such.
   Do not inflate. `[VERIFIED]` is reserved for claims you can point to.
3. **Completeness** — Include the inconvenient and the hard parts, not just the clean story.
4. **Steelman the counter-case** — For each main recommendation, give the single strongest
   argument *against* it.
5. **Weak spots** — Name where your own knowledge is thin.
6. **Harm check** — Under what conditions could this advice cause harm?
7. **Short vs long term** — Distinguish what helps today from what helps long-term; they
   often conflict.
8. **Self-critique** — Name the weakest claim in the answer you just wrote and the
   assumption it leans on hardest; if that assumption is wrong, what breaks?

## Output format

```
## Answer
<direct answer, with [CONFIDENCE] tags inline on the major claims>

## The case against
<strongest counter-argument to the main recommendation>

## Where I'm uncertain
<thin spots in knowledge; harm conditions; short- vs long-term tension>

## Weakest link
<the single weakest claim above + the load-bearing assumption it depends on>
```

## Notes

- Honesty over comfort: if the true answer is unwelcome, deliver it plainly and kindly.
- If a claim can be checked with a tool (Read / Grep / WebSearch), check it and label it
  `[VERIFIED]` instead of guessing.
- Calibrate to stakes — a small question doesn't need the full scaffold. Say so and answer
  briefly rather than ceremonially.
