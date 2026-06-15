---
name: deep-thinking
description: "Crack a problem too complex for one pass: decompose into sub-problems, solve each, integrate, then check the seams for contradictions and blind spots. Triggers: /core:deep-thinking, think deeply, decompose this, hard problem, reason this through, work through this carefully"
user-invocable: true
allowed-tools: Read, Grep, Glob, WebSearch
model: opus
---

# Deep Thinking

For a problem a single-pass answer would oversimplify. Break it into parts, solve each on
its own, then integrate — and crucially, check whether the parts actually fit together.

> Sibling skill, different move: `first-principles` questions the premises and *redefines*
> the problem. `deep-thinking` takes the problem as posed and *decomposes and solves* it.
> Use `first-principles` when you suspect the question is wrong; use this when the question
> is right but big.

## Procedure

Work the stages in order. Each is a gate — don't carry an unsolved part forward.

1. **Decompose** — Break the problem into 3–7 sub-problems that can be solved
   independently. State them explicitly.
2. **Solve each** — Resolve each sub-problem completely before the next. Use tools where a
   fact can be checked rather than assumed.
3. **Integrate** — Combine the sub-solutions. Draw out the insight that appears only when
   they are put together.
4. **Check the seams** — Find contradictions *between* sub-solutions and resolve them. A
   clean part-by-part answer with conflicting parts is not a solution.
5. **Confidence** — Rate each sub-solution 1–10. Low scores mark where the integrated
   answer is fragile.
6. **Red-team** — State the strongest objection to the integrated conclusion, then defend
   it or revise it.
7. **Blind spots** — What did the decomposition leave out? Which assumption is doing the
   most work?
8. **Synthesize** — Deliver the integrated answer and name its weakest link.

## Output format

```
## Sub-problems
1. <sub-problem> — confidence X/10
...

## Integrated answer
<the synthesis, not a list of parts>

## Seams & contradictions
<conflicts found between parts, and how resolved>

## Strongest objection
<the red-team case, and your response>

## Weakest link
<the most fragile sub-solution or load-bearing assumption>
```

## Notes

- The value is in the integration and the seam-check, not the decomposition alone — a list
  of sub-answers is not the deliverable.
- If a sub-problem turns out to depend on another, note the dependency and order them.
- Match depth to stakes; not every problem needs all eight stages — say which you skipped.
