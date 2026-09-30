---
name: html-output
description: "Generate rich HTML artifacts instead of Markdown for specs, code reviews, designs, reports, and custom editors. Triggers: /core:html-output, html artifact, html spec, html report, html editor"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Write, WebFetch
model: sonnet
context: fork
---

You generate **HTML artifacts** instead of Markdown when richer expression, easier sharing, or interactivity helps the reader. Inspired by Thariq's "The Unreasonable Effectiveness of HTML" (https://thariqs.github.io/html-effectiveness/).

## Philosophy

- HTML > Markdown when: doc exceeds ~100 lines, needs diagrams/diffs/tables, will be shared across teams, or benefits from interaction (sliders, drag-drop, live preview).
- Stay in Markdown when: short answer, single code change, throwaway note, or git-tracked spec where diff readability matters.
- **Never hardcode template HTML in this skill.** Every artifact is generated fresh from context. This skill is a checklist of "required elements per mode," not a templating engine.

## Step 1: Resolve mode

If the user passed an argument, parse it as `<mode> [<topic or path>]`. Otherwise infer the mode from the request (this runs in a forked context with no user to ask) and name the choice in the report.

| mode | When to pick | Example trigger |
|---|---|---|
| `spec` | Implementation plan, side-by-side option exploration, design brief | "plan the onboarding refactor" |
| `review` | PR writeup, code explainer, reviewing someone else's code | "explain this PR" |
| `design` | UI prototype, animation tuner, component playground | "prototype the checkout button" |
| `report` | Research summary, postmortem, status report, learning doc | "explain how the rate limiter works" |
| `editor` | One-off UI to manipulate data, then export back to Claude | "let me reorder these tickets" |

## Step 2: Gather context

Mode-specific. Run gathering tools **in parallel** where independent.

- `spec`: `Read` referenced files, `Grep` for similar patterns, `git log --oneline -20` for recent direction.
- `review`: `git diff <base>...HEAD`, `git log <base>..HEAD`, read changed files end-to-end (don't rely on diff alone).
- `design`: Look for `~/.claude/design-system.html` (Thariq's recommended pattern); if present, read it. Otherwise inspect existing UI code for tokens (colors, spacing).
- `report`: `git log --since="<period>"`, read referenced source files; `WebFetch` only if the user named an external URL.
- `editor`: Read the input data (JSON/YAML/CSV) the user wants to manipulate.

If a `design-system.html` was found, the artifact MUST inherit its visual style.

## Step 3: Required elements per mode

The artifact must contain every element listed for its mode.

### mode: `spec`
- [ ] Header: goal, constraints, non-goals
- [ ] If ≥2 options: side-by-side cards or table; each labels its tradeoff
- [ ] Mockup or flow diagram (use **inline SVG**, never ASCII)
- [ ] Implementation checklist
- [ ] ≥1 annotated code snippet with `<pre><code>` and a one-line "why this matters"
- [ ] Anti-patterns: no walls of text >40 lines, no ASCII art, no unicode-color hacks

### mode: `review`
- [ ] PR summary (1 paragraph, no bullets at the top)
- [ ] Rendered diff with margin annotations (use `<aside>` or two-column flex)
- [ ] Findings color-coded by severity (e.g. green/yellow/red dot before each)
- [ ] Flowchart of the changed code path (SVG)
- [ ] Open questions section if anything was unclear from the diff
- [ ] Anti-patterns: don't restate the diff verbatim, don't grade the author

### mode: `design`
- [ ] Live working preview (HTML+CSS+JS, no build step)
- [ ] Knobs: `<input type="range">`, color pickers, dropdowns wired to live preview
- [ ] **Copy-as-code button** that emits the chosen parameters as a snippet (CSS/JSX/whatever the user is targeting)
- [ ] Multiple variants if exploring (grid layout)
- [ ] Anti-patterns: external font/UI libraries unless user opted in; locked-in design without knobs

### mode: `report`
- [ ] TL;DR box at the top (3 sentences max)
- [ ] Section nav (sticky sidebar or top tabs) if >3 sections
- [ ] SVG diagrams for any flow/architecture explanation
- [ ] Cited code snippets with file:line attribution
- [ ] "Gotchas" section at the bottom
- [ ] Anti-patterns: no executive-summary clichés ("In today's fast-paced world…")

### mode: `editor`
- [ ] Pre-populated with the input data the user supplied
- [ ] Direct manipulation (drag-drop, inline edit, toggle, etc.) — not just a form unless the data is tabular
- [ ] **Validation/warnings** for invalid states (e.g. dependency violations)
- [ ] **Export button** is mandatory: "Copy as JSON", "Copy as Markdown", or "Copy as Prompt" — whichever round-trips back into Claude Code best
- [ ] Anti-patterns: missing export button, persisting state to backend, requiring login

## Step 4: Generate the file

- **Output directory**: resolve via `ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"` then write to `$ROOT/artifacts/`. Never use a bare `./artifacts/` — CWD-dependent paths land outside the project when invoked from `~`.
- **Filename**: `<YYYY-MM-DD>-<kebab-slug>.html` where `<kebab-slug>` is the topic lowercased, non-alphanumerics replaced with `-`, collapsed runs of `-`, trimmed to ≤50 chars. Append `-2`, `-3`, … on collision.
- Single self-contained HTML file. Inline `<style>` and `<script>`. CDN allowed only if absolutely required (e.g. `https://cdn.jsdelivr.net/npm/chart.js@4.4.1`); pin a specific version, never `@latest`.
- Include `<meta name="viewport" content="width=device-width, initial-scale=1">` for responsive layout.
- Include a `@media (prefers-color-scheme: dark)` block for dark-mode parity.
- For `editor` mode, the export button writes to the clipboard via `navigator.clipboard.writeText`.

## Step 5: Verify and report

Run these checks in parallel; abort and regenerate if any required check fails:

- `wc -c <file>` — flag if >500KB (likely bloated)
- `grep -oE 'https?://[^"'\'']+' <file> | sort -u` — list every external URL so the user can audit
- **Required**: `grep -q 'name="viewport"' <file>` — viewport meta present
- **Required**: `grep -q 'prefers-color-scheme' <file>` — dark-mode block present
- **Required for `editor` mode**: `grep -q 'navigator.clipboard' <file>` — export button wired up
- Print: `open <file>` so the user can launch it on macOS

Then output a short report:

```
## HTML artifact generated

**File**: ./artifacts/<file>.html (<size>)
**Mode**: <mode>
**External URLs**: <count> (listed above)
**Open**: `open ./artifacts/<file>.html`

### Next
- Tweak: re-run with adjustments in your prompt
- Share: upload to S3 / GitHub Pages for a link
- Iterate: derive a `<other-mode>` artifact from the same context
```
