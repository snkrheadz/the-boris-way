---
description: "Data flow tracing. Visualize UI → compute → render chain before fixing bugs. Triggers: trace, dataflow, flow, debug flow"
---

# Data Flow Trace

Before fixing this bug, trace the data flow end-to-end. Show me where each value is used (or should be used) in each step:

1. **UI/Input**: Where is the filter/input selected?
2. **State**: How is it stored in state?
3. **Query/Params**: How is it passed to the query/computation?
4. **Compute**: Where is the calculation performed?
5. **Render**: How is the result displayed?

For each step, show:
- The file and line number
- The actual value at that point
- Whether the value is correctly passed to the next step

## Output Format

```
[Step] → [File:Line] → [Value/Expression]
   ↓ (passed via: props/state/params/etc.)
[Next Step] → ...
```

## Don't

- Don't start fixing until the full chain is traced
- Don't patch symptoms - find the root cause
- Don't assume - verify each step with actual code
