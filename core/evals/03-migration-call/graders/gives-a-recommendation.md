---
type: llm
focus: last_message
weight: 1
---
PASS if the answer states what the team should actually do — split, don't split, or a
named intermediate move (e.g. "extract exactly one seam first, starting with X").

FAIL if the answer surveys considerations and ends without a position
("判断材料を挙げました", "どちらもありえます", "チームで議論してください").
