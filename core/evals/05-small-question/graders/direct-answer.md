---
type: llm
focus: last_message
weight: 1
---
This is a small, low-stakes question with a well-known answer.

PASS if the answer states which to use and the deciding reason (mutability / fixed-size
heterogeneous record / hashability as a dict key) within roughly the first few sentences,
before any sectioned analysis.

FAIL if the reader has to get past framing, scope-setting, or a section of caveats
before learning which one to use.
