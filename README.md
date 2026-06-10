# claude-skills

A Claude Code skill marketplace maintained by snkrheadz.
**Goal: a new teammate (engineer / PM) can use Claude Code in the same environment
from day one.**

We intentionally keep this lean. Anything the **official Claude Code commands already
cover** (code review, simplification, app verification, committing, project init) is *not*
duplicated here — see [Covered by official Claude Code](#covered-by-official-claude-code).
This repo only ships the gaps.

---

## Big picture: distribution has two channels

A plugin alone is not enough. By design, Claude Code cannot distribute
`permissions.deny` (the security deny-list) or the global `CLAUDE.md` (your working
philosophy) through a plugin, so those go through a separate channel.

| Channel | What | How |
|---|---|---|
| **A. Plugins** | skills / agents / hooks | `/plugin marketplace add` → `/plugin install` |
| **B. Settings + philosophy** | permission deny-list / `CLAUDE.md` | paste into `~/.claude/settings.json` + install `CLAUDE.md` |

---

## Channel A: install the plugins

### 1. Add this marketplace (everyone)

```
/plugin marketplace add snkrheadz/claude-skills
```

> Works for private repos too. A manual `add` reuses your local git auth
> (`gh auth login` / SSH / Keychain), so if you can `git clone` it, you can add it.
> Only set `GITHUB_TOKEN` (with `repo` scope) if you also want auto-update on startup.

### 2. Install Core first (everyone)

```
/plugin install core@claude-skills
```

What Core ships (role-agnostic):

- `first-principles` — rethink a problem from fundamentals
- `teach-session` — teach back the work just done (great for onboarding)
- `html-output` — emit specs / reviews / reports as rich HTML
- `pre-tool-guard` hook — block access to sensitive files (defense in depth)

### 3. Install role packs

#### PM / business

```
# Our own business assets (maintained by snkrheadz)
/plugin install pm@claude-skills          # 業務定義シート (task definition sheet) as A4 HTML

# PM lifecycle (external, MIT, recommended for non-developers)
/plugin marketplace add phuryn/pm-skills
/plugin install pm-product-discovery@pm-skills   # discovery / prioritization / interviews
/plugin install pm-product-strategy@pm-skills    # strategy / canvases / pricing
/plugin install pm-execution@pm-skills           # PRD / OKR / roadmap / sprint
/plugin install pm-market-research@pm-skills     # personas / market sizing / competitors
# Install only what you need. All 9 plugins: https://github.com/phuryn/pm-skills

# Document generation (official, docx/pptx/xlsx/pdf)
/plugin install document-skills@anthropic-agent-skills
```

#### Engineer

```
/plugin install eng@claude-skills
```

This pack deliberately **does not** re-implement review/simplify/verify/commit — those are
official commands now (see below). It ships the workflow gaps around them:

- Skills (8): `create-pr` `prune-redundant-skills` `review-inbox` `test-and-fix`
  `refactor-swarm` `techdebt` `trace-dataflow` `db-query`
- Agents (8): `code-architect` `architecture-reviewer` `verify-shell`
  `migration-assistant` `oncall-guide` `state-machine-diagram`
  `aws-best-practices-advisor` `gcp-best-practices-advisor`

Recommended alongside the official LSP plugins:

```
/plugin install gopls-lsp@claude-plugins-official        # Go
/plugin install typescript-lsp@claude-plugins-official   # TS
```

#### Research (role-agnostic, optional)

For anyone investigating AI/ML papers, APIs, and models — any role can add it.

```
/plugin install research@claude-skills
```

Agents (3): `arxiv-ai-researcher` (paper discovery & synthesis),
`gemini-api-researcher` (Gemini API capabilities & usage),
`huggingface-spaces-researcher` (HF Spaces / model discovery).

#### Marketer / Designer

These roles are served almost entirely by **official Anthropic plugins** — we no longer
ship a custom pack for them.

```
# Marketer
/plugin install document-skills@anthropic-agent-skills   # brand-guidelines, internal-comms, doc-coauthoring
# + the deep-research skill; landing pages via frontend-design@claude-plugins-official

# Designer
/plugin install frontend-design@claude-plugins-official
/plugin install document-skills@anthropic-agent-skills   # canvas-design, theme-factory, algorithmic-art, slack-gif-creator
```

---

## Covered by official Claude Code

These workflows ship with Claude Code itself, so this marketplace intentionally omits them.
Use the official commands directly:

| Need | Official command |
|---|---|
| Review the current diff / a PR | `/code-review` (`/code-review ultra [PR#]` for deep multi-agent cloud review), `/review` |
| Security review | `/security-review` |
| Simplify / de-duplicate code | `/simplify` |
| Verify a change by running the app | `/verify`, `/run` |
| Commit | Claude Code commits natively (or the `commit-commands` plugin) |
| Initialize `CLAUDE.md` / project config | `/init`, the `update-config` skill |
| Claude Code / Agent SDK / API how-to | the official `claude-code-guide` agent |

The `eng` pack's `review-inbox` builds **on top of** `/code-review` (it triages the PRs where
you are the requested reviewer and posts human-confirmed comments), rather than replacing it.

