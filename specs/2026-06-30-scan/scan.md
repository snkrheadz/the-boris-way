---
id: 2026-06-30-scan
phase: scan
agent_ready: yes
---

> verdict: the-boris-way は boris のやり方を「おおむね遵守」している — 最も希少なピラー（エージェントが自分で閉じられる検証ループ `validate.sh`）を実際に持ち、description=自律トリガ面の規律も効いている。最大の伸びしろは「検証ゲートが PR で強制されていない（CI なし）」ことと「最新の spec パックが repo 自身の frontmatter 規約に違反している」自己流ドリフト。

## 検証サブストレート（エージェントが自分で叩けるコマンド）
| 種別 | コマンド | 有無 | CIと一致 |
| --- | --- | --- | --- |
| test | `bash scripts/validate.sh`（JSON妥当性・version一致・skill frontmatter）→ 実行し exit 0 を観測 | ✅ | ⚠️ CI不在のため「一致」以前に強制されていない |
| lint/format | `shellcheck scripts/validate.sh core/hooks/pre-tool-guard.sh` → CLEAN | ✅（ただしゲート外・手動） | ❌ |
| type-check | 該当なし（実体はMarkdown/JSONのプロンプト資産） | — | — |
| build | `claude plugin validate .`（validate.sh内で実行・green） | ✅ | ⚠️ 同上 |
| CI | `.github/` 不在 | ❌ | ❌ |

## スコアカード（Honk 3本柱 / 各 0–5）
| 柱 | スコア | 根拠（codegraph / 実コマンドで観測したこと） |
| --- | --- | --- |
| A テストの自動化 | 3 | `validate.sh` が JSON妥当性・plugin.json↔marketplace.json の version一致・`name==dir`・`Triggers:` の有無・model pin(warn) を機械検査し、最後に権威ある `claude plugin validate .` を回す。クリーンチェックアウトから `jq` のみで走る。**穴**: 相互参照整合性（`For X use Y instead` が実在skillを指すか）はゲート未検査で、今日通っているのは作者の規律のみ（手動検証では整合）。`shellcheck` もゲート外。README↔カタログのドリフトも未検査。 |
| B 検証の仕組み(closed-loop) | 4 | エージェントが端から端まで無人で回せる自己終了型ループが**実在**（validate.sh ヘッダが「autonomous loop が done を宣言する前のhonestなチェック」と明記、exit code で正直に終了）。Honk ゲートはPASS。**減点**: CI不在ゆえ PR で強制されず、「ローカルで叩ける」=「マージ前に必ず走る」になっていない。単一保守者運用でリスクは低いが、ローカル↔強制の隙間が残る。 |
| C 標準化・一貫性 | 3 | 全 skill dir が `name/description/Triggers:` を持ち validate が強制、相互参照29件は外部1件(`/claude-md-management:*`)を除き全て実在へ解決。**具体的逸脱**: ①**spec パック6 skill の frontmatter が repo 規約違反** — `name/description/user-invocable` のみで `allowed-tools` も `model:` も無い。他全パックは両方を持ち、root CLAUDE.md は「Pin `model:` explicitly」と明記。validate.sh も6件全てに WARN。最新追加パックでの自己流ドリフト。②`context: fork` の適用が不揃い（first-principles/html-output/db-query/refactor-swarm/techdebt/test-and-fix には有り、同系の deep-thinking/honest-reasoning/life-decision には無し、基準が未文書化で新規作成時に当て推量が必要）。③model pin の WARN 計9件（teach-session/create-pr/prune-redundant-skills は main-session 意図と推測できるが未明示、spec6件は未完）。 |

## ROI順 仕様バックログ
各行はそのまま `/spec-requirement "<intent>"` に流せる一言にする。
| # | intent（一言） | impact | effort | ROI | 由来した柱 |
| --- | --- | --- | --- | --- |
| 1 | 最新パックの skill メタデータを既存パックと同じ水準に揃え、リポジトリが自分の規約を全パックで満たす状態にする | High | Low | 最高 | C |
| 2 | マージ前に検証ゲートを必ず通す仕組みを用意し、ローカルでしか走らない状態を解消する | High | Low–Med | 高 | B |
| 3 | スキル間の相互参照が実在するスキルを指しているかを検証ゲートで自動保証する | Med | Low | 高 | A |
| 4 | シェルスクリプトの静的解析を検証ゲートに組み込み、手動実行依存をなくす | Med | Low | 中 | A |
| 5 | スキル実行コンテキストの分離方針を明文化し、既存スキルの設定を基準に揃える | Med | Med | 中 | C |
| 6 | カタログと人手管理のドキュメント（パック別スキル一覧）の乖離を自動検出する | Low–Med | Med | 中 | A |

## エージェント自律化を阻む最大要因
自律化を「阻む」決定的要因は無い — Honk ゲートはすでにPASSしており、これがこのリポジトリが boris のやり方を遵守していると言える最大の根拠。残る最大の**レバー**は、検証ゲートが (a) PR で強制されておらず（CI不在）、かつ (b) 機械検査の網に穴がある（相互参照整合性・shellcheck・README ドリフトがゲート外）こと。この2つが重なると、エージェントは「ゲートを通したのにゲートが見ていないドリフトを持ち込む」状態になり得る。現にそれが起きた具体例が backlog #1（spec パックが規約違反のままゲートを通過＝マージ済み）。よって最優先は #1 で自己流ドリフトを刈り取り、続けて #2–#4 でゲート自体を「強制 × 網羅」に引き上げる順が最もROIが高い。

## スコープ外で気づいた負債
- spec パイプラインは自己適用（dogfooding）されている（`specs/2026-06-30-spec-pack-promotion/` に intent→requirement→design→tasks→review が揃う）が、`/spec:scan` の出力（scan.md）だけは今回が初めて＝scan フェーズは未dogfood だった。
- root CLAUDE.md は Boris レンズで良くチューンされている（maintainer's map / context-not-rules）。指摘ではなく良い兆候として記録。
- `validate.sh` の model-pin チェックは warn 止まりで「意図的な main-session skill」と「未完で pin 忘れ」を区別できない。frontmatter に意図フラグを持たせれば warn のS/N比が上がる（将来の改善余地、今は修正しない）。

> Scan 完了: `specs/2026-06-30-scan/scan.md` をレビューしてください。`agent_ready: yes` なので検証ループ自体は整備済みです。ROI最上位は backlog #1（最新パックの規約違反ドリフト刈り取り）。着手する intent を選び、`/spec-requirement "<その intent>"` でパイプラインに流してください。
