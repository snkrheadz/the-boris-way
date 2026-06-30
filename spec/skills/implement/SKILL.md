---
name: implement
description: "Implement a spec's tasks while keeping running implementation notes (decisions, tradeoffs, deltas from the spec). Triggers: /spec:implement, implement spec, implement tasks, implement with notes"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
model: opus
---


Implement $ARGUMENTS. As you work maintain a running implementation-notes.html file that captures anything I should know about how the implementation diverges from or interprets the spec, including:

- Design decisions: choices you made where the spec was ambiguous
- Deviations: places where you intentionally departed from the spec, and why
- Tradeoffs:  alternatives you considered and why you picked what you did
- Open questions: anything you'd want me to confirm or revise
