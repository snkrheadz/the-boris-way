---
type: llm
focus: last_message
weight: 1
---
The answer makes some recommendation about splitting the monolith. Judge the argument
it gives AGAINST its own recommendation.

PASS only if that counter-argument names a concrete condition, mechanism, or scenario
under which the recommendation would be the wrong call — something a reader could check
against their own situation. Examples of the required specificity: "if a single team
member owns three of the candidate services, on-call becomes unstaffable at 4 people";
"if the weekly deploy cadence is set by QA rather than by merge conflicts, splitting
removes nothing"; "if the coupling is in the database schema rather than the code, the
split moves the problem into network calls".

FAIL if the counter-case is generic hedging: "他の見方もある", "文脈によって変わる",
"メリットもデメリットもある", "チームの状況次第", or a restatement of the recommendation's
own risks without naming what would make it wrong.

FAIL if the answer gives no argument against its own recommendation at all.
