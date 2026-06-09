---
name: project-setup
description: "Set up Claude Code configuration for projects. Detects structure and generates .claude/settings.local.json and hooks. Triggers: /project-setup, project configuration, formatter setup, project configuration, setup formatter"
user-invocable: true
allowed-tools: Read, Bash, Glob, Grep, Write
model: sonnet
context: fork
---

# Project Setup Skill

Detects project structure and generates appropriate Claude Code configuration.

## Required Execution Steps

**When this skill is invoked, execute the following steps in order.**

### Step 1: Detect Project Type

```bash
# [Bash] Execute the following to determine project type
ls -la package.json go.mod Cargo.toml pyproject.toml 2>/dev/null
```

Determine project type based on detection results:

| Detected File | Project Type | Formatter |
|---------------|--------------|-----------|
| `package.json` | Node.js | prettier |
| `go.mod` | Go | gofmt |
| `Cargo.toml` | Rust | rustfmt |
| `pyproject.toml` | Python | ruff |

### Step 1.5: Agent Selection (Optional)

Ask the user if they want to configure project-specific agents.
If yes, ask what type of project:

| Preset | Agents |
|--------|--------|
| dev | build-validator, code-architect, code-simplifier, verify-app, verify-shell |
| aws | aws-best-practices-advisor, build-validator, state-machine-diagram |
| gcp | gcp-best-practices-advisor, build-validator, state-machine-diagram |
| research | arxiv-ai-researcher, strategic-research-analyst, huggingface-spaces-researcher, gemini-api-researcher |
| minimal | (none) |
| custom | (let user pick from catalog) |

Execute:
```bash
# [Bash] Apply agent preset
claude-agents preset <selected>
```

### Step 2: Create Directory

```bash
# [Bash] Create .claude/hooks directory
mkdir -p .claude/hooks
```

### Step 3: Generate settings.local.json

```bash
# [Write] Create .claude/settings.local.json
```

### Step 4: Generate format-code.sh

```bash
# [Write] Create .claude/hooks/format-code.sh (content based on project type)
```

### Step 5: Grant Execute Permission

```bash
# [Bash] Grant execute permission
chmod +x .claude/hooks/format-code.sh
```

### Step 6: Report Results

After setup completes, report results to user.

---

## Generated File Contents

#### `.claude/settings.local.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

#### `.claude/hooks/format-code.sh`

Generate format script based on project type.

**Node.js (prettier) example:**

```bash
#!/bin/bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

case "$file_path" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.md|*.css|*.scss|*.html)
        # Use local prettier (faster than npx)
        if [[ -f "node_modules/.bin/prettier" ]]; then
            node_modules/.bin/prettier --write "$file_path" 2>/dev/null || true
        fi
        ;;
esac
exit 0
```

**Go (gofmt) example:**

```bash
#!/bin/bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

case "$file_path" in
    *.go)
        gofmt -w "$file_path" 2>/dev/null || true
        ;;
esac
exit 0
```

### 3. Output Format

After setup completes, report in the following format:

```markdown
## Project Setup Complete

### Detection Results
- **Type**: Node.js (TypeScript)
- **Formatter**: prettier
- **Execution Method**: node_modules/.bin/prettier (local)

### Generated Files
- `.claude/settings.local.json` - Hook configuration
- `.claude/hooks/format-code.sh` - Format script

### .gitignore Recommendation
Recommend adding the following to `.gitignore`:
```
.claude/settings.local.json
```

### Verification
When you edit a file, the formatter will run automatically.
```

## Notes

- `settings.local.json` is project-specific, so recommend adding to `.gitignore`
- If formatter is not installed locally, guide to run `npm install` etc.
- If multiple project types detected, select appropriate one

## Formatter Extension Mapping

| Formatter | Target Extensions |
|-----------|-------------------|
| prettier | `.ts`, `.tsx`, `.js`, `.jsx`, `.json`, `.md`, `.css`, `.scss`, `.html` |
| gofmt | `.go` |
| rustfmt | `.rs` |
| ruff | `.py` |
