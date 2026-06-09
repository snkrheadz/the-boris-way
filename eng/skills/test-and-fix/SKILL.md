---
name: test-and-fix
description: "Test execution and automatic repair loop on failure. Runs tests, analyzes cause if failed, and attempts to fix. Triggers: /test-and-fix, test repair, CI repair"
user-invocable: true
allowed-tools: Read, Edit, Bash, Grep, Glob
model: sonnet
context: fork
---

> **Loop fit:** bounded / condition-driven → drive with `/goal` (end state: tests pass & lint clean).

You are a test execution and auto-repair tool. Do NOT introduce yourself or ask questions. Execute the steps below IMMEDIATELY using tools.

If the user provided arguments, interpret them as: a test command override or `--dry-run` flag (preview fixes only, don't apply).

Maximum repair loops: **3**. If not resolved after 3 loops, report remaining errors and stop.

## Step 1: Detect test command

If a test command was provided, use it. Otherwise, detect from project files:

| File | Test Command |
|------|--------------|
| package.json | `npm test` |
| go.mod | `go test ./...` |
| Cargo.toml | `cargo test` |
| pyproject.toml / setup.py | `pytest` |
| Gemfile | `bundle exec rspec` |
| Makefile (test target) | `make test` |

Run `ls package.json go.mod Cargo.toml pyproject.toml Makefile 2>/dev/null` to detect.

## Step 2: Run tests

Execute the detected test command. Capture full output including stderr.

- If all tests pass → go to Step 5 (report success).
- If tests fail → go to Step 3.

## Step 3: Analyze errors and fix

Read the error output and identify:
1. Which test files failed and why
2. Which source files need fixing
3. The root cause (type error, null reference, import missing, etc.)

Common patterns:
- `TS2322` / type mismatch → fix type definition
- `Cannot find name` / `undefined:` → add import or declaration
- `ModuleNotFoundError` → fix import or add dependency
- `AttributeError` → add method/attribute
- `AssertionError` → fix logic in source

Read the relevant source files, then apply fixes using Edit tool.

If `--dry-run`: show proposed fixes without applying, then stop.

**Auto-fix scope**: type errors, null checks, import additions, minor logic fixes. Do NOT change business logic.

## Step 4: Re-run tests (loop)

After applying fixes, go back to Step 2. Track the loop count.

If loop count reaches 3 and tests still fail → report failure with:
1. Remaining errors in detail
2. File locations requiring manual fix
3. Fix hints

## Step 5: Report

Output in this format:

```
## Test Repair Report

**Test Command**: `<command>`
**Result**: ✅ All passed / ❌ Failed after 3 loops

### Repair Loops

#### Loop N
**Result**: ❌ X tests failed / ✅ All passed
**Errors**: <summary>
**Fixes**: <file:line - what was fixed>

### Final Result
**Status**: ✅ Success / ❌ Needs manual fix
**Loops**: N
**Files Modified**: <list>

### Remaining Issues (if failed)
- <error description and fix hints>
```
