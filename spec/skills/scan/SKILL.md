---
name: scan
description: "Scan a repository for agent-readiness (test automation / closed-loop verification / consistency) and emit an ROI-ranked backlog of spec intents — the front gate of the spec pipeline. Triggers: /spec:scan, scan repo, agent readiness, spec scan, repo audit"
user-invocable: true
---


You are the **scan** phase — the front gate of the spec-driven pipeline. The existing pipeline starts from a human-given `intent`; your job is to **produce those intents from the repository itself**. You assess how ready the repo is for autonomous agents and propose what to fix first. Do NOT design, write tasks, or implement anything.

This phase encodes the single lesson from Spotify's Honk: **verification is the most underinvested lever, and consistency is what lets agents perform.** You audit three pillars, gate hard on the verify loop, then rank fixes by ROI.

Target: $ARGUMENTS  （空なら `.` = カレントリポジトリ）

> Scoring basis: the portable rubric in `rubric.md` (this skill's directory) defines the
> Honk gate and the three pillars — the single, carry-anywhere source for the criteria the
> steps below apply. Adjust the criteria there, not here.

## Steps

1. **Resolve the target.** If `$ARGUMENTS` is empty, scan the current repo root. Confirm it is a git repo (`git rev-parse --show-toplevel`).
2. **Detect the verify substrate FIRST (the Honk gate).** Before anything else, find the commands an agent could invoke *itself* to close the loop. Look for, and record the actual command for each that exists:
   - test runner (e.g. `package.json` scripts, `pytest`, `go test`, `cargo test`, `Makefile` targets)
   - lint / format (`eslint`, `ruff`, `golangci-lint`, `shellcheck`, pre-commit)
   - type-check (`tsc --noEmit`, `mypy`, `go vet`)
   - build (`make`, `npm run build`, `cargo build`)
   - CI definition (`.github/workflows/*`, etc.) — does CI run the same commands a local agent could?
   - Then **apply the Honk gate as defined in `rubric.md`**: if no agent-invokable verify command exists at all, the verdict is fixed before any scoring (the rubric states the exact rule and its consequence).
3. **Score the three pillars (A / B / C), each 0–5, per the definitions in `rubric.md`.** Use `codegraph_explore` (not raw file reads) to survey structure and consistency — it is the pre-built index, far cheaper than a grep/read loop. Score against the rubric's criteria; do not redefine them here.
4. **Rank the backlog by ROI.** For each gap, estimate `impact` (how much it unblocks autonomous/agent work) and `effort`, and sort by impact/effort. The verify-loop gap, if present, dominates.
5. **Write `specs/<YYYY-MM-DD>-scan/scan.md`** in the format below. Use today's date; create the directory.
6. **Stop at the gate.** Print the scorecard, the agent-ready verdict, and the exact next command for the top intent. Do not start requirements yourself.

## scan.md format

```markdown
---
id: <YYYY-MM-DD>-scan
phase: scan
agent_ready: <yes | no>   # no if Pillar B has no agent-invokable verify loop
---

> verdict: <one line — is this repo ready for autonomous agents, and the single biggest lever>

## 検証サブストレート（エージェントが自分で叩けるコマンド）
| 種別 | コマンド | 有無 | CIと一致 |
| --- | --- | --- | --- |
| test |  |  |  |
| lint/format |  |  |  |
| type-check |  |  |  |
| build |  |  |  |
| CI |  |  |  |

## スコアカード（Honk 3本柱 / 各 0–5）
| 柱 | スコア | 根拠（codegraph / 実コマンドで観測したこと） |
| --- | --- | --- |
| A テストの自動化 |  |  |
| B 検証の仕組み(closed-loop) |  |  |
| C 標準化・一貫性 |  |  |

## ROI順 仕様バックログ
各行はそのまま `/spec:requirement "<intent>"` に流せる一言にする。
| # | intent（一言） | impact | effort | ROI | 由来した柱 |
| --- | --- | --- | --- | --- |
| 1 |  |  |  |  |  |

## エージェント自律化を阻む最大要因
<the one thing to fix first, and why it gates everything else>

## スコープ外で気づいた負債
<pre-existing issues — mention, do not fix>
```

## Rules

- **The Honk gate and the scoring criteria live in `rubric.md` — apply them, don't restate them.** That file is the single source; the gate (no agent-invokable verify loop → `agent_ready: no`, backlog #1) and the three pillars are defined there. If the criteria change, change them there.
- **Observe, don't guess.** Every score must cite something you actually ran or read via `codegraph` (a command's output, a concrete naming divergence). "Feels inconsistent" is not a finding.
- **Intents stay at intent altitude.** Each backlog row is a one-line problem statement — no file paths, no design, no tech choices. Those belong to `/spec:requirement` and downstream.
- **Scan only.** Do not fix anything, do not write requirement.md. This phase produces `scan.md` and a ranked list of intents — nothing else.

When done, end with exactly:

> Scan 完了: `specs/<id>/scan.md` をレビューしてください。`agent_ready: no` なら検証ループの整備(バックログ #1)が最優先です。着手する intent を選び、`/spec:requirement "<その intent>"` でパイプラインに流してください。
