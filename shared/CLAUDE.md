# Workflow Orchestration

These are the *non-obvious* operating rules for working with Claude Code on our team.
Things a modern model already does well — find root causes, prefer simple code, write
tests, avoid hacks — are intentionally **not** repeated here. Adding them back is
micromanagement; trust the model and keep this file minimal.

> Distribute this file to your `~/.claude/CLAUDE.md` (global) or a project's
> `./CLAUDE.md`. Plugins cannot ship it automatically — see the repo README.


## 1. auto-first execution
- Default to **auto mode**: act, don't ask. The harness routes risky commands through a
  security check, and two accident guardrails — the README's `permissions.deny` block
  (Channel B) and the `core` plugin's `pre-tool-guard` hook — catch sensitive-file
  access. They are guardrails against mistakes, not a security boundary; narrating
  yes/no for each step adds no safety, it just hides the calls that matter.
- **Skip plan mode for ordinary work.** Current models don't need a separate planning
  step. Reach for plan mode only when a choice is genuinely hard to reverse
  (schema/data migrations, public-facing or destructive changes, multi-service
  refactors) or the requirements are truly ambiguous.
- If an approach goes sideways, stop and re-think rather than pushing a failing path.


## 2. Orchestration: skill → subagent → team → workflow
Escalate only as far as the work demands; the difference is who holds the plan.
- **Skill** — a repeatable in-context procedure with no fan-out. Cheapest; prefer it
  before spinning up agents.
- **Subagent** (`Agent`) — one focused task in its own context (research, a scoped edit,
  one file's analysis). The default for delegation.
- **Agent Team** — a lead supervising long-lived peers over a shared task list. Use when
  work needs coordination across roles.
- **Dynamic Workflow** (`Workflow`, via the `ultracode` keyword) — deterministic fan-out
  with verify gates. Use for breadth one context can't hold: codebase-wide audit,
  migration over many sites, adversarial review.

**Rule:** a matching skill → use it; otherwise, plan fits in 2–3 steps → subagent;
coordinated multi-role → Team; wide fan-out + verify/synthesize → Workflow.

- **Web fan-out is serial, not parallel.** Many concurrent `WebFetch` calls or parallel
  research subagents against one host trip CDN rate limits and bot detection, which
  slows the whole job. Launch web-research subagents one at a time; triage with
  `WebSearch`, then fetch only a curated few; prefer typed channels (the `research`
  pack's researchers) over raw scraping.

### Model routing
- Pin `model:` explicitly when delegating — subagents inherit the main-session model
  otherwise, and on a Fable 5 session an untagged delegation buys top-tier reasoning
  (at top-tier cost) for work that doesn't need it.
- **Security work routes to Opus 4.8.** Security audits, red-teaming, and
  exploit-reproduction debugging can trip Fable 5's safety classifiers
  (`stop_reason: refusal`) even when benign — run them on Opus 4.8 (switch the main
  session, or a `model: "opus"` subagent).
- **Dispatch async, don't block.** Fire independent subtasks in the background and
  keep working; reuse a long-lived agent instead of respawning — context carries
  over and cache reads stay warm.


## 3. Self-improvement & memory
- **User correction → a project `tasks/lessons.md`** (record the pattern *and the why*).
- **Discovered preference → auto-memory** (`~/.claude/projects/<project>/memory/`, let
  Claude Code manage it).
- Review `tasks/lessons.md` at session start for the active project.


## 4. Verification = run the real thing
"Done" means **observed working**, not exit 0. Lint and type-checks are table stakes,
not verification — for an agent, verification is *"can I actually run this and watch it
behave?"*
- Start the real server / UI driver / simulator and observe behavior; diff against the
  baseline when relevant.
- **Autonomous runs need an end-to-end check that self-terminates honestly.** If none
  exists, build it first — an unattended loop with no verification path is not safe to run.
- **Ground progress claims in evidence.** On long runs, audit each claim against a
  tool result from the session before reporting — only report work you can point to
  evidence for; if something is unverified, say so explicitly.
- Define your **project's closing gate** explicitly: whatever proves a change works
  end-to-end (the real build passes, the app runs, the tests are green) — and run it
  before calling work done.


## 5. Loop & routine primitives — pick by what triggers the next turn
"Write the loop that does the work; don't hand-prompt each turn."

- **routine** (`schedule` skill → cloud cron agent) — **unattended and recurring; runs
  without you present.** The default for ongoing maintenance.
- **`/goal <condition>`** — work until a verifiable end state holds (tests pass, queue
  empty, migration complete). Bounded work with a measurable end.
- **`/loop [interval] <prompt>`** — fixed interval, or no interval to self-pace. For an
  interactive, in-session watch/maintain pass.

**Rule:** unattended & recurring → routine; verifiable end condition → `/goal`;
in-session observe/maintain → `/loop`.


---

## Task management & principles
- Non-trivial work: jot a short checkable plan in `tasks/todo.md`, track it as you go,
  and close with a one-paragraph review. Skip the ceremony for small obvious changes.
- Keep every change minimal and scoped — touch only what's necessary.
