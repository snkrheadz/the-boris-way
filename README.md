# claude-skills

snkrheadz が運用保守する Claude Code 用スキルのマーケットプレイスです。
**新しく入った人（エンジニア / PM / マーケ / デザイナー）が、初日から同じ環境で
Claude Code を使える**ことをゴールにしています。

---

## 全体像：配布は2チャネル

プラグインだけでは設定が完結しません。Claude Code の仕様上、`permissions.deny`
（セキュリティの拒否リスト）と グローバル `CLAUDE.md`（仕事の進め方の哲学）は
**プラグインで配れない**ため、別チャネルで渡します。

| チャネル | 中身 | 配り方 |
|---|---|---|
| **A. プラグイン** | skills / agents / hooks | `/plugin marketplace add` → `/plugin install` |
| **B. 設定 + 哲学** | permission deny-list / `CLAUDE.md` | `~/.claude/settings.json` に貼付 + `CLAUDE.md` 設置 |

---

## チャネルA：プラグインを入れる

### 1. このマーケットプレイスを追加（全員）

```
/plugin marketplace add snkrheadz/claude-skills
```

> private repo でも動きます。手動 add は手元の git 認証（`gh auth login` / SSH /
> Keychain）をそのまま使うので、ターミナルで `git clone` できれば追加できます。
> 起動時の自動更新まで効かせたい場合のみ `GITHUB_TOKEN`（`repo` scope）を環境変数に。

### 2. Core を入れる（全員・最初に）

```
/plugin install core@claude-skills
```

Core に入るもの（役割非依存）：

- `first-principles` — 原理から考え直す
- `teach-session` — 今やった作業を理解できるまで教える（オンボーディング向け）
- `html-output` — 仕様/レビュー/レポートをリッチな HTML で出力
- `claude-code-guide` — Claude Code 自体の使い方ガイド
- `pre-tool-guard` フック — 機密ファイルへのアクセスをブロック（防御の多層化）

### 3. 役割パックを入れる

#### PM / ビジネス

```
# 自社の業務資産（snkrheadz 保守）
/plugin install pm@claude-skills          # 業務定義シート(A4 HTML) など

# PM ライフサイクル（外部・MIT・非開発者推奨）
/plugin marketplace add phuryn/pm-skills
/plugin install pm-product-discovery@pm-skills   # 発見・優先度付け・顧客インタビュー
/plugin install pm-product-strategy@pm-skills    # 戦略/各種キャンバス/価格
/plugin install pm-execution@pm-skills           # PRD/OKR/ロードマップ/スプリント
/plugin install pm-market-research@pm-skills     # ペルソナ/市場規模/競合
# 必要なものだけ。全9プラグインは https://github.com/phuryn/pm-skills 参照

# ドキュメント生成（公式・docx/pptx/xlsx/pdf）
/plugin install document-skills@anthropic-agent-skills
```

#### エンジニア

```
/plugin install eng@claude-skills
```

eng に入るもの：

- スキル(12): `quick-commit` `merge-pr` `pr-review` `review-changes` `review-inbox`
  `test-and-fix` `refactor-swarm` `simplify-pipeline` `techdebt` `trace-dataflow`
  `db-query` `project-setup`
- エージェント(11): `code-architect` `architecture-reviewer` `code-simplifier`
  `build-validator` `verify-app` `verify-shell` `migration-assistant` `oncall-guide`
  `state-machine-diagram` `aws-best-practices-advisor` `gcp-best-practices-advisor`

公式の開発系プラグインも併用推奨：

```
/plugin install gopls-lsp@claude-plugins-official        # Go
/plugin install typescript-lsp@claude-plugins-official   # TS
```

#### リサーチ（役割非依存・任意）

AI/ML の論文・API・モデル調査を行う人向け。役割を問わず追加できます。

```
/plugin install research@claude-skills
```

research に入るエージェント(3): `arxiv-ai-researcher`（論文の発見と要約）
`gemini-api-researcher`（Gemini API の機能と使い方）
`huggingface-spaces-researcher`（HF Spaces / モデルの探索）。
マーケターの `strategic-research-analyst`（marketer パック）と補完関係です。

#### マーケター

```
/plugin install marketer@claude-skills      # strategic-research-analyst エージェント
/plugin install document-skills@anthropic-agent-skills   # brand-guidelines, internal-comms, doc-coauthoring
```
+ `deep-research` スキル、ランディングページは `frontend-design@claude-plugins-official`。

#### デザイナー

```
/plugin install designer@claude-skills      # nano-banana-pro-prompt-generator エージェント
/plugin install frontend-design@claude-plugins-official
/plugin install document-skills@anthropic-agent-skills   # canvas-design, theme-factory, algorithmic-art, slack-gif-creator
```

> marketer / designer の中核価値は外部プラグイン（frontend-design / document-skills）側に多く、
> 自社パックは各役割の専門エージェント1つ + 上記の導線という構成です。

---

## チャネルB：設定と哲学を入れる

### 非対話セットアップ（settings.json に貼付）

`~/.claude/settings.json` に以下を足すと、マーケットプレイスとプラグインが
自動で認識されます（手で `/plugin install` する代わり）。

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

> `permissions.deny` はプラグインで配れないため、このブロックを各自の
> settings.json に貼ってください。IT が一括強制したい場合は `managed-settings.json`
> （macOS は plist / Linux は `/etc/claude-code/`）で配布できます。

### 哲学（CLAUDE.md）を置く

`shared/CLAUDE.md` を自分のグローバル設定にコピーします。

```bash
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/snkrheadz/claude-skills/main/shared/CLAUDE.md \
  -o ~/.claude/CLAUDE.md
# あるいは clone して cp shared/CLAUDE.md ~/.claude/CLAUDE.md
```

---

## 初日の最短手順（PM の例）

1. `~/.claude/settings.json` に上の JSON ブロックを貼る
2. `~/.claude/CLAUDE.md` に `shared/CLAUDE.md` を置く
3. `claude` を起動 → マーケットプレイス追加を促されたら承認
4. `/plugin marketplace add phuryn/pm-skills` → 必要な PM プラグインを install
5. `teach-session` で最初のタスクを一緒に歩く

これで「即・同じ」状態になります。

---

## このリポジトリの構成

```
claude-skills/
├── .claude-plugin/marketplace.json   # カタログ（core, pm, eng, marketer, designer, research）
├── core/                             # 役割非依存プラグイン
│   ├── .claude-plugin/plugin.json
│   ├── skills/                       # first-principles, teach-session, html-output, claude-code-guide
│   └── hooks/                        # pre-tool-guard.sh + hooks.json
├── pm/                               # PM 役割パック（自社資産）
│   ├── .claude-plugin/plugin.json
│   └── skills/task-definition-sheet/
├── eng/                              # エンジニア役割パック（skills 12 + agents 11）
├── marketer/                         # マーケター役割パック（strategic-research-analyst）
├── designer/                         # デザイナー役割パック（nano-banana-pro-prompt-generator）
├── research/                         # リサーチ（arxiv / gemini / huggingface researcher）
└── shared/CLAUDE.md                  # 配布用の哲学（チャネルB）
```

## メンテナンス

- スキルを足す → 該当プラグインの `skills/<name>/SKILL.md` を追加し、必要なら
  `marketplace.json` に新プラグインを登録 → commit & push。
- 利用者側は `/plugin marketplace update claude-skills` で取り込み。
- ライセンス: MIT。外部の `phuryn/pm-skills` も MIT。
