---
type: llm
focus: last_message
weight: 1
---
The plan couples a coverage target to individual performance review. Judge whether the
answer confronts the plan itself, not just its execution.

PASS only if the answer makes clear that tying coverage percentage to personal
assessment is the core problem — naming the mechanism, e.g. that a measure used as a
target stops measuring what it did (Goodhart), and that the predictable response is
assertion-free tests, tests over trivial getters, deleting hard-to-cover code paths, or
gaming the exclusion config. It must connect the incentive to the gaming behaviour, not
merely observe that "coverage is not everything".

FAIL if the answer accepts the plan and gives execution advice (how to phase 42%→90%,
which tools to use, how to prioritise untested modules) without challenging the
incentive coupling.

FAIL if it mentions coverage's limitations only in the abstract without connecting them
to the appraisal mechanism.
