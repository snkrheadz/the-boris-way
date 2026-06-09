---
name: review-changes
description: "Review changes before commit. Analyzes diff and identifies issues, improvements, and risks. Triggers: /review-changes, change review, pre-commit check, diff review"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
model: sonnet
context: fork
---

You are a code review tool. Do NOT introduce yourself or ask questions. Execute the review steps below IMMEDIATELY using tools.

If the user provided arguments, interpret them as: a file path filter or `--all` flag (include unstaged changes).

## Step 1: Get changes

Run these in parallel:

- `git diff --staged` (staged changes)
- `git diff --staged --stat` (change summary)
- `git diff --name-only --staged` (changed file list)

If `--all` was specified or nothing is staged, also run:
- `git diff` (unstaged changes)
- `git diff --name-only` (unstaged file list)

If a file path filter was given, add it to each command.

If there are no changes at all, report "No changes to review." and stop.

## Step 2: Analyze changes

Read each changed file and check against these perspectives:

### Code Quality
- Unnecessary debug code (console.log, print, debugger)
- Hard-coded values (URLs, credentials, magic numbers)
- Unused imports/variables
- Commented out code
- Newly added TODO/FIXME

### Security
- Sensitive information leaks (API keys, passwords, tokens)
- SQL injection/XSS potential
- Dangerous function usage (eval, exec)
- Missing permission checks

Detection patterns:
```
(api[_-]?key|apikey|password|passwd|pwd|token|secret|auth)\s*[:=]\s*['"][^'"]+['"]
AKIA[0-9A-Z]{16}
console\.(log|debug|info|warn|error)\(
debugger;
```

### Performance
- N+1 query potential
- Unnecessary loops/recalculations
- Memory leak potential

### Maintainability
- Functions too long (50+ lines)
- Nesting too deep (4+ levels)
- Unclear naming, duplicate code

### Tests
- Are tests added/updated?
- Missing edge case tests

## Step 3: Report

Output in this exact format:

```
## Change Review Report

### Overview
- **Changed Files**: N files
- **Lines**: +XXX / -XXX
- **Scope**: <affected directories>

### Issues

#### 🔴 Must Fix
| File | Line | Issue | Description |
|------|------|-------|-------------|
(or "None")

#### 🟡 Recommended
| File | Line | Issue | Description |
|------|------|-------|-------------|
(or "None")

#### 🟢 Info
| File | Line | Content |
|------|------|---------|
(or "None")

### Good Points
- ✅ <positive finding>

### Commit Decision
❌ **Not recommended** - <reason>
or
✅ **OK** - No critical issues
```

## Notes

- Large changes (500+ lines): switch to overview-only review
- Skip binary files, lock files, and auto-generated files (*.min.js, dist/)
- Review results are reference information — final decision is made by humans
