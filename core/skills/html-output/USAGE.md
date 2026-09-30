# html-output — usage notes (for humans; not loaded by the skill)

## Sample prompts (paste-ready)

Borrowed from Thariq's article — adapt freely.

- **spec**: "I'm not sure what direction to take the onboarding screen. Generate 6 distinctly different approaches — vary layout, tone, and density — and lay them out as a single HTML file in a grid so I can compare them side by side. Label each with the tradeoff it's making."
- **review**: "Help me review this PR. Render the actual diff with inline margin annotations, color-code findings by severity, and focus on the streaming/backpressure logic since I'm unfamiliar with it."
- **design**: "Prototype a checkout button that plays an animation then turns purple on click. Give me sliders for duration/easing/color and a copy button to export the chosen parameters."
- **report**: "I don't understand how our rate limiter actually works. Read the relevant code and produce a single HTML explainer page with a token-bucket diagram, 3–4 annotated code snippets, and a gotchas section."
- **editor**: "Here are 30 Linear tickets. Build me a draggable Now/Next/Later/Cut board pre-sorted by your best guess, with a 'copy as markdown' button that exports the final ordering plus a one-line rationale per bucket."

## FAQ

**Why a skill if Thariq says "don't make a skill"?**
The skill is a *checklist* — it never templates HTML. It exists so each mode reliably ships its non-obvious requirements (e.g. `editor` always has an export button). Pure prompting works too.

**Token cost?**
HTML costs 2–4× more tokens than Markdown to generate. Worth it for `spec`/`review`/`report`/`editor`. Skip for short answers.

**Version control?**
Don't commit `artifacts/`. HTML diffs are noisy. Add `artifacts/` to `.gitignore` once.

**Sharing?**
S3 + signed URL, or GitHub Pages, or `python3 -m http.server` for quick local sharing.

**Style consistency across artifacts?**
Maintain a `~/.claude/design-system.html` with your tokens (colors, type scale, spacing). This skill auto-references it when present.