---

## Channel B: install settings and philosophy

### Non-interactive setup (paste into settings.json)

Add this to `~/.claude/settings.json` and the marketplace + plugins are picked up
automatically (instead of running `/plugin install` by hand).

```jsonc
{
  "extraKnownMarketplaces": {
    "claude-skills": {
      "source": { "source": "github", "repo": "snkrheadz/claude-skills" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "core@claude-skills": true,
    "pm@claude-skills": true
  },
  "permissions": {
    "deny": [
      "Read(~/.secrets.env)", "Read(**/.env)", "Read(**/.env.*)",
      "Read(~/.aws/credentials)", "Read(~/.ssh/id_*)",
      "Bash(curl * | bash*)", "Bash(curl * | sh*)",
      "Bash(rm -rf /)", "Bash(rm -rf ~)", "Bash(sudo *)"
    ]
  }
}
```

> `permissions.deny` can't be shipped in a plugin, so paste this block into your own
> settings.json. For org-wide enforcement, distribute it via `managed-settings.json`
> (a plist on macOS, or `/etc/claude-code/` on Linux).

### Install the philosophy (CLAUDE.md)

Copy `shared/CLAUDE.md` into your global config.

```bash
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/snkrheadz/claude-skills/main/shared/CLAUDE.md \
  -o ~/.claude/CLAUDE.md
# or clone and: cp shared/CLAUDE.md ~/.claude/CLAUDE.md
```

---

## Fastest day-one path (PM example)

1. Paste the JSON block above into `~/.claude/settings.json`
2. Put `shared/CLAUDE.md` at `~/.claude/CLAUDE.md`
3. Launch `claude` → approve the marketplace prompt when asked
4. `/plugin marketplace add phuryn/pm-skills` → install the PM plugins you need
5. Use `teach-session` to walk through your first task together

Now everyone is "same environment, immediately."

---

## Repository layout

```
claude-skills/
├── .claude-plugin/marketplace.json   # catalog (core, pm, eng, research)
├── core/                             # role-agnostic plugin
│   ├── .claude-plugin/plugin.json
│   ├── skills/                       # first-principles, teach-session, html-output
│   └── hooks/                        # pre-tool-guard.sh + hooks.json
├── pm/                               # PM role pack (our own assets)
│   ├── .claude-plugin/plugin.json
│   └── skills/task-definition-sheet/
├── eng/                              # engineering pack (skills 8 + agents 8)
├── research/                         # research pack (arxiv / gemini / huggingface)
└── shared/CLAUDE.md                  # philosophy for distribution (Channel B)
```

## Maintenance

- Add a skill → drop `skills/<name>/SKILL.md` into the right plugin, register a new
  plugin in `marketplace.json` if needed → commit & push.
- Before adding a skill, check [Covered by official Claude Code](#covered-by-official-claude-code) —
  don't duplicate a built-in command.
- Periodically run `/eng:prune-redundant-skills` — the official surface keeps growing, so it
  audits every skill against the current built-ins, removes the now-redundant ones, and fixes
  the dependent files (README counts, `plugin.json`, `marketplace.json`, cross-skill links).
- Consumers pull updates with `/plugin marketplace update claude-skills`.
- License: MIT. The external `phuryn/pm-skills` is MIT too.
