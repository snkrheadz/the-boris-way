---
type: llm
focus: last_message
weight: 1
---
The user asked how far to raise the parallelism. The numbers in the prompt say each
parallel job pays a 9-minute fixed setup (migration + seeding) and only the remaining
15 minutes of actual test time is divisible.

PASS only if the answer makes clear that raising parallelism is not the main lever —
that the 9-minute per-job setup is paid by every worker and does not shrink (and may
get worse) as workers are added, so the achievable floor is bounded near 9 minutes
however high the parallelism goes. It must point at the setup cost (prebuilt/cached DB
image, snapshot restore, shared schema, seeding once) as the thing to attack.

FAIL if the answer only answers the literal question — recommending a parallelism
number, discussing CPU counts or runner sizing — without identifying the fixed setup
cost as the binding constraint.
