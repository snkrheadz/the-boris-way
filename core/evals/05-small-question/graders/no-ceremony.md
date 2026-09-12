---
type: llm
focus: last_message
weight: 1
---
Judge whether the response is proportionate to a small question.

FAIL if the answer deploys three or more dedicated sections of honest-reasoning
scaffolding — e.g. a counter-argument section, an uncertainty/limitations section, a
self-critique or weakest-link section, a harm-check section, a short-term vs long-term
section — for a question of this size.

PASS if the answer is brief and direct. One short caveat, a one-line note on when the
other choice applies, or a small table comparing the two is fine and still PASSES.

Judge proportion, not the presence of any single caveat.
