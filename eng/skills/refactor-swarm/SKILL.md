---
name: refactor-swarm
description: "Parallel refactoring with Agent Teams. Partition by module, avoid conflicts. Triggers: /eng:refactor-swarm, parallel refactor, refactor swarm, refactor by module, multi-agent refactor"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit
model: sonnet
context: fork
---

> **Loop fit:** bounded / condition-driven → drive with `/goal` (end state: all modules refactored & integration verified).

You are a refactoring swarm orchestrator. You partition a codebase into independent modules and run parallel refactoring agents, then integrate and verify the results.

If the user provided arguments, interpret them as a target directory.
Default target: `src/` if it exists, otherwise current directory.

## Workflow

### Step 1: Partition (sequential — single agent)

1. **Scan the target directory** for module boundaries:
   - Top-level directories under the target
   - Package/module boundaries (package.json, go.mod, __init__.py)
   - Logical groupings (by feature, by layer)

2. **Identify shared code**:
   - Types/interfaces (`src/types/`, `src/interfaces/`)
   - Configuration files
   - Shared utilities
   - These are **read-only** for parallel agents

3. **Create partition plan**:
   ```
   Shared (read-only): src/types/, src/config/, src/utils/
   Module A: src/auth/       → Agent 1
   Module B: src/users/      → Agent 2
   Module C: src/orders/     → Agent 3
   ```

4. **Max 3 parallel agents** — if more modules exist, batch them

### Step 2: Shared refactoring (sequential — single agent)

Before parallel work, handle shared code that multiple modules depend on:

1. Refactor types/interfaces if needed
2. Update shared utilities
3. Ensure all changes are committed before parallel step
4. This establishes the "contract" that parallel agents must respect

### Step 3: Parallel module refactoring

Launch parallel agents using Agent Teams, each in its own worktree:

For each module agent, include these constraints in the task description:

```
CONSTRAINTS:
- You may ONLY modify files under: [module path]
- These paths are READ-ONLY: [shared paths]
- Do NOT modify any configuration files
- Do NOT change public interfaces/exports
- Run the simplification pipeline on your module:
  1. Identify hotspots (deep nesting, duplicates, long functions)
  2. Apply simplifications (early returns, extract helpers, remove dead code)
  3. Verify build passes
  4. Verify existing tests pass
- Report: files changed, before/after metrics, any issues found
```

### Step 4: Integration verification (sequential)

After all parallel agents complete:

1. **Merge check**: Verify no file was modified by multiple agents
2. **Build validation**: Run full project build
3. **Test suite**: Run complete test suite
4. **Conflict resolution**: If conflicts exist, resolve them sequentially

### Step 5: Governance feedback

1. Record the refactoring session in `~/.claude/governance/log.jsonl`:
   ```json
   {
     "timestamp": "...",
     "type": "refactor-swarm",
     "modules": ["auth", "users", "orders"],
     "agents": 3,
     "files_changed": N,
     "lines_reduced": N,
     "tests_passed": true
   }
   ```
2. If any module agent failed, create a governance proposal
3. If patterns emerged across modules, suggest a new CLAUDE.md rule

## Output format

```markdown
## Refactor Swarm Report

**Target**: [directory]
**Date**: YYYY-MM-DD
**Agents**: N

### Partition Plan

| Module | Path | Agent | Status |
|--------|------|-------|--------|
| Auth | src/auth/ | Agent 1 | Completed |
| Users | src/users/ | Agent 2 | Completed |
| Orders | src/orders/ | Agent 3 | Failed (Stage 3) |

**Shared (read-only)**: src/types/, src/config/

### Per-Module Results

#### Module: Auth (Agent 1)
- Files changed: N
- Lines: 450 → 320 (-29%)
- Max nesting: 5 → 2
- Tests: 12/12 passed

#### Module: Users (Agent 2)
- Files changed: N
- Lines: 380 → 290 (-24%)
- Max nesting: 4 → 2
- Tests: 8/8 passed

### Integration
- Merge conflicts: 0
- Full build: PASS
- Full test suite: 28/30 passed (2 pre-existing failures)

### Governance
- Proposals generated: 1
- Cross-module patterns: [description]

### Overall
- **Total files changed**: N
- **Total lines reduced**: N (-N%)
- **Total complexity reduction**: -N%
```

## Safety rules

- **Max 3 parallel agents** to control token usage
- **File ownership is exclusive** — no two agents touch the same file
- **Shared code is read-only** during parallel phase
- **Stop on integration failure** — don't push broken code
- **Human review before merge** — present the report, don't auto-merge
