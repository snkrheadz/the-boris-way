---
id: 2026-06-30-spec-pack-promotion
phase: review
status: pass
---

> verdict: 移植は忠実・カタログは加算のみで回帰なし。初回レビューの Major 2件（rubric 二重定義 / 公理5 dangling 参照）を実装フェーズで修正し、全受け入れ条件 ✅・validate 緑を再観測したため pass。

## 受け入れ条件の充足
| 受け入れ条件 | 状態 | 根拠（実際に観測したこと） |
| --- | --- | --- |
| install で全6フェーズが選択可能（カタログ成立の前提） | ✅ | marketplace.json に spec 追加、`claude plugin validate .` ok、6 SKILL.md が frontmatter 規約（name=dir / Triggers: / user-invocable）を満たす |
| 現行と同じ成果物＋人間ゲートが再現 | ✅ | 各 SKILL 本文を laptop コマンドと diff、`/spec-x→/spec:x`・`/implement-with-notes→/spec:implement` の意図した書換のみ。ゲート停止文言一致 |
| 内部参照が解決できる（名前空間整合） | ✅ | `grep -rnE '/spec-(scan\|requirement\|design\|tasks\|review)\|/implement-with-notes' spec/` → 0ヒット |
| closing gate（validate.sh）通過 | ✅ | `all checks passed (9 warning(s))` / rc=0。WARN は model 無指定のみ（design/tasks で許容） |
| 第三者がドキュメントで辿れる | ✅ | spec/README.md にフロー図・コマンド表・3ゲート・出自記載 |
| 既存6パック回帰なし | ✅ | marketplace.json 差分は spec 加算のみ。core/pm/eng/research/strategy/writing 無変更 |
| 版整合 | ✅ | plugin.json=0.1.0、marketplace spec=0.1.0 一致 |
| 単一情報源（rubric） | ✅ | 修正後、柱定義＋Honk ゲートは rubric.md のみ。scan は参照のみ（`grep "Pillar A"` → scan 本文 0、定義の重複なし） |
| 持ち運び可能性（公理参照の自己完結） | ✅ | 公理5 に inline gloss 付与（公理2 と同じ扱い）、未定義参照なし |

## 設計との整合（eng:architecture-reviewer より）
- パック境界健全: spec は既存6パックに侵入せず、marketplace 差分は加算のみ。spec→eng（/eng:create-pr, /eng:test-and-fix）は advisory テキスト参照のみで import なし＝循環・結合なし。
- 移植忠実性: 各フェーズ本文・ゲート・altitude が laptop 版と意味的に等価（diff で確認）。
- 初回判定は **REQUEST CHANGES**（下記 Major 2件）。修正後に両方解消。

## 指摘（重大度順）
- [Blocker→解消] **rubric 二重定義**（scan/SKILL.md の Step3 柱詳述＋Rules の Honk ゲート再掲が rubric.md と重複）— design.md:34 が「分離して参照」を選び「本文内包」を却下したのに両方を出荷していた。
  - 修正: scan の柱定義・ゲート規則を rubric.md への参照に圧縮。基準は rubric.md に一元化（scan は適用のみ）。`> Scoring basis` ノートの "keep the two in sync"（重複の自認）も削除。
- [Blocker→解消] **公理5 の dangling 参照**（tasks/SKILL.md:46）— gloss 無しでパック内に定義が無く、別 repo に install すると解決不能。review は公理2 に gloss 済みだが tasks で漏れていた。
  - 修正: `(公理5: 各タスクが自分の検証を持つまで分割する)` を inline 付与。
- [Minor/非ブロッキング] README.md カタログ一覧コメントに spec と併せて writing も追記。writing は既存パックなのにコメントから漏れていた既存欠落の無害な修正。スコープ規律上は spec のみが本筋だが、ドキュメント正確性が上がるため残置。

## 検証ログ
- `bash scripts/validate.sh` → `all checks passed (9 warning(s))` / rc=0（修正後・再実行）
- `jq empty .claude-plugin/marketplace.json` / `jq empty spec/.claude-plugin/plugin.json` → 両 ok
- version: marketplace spec=0.1.0、plugin.json=0.1.0 一致
- `git diff origin/main...HEAD -- .claude-plugin/marketplace.json` → spec 加算のみ、既存6パック差分ゼロ
- frontmatter 6本検査 → name一致 / Triggers: 有 / user-invocable:true
- `grep -rnE '/spec-…|/implement-with-notes' spec/` → 0ヒット
- 修正後 `grep "Pillar A" spec/` → 定義の重複なし、`公理5` gloss 確認

## スコープ外で気づいた負債
- 実 install スモーク（`/plugin install spec@…` で実際にスキルが選択・起動でき、`$ARGUMENTS` 解決や eng スキル slug 実在を runtime 観測）は静的検証（validate.sh + plugin validate）まで。install 成立の前提（カタログ・版・frontmatter・名前空間）は全て ✅ で観測済み。
- laptop 側のローカル spec-* コマンドを本パックへ置換して単一情報源化するのは別案件（フォローアップ）。
