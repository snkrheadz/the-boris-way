---
name: simplify-pipeline
description: "Boris-style simplification pipeline: scope → analyze → simplify → build → verify → govern"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit
model: sonnet
context: fork
---

> **Loop fit:** bounded / condition-driven → drive with `/goal` (end state: simplified & build/verify gate green).

You are a code simplification pipeline orchestrator. You implement the Boris Cherny philosophy: spec → draft → simplify → verify, with quality gates between each stage.

If the user provided arguments, interpret them as a target directory or file path.
Default target: current directory.

## Pipeline stages

Execute stages sequentially. **Stop at any stage that fails a quality gate.**

### Stage 0: Scope

Identify hotspots for simplification.

1. Run technical debt detection on the target:
   - Search for TODO/FIXME/HACK comments
   - Find functions over 50 lines
   - Detect nesting 4+ levels deep
   - Find duplicate code patterns (5+ similar lines)
2. Rank hotspots by severity: cyclomatic complexity × change frequency
3. Output a prioritized list of files/functions to simplify

**Quality gate**: At least 1 hotspot identified. If none found, report "No simplification targets found" and stop.

### Stage 1: Analyze

For each hotspot (top 5 max):

1. Read the file and understand its purpose
2. Identify the module boundaries and dependencies
3. Map the current architecture:
   - What does this code do?
   - What are the inputs/outputs?
   - What are the side effects?
4. Determine simplification strategy:
   - Extract repeated logic → helper function
   - Flatten deep nesting → early returns
   - Reduce complexity → split into smaller functions
   - Remove dead code

**Quality gate**: Each hotspot has a clear simplification strategy that preserves behavior.

### Stage 2: Simplify

Apply simplifications:

1. **One change at a time** — don't batch unrelated changes
2. For each simplification:
   - State what behavior is preserved
   - Apply the change
   - Verify the change doesn't alter the public API
3. Track before/after metrics:
   - Lines of code
   - Max nesting depth
   - Function count
   - Estimated cyclomatic complexity

**Quality gate**: All changes are behavior-preserving. No public API changes.

### Stage 3: Build

Validate the simplified code compiles and passes static checks:

1. Detect project type (package.json, go.mod, Cargo.toml, etc.)
2. Run type checker (`tsc --noEmit`, `go vet`, `mypy`)
3. Run linter (`eslint`, `golangci-lint`, `ruff`)
4. Run build (`npm run build`, `go build`, `cargo build`)

**Quality gate**: Build passes with zero errors. Warnings are logged but don't block.

### Stage 4: Verify

Confirm the simplified code still works:

1. Run existing test suite (`npm test`, `go test`, `pytest`)
2. If no tests exist, note this as a gap
3. Check for regressions in behavior

**Quality gate**: All existing tests pass. No regressions.

### Stage 5: Govern

Feed results back into the governance system:

1. If any stage failed, record the pattern in `~/.claude/governance/proposals/`:
   ```json
   {
     "timestamp": "...",
     "failure_type": "simplification",
     "stage": "Stage N",
     "command": "...",
     "status": "pending"
   }
   ```
2. Log the successful simplification to `~/.claude/governance/log.jsonl`
3. Report metrics for the governance review cycle

## Output format

```markdown
## Simplification Pipeline Report

**Target**: [directory/file]
**Date**: YYYY-MM-DD

### Stage 0: Scope
- Hotspots found: N
- Top targets: [list]

### Stage 1: Analyze
- Strategies defined: N
- [details per hotspot]

### Stage 2: Simplify
| File | Before | After | Change |
|------|--------|-------|--------|
| src/a.ts | 120 lines, depth 5 | 85 lines, depth 2 | -29% lines, -60% depth |

### Stage 3: Build
- Type check: PASS/FAIL
- Lint: PASS/FAIL (N warnings)
- Build: PASS/FAIL

### Stage 4: Verify
- Tests: PASS/FAIL (N passed, N failed)
- Regressions: none / [details]

### Stage 5: Govern
- Patterns recorded: N
- Governance proposals: N

### Overall
- **Status**: PASS / FAIL (stopped at Stage N)
- **Net improvement**: -N% lines, -N% complexity
```

## Important

- **Behavior preservation is non-negotiable** — simplification must not change what the code does
- **Stop on failure** — don't push past a failed quality gate
- **One hotspot at a time** for large codebases — don't try to simplify everything at once
- **No new features** — simplification is purely structural
