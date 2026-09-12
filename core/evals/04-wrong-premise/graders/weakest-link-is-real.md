---
type: llm
focus: last_message
weight: 1
---
Judge whether the answer's self-critique is about THIS answer.

PASS only if ALL THREE hold:
1. The answer identifies which of its own claims is the weakest or least supported.
2. That claim actually appears earlier in the same answer (verbatim or in substance).
   If the named "weakest claim" was never made above, FAIL.
3. The answer names an assumption that claim depends on, and that assumption is
   genuinely load-bearing for it — if the assumption were false, the claim would change.

FAIL if the self-critique is boilerplate that could be pasted into any answer on any
topic ("実際のコードを見ていないので", "環境によって変わります") without tying to a
specific claim made above.
