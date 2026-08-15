# RULES.md — 規則棚卸しの索引

`consolidate-rules` Skill が読み書きする索引。規則の実体はここに書かず、対象ファイルへのポインタ・一言要約・相互参照・直近棚卸し時点の状態のみを記録する。次回実行時はここを起点に、記載の commit/日付より後に変更があったファイルだけを深読みする。

## CLAUDE.md群

- **`CLAUDE.md`**（リポ直下） — 実行者向けの動作フロー・検証コマンド・アーキテクチャの要点。禁止と強制は書かず `.claude/settings.json` の deny と `.claude/hooks/` に委ねると宣言している。相互参照: `docs-agents/harness-guide.md` §2〜§4 の層構成を実装した例であり、`pr-workflow/SKILL.md` へ実装手順を委譲。棚卸し: 8dd42e6 2026-08-15

## docs-agents（基準の実体）

判断層（リポごとに答えが変わる）と定型層（一度決めれば機械適用できる）に分かれる。英語版 `*.en.md` は日本語版の従属物であり、規則の実体ではないため索引の対象にしない。

- **`docs-agents/repo-guide.md`**（定型層） — ファイル衛生・`.gitignore` の基準・repo 面のシークレット・公開前チェックリスト。相互参照: `repo-standardize/SKILL.md` が基準として読む、`repo-publish/SKILL.md` の公開前スキャンが §3・§4 を前提にしている。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/harness-guide.md`**（定型層） — リポ類型と検証手段・`.claude/` の層構成（層1 settings.json とフック / 層2 指示ファイル）・新規リポのチェックリスト。相互参照: `repo-standardize/SKILL.md` が基準として読む、リポ直下 `CLAUDE.md` はこの層2の実装例。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/issue-driven-workflow.md`**（定型層） — フェーズ（MVP期 / Issueドリブン期）・担当分離・Issue フォーマット・シェル関数。相互参照: `new-issue/SKILL.md` が Issue フォーマットと担当分離を実装、`pr-workflow/SKILL.md` が実行者側の手順を担う、`docs-agents/test-policy.md` の保証節を Issue フォーマットに組み込んでいる。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/cicd-guide.md`**（定型層） — 2つのリポパターン・CI・デプロイ・デモ公開・Secrets・Dependabot・担当分離との接続。相互参照: `dependabot-triage/SKILL.md` の判断基準の正本は §6、`cf-private-deploy/SKILL.md` が §3・§4 の具体化、`readme-guide.md` §8 の Deploy 節が本ガイドへ委譲。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/test-policy.md`**（定型層） — テストの位置づけ・Guarantee-Driven Development・濃淡のリスクベース判断・保証台帳 `docs/guarantees.md` の構成と敷設・追従。相互参照: `guarantee-audit/SKILL.md` が台帳の敷設と棚卸しを実装、`issue-driven-workflow.md` の Issue 保証節と対応。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/readme-guide.md`**（判断層） — README の種別判定（Type A/B/C）・下限・コアメッセージとターゲット・アウトラインの組み立て・`docs/` 分離。相互参照: `repo-readme/SKILL.md` が基準として読む、`repo-standardize/SKILL.md` は §1・§3 のみ使う、§8 の図は `diagram-guide.md` へ委譲。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/module-guide.md`**（判断層） — リポの型の判定手順（組み込み型 / ツールキット型 / 研究型）・モジュール境界の切り方・デモ・既存リポへの追加。相互参照: `module-dev/SKILL.md` が規範として読む、§1 が `readme-guide.md` §1 の Type A/B/C との対応と優先順位を規定（参照は片方向）。棚卸し: 8dd42e6 2026-08-15
- **`docs-agents/diagram-guide.md`**（判断層） — 図を描くかの判断・幅の制約・形と線種・抽象度・分割の軸。相互参照: `readme-guide.md` §8 から委譲される、描く手順は `mermaid-diagram/SKILL.md` が持つ（本ガイドは基準のみで手順を持たない）。棚卸し: 8dd42e6 2026-08-15

## Skill（frontmatter description が日本語のもの）

ベンダー技術リファレンス系・Anthropic 標準搭載 Skill は対象外。判定は実行時に frontmatter を見て行い、固定の除外リストは保守しない。

### 公開パイプライン

固定順 `repo-standardize → guarantee-audit → repo-readme → readme-i18n → repo-publish → repo-about`。

- **`.claude/skills/repo-standardize/SKILL.md`** — 新規リポの組成・既存リポの公開前点検を docs-agents の4基準で行う（第1）。相互参照: 基準は `repo-guide.md` / `harness-guide.md` / `issue-driven-workflow.md` / `cicd-guide.md` の4本、README は `readme-guide.md` §1・§3 のみ使い残りは `repo-readme` に譲る。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/guarantee-audit/SKILL.md`** — 既存テストから公開面の保証を抽出し保証台帳のドラフトを user 裁可にかけ、欠落テストを追加する（第2）。相互参照: `test-policy.md` の台帳規定を実装。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/repo-readme/SKILL.md`** — 公開前の本格 README を作成・更新する（第3）。相互参照: 基準は `readme-guide.md`、図は `diagram-guide.md` 経由で `mermaid-diagram` へ委譲。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/readme-i18n/SKILL.md`** — 日本語 README から英語版を生成・同期し、言語切替リンクを挿入する（第4）。相互参照: 文章規範は `jp-writing/SKILL.md`。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/repo-publish/SKILL.md`** — Private リポの Public 化。全履歴のシークレットスキャンから公開時にしかできない設定までを一括で行う（第5）。相互参照: `repo-guide.md` §3・§4 を前提、公開後の CI 設定は `cicd-guide.md` §6。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/repo-about/SKILL.md`** — README から GitHub の About と topics を生成して設定する（第6）。棚卸し: 8dd42e6 2026-08-15

### Issue 駆動ワークフロー

- **`.claude/skills/new-issue/SKILL.md`** — 相談者として Issue ファイルを設計し `issues/` に書き出す。コードは書かない（軽量経路を除く）。相互参照: `issue-driven-workflow.md` の担当分離節と Issue フォーマットを実装、保証節は `test-policy.md` に依存。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/pr-workflow/SKILL.md`** — 実行者の実装からローカルコミットまでの標準フロー。push・PR 作成はしない。相互参照: `issue-driven-workflow.md` の実行者側、検証手段は各リポ `CLAUDE.md` に委ねる設計。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/session-nudge/SKILL.md`** — 別の稼働中セッションについて相談し、必要なら人間の裁可を経て送る。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/hunk-comments/SKILL.md`** — 稼働中の Hunk に user が行単位で残したレビューコメントを取り込んで対応する。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/ctx-history-search/SKILL.md`** — 過去の相談者セッションを ctx で検索する。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/dependabot-triage/SKILL.md`** — 溜まった Dependabot PR を横断棚卸しし、条件を満たすものはマージまで行う。相互参照: 判断基準の正本は `cicd-guide.md` §6。棚卸し: 8dd42e6 2026-08-15

### 執筆・設計

- **`.claude/skills/jp-writing/SKILL.md`** — 日本語の文章規範。冗長の排除・LLM口調の禁止・視点の一貫性・リライト時の一律適用の禁止。相互参照: `readme-i18n` / `repo-readme` が文章を書く際の前提。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/mermaid-diagram/SKILL.md`** — Mermaid 図の新規作成・監査・修正の手順。相互参照: 基準は `diagram-guide.md`（本 Skill は手順のみで基準を持たない）、README 文脈では `repo-readme` から `readme-guide.md` §8 経由で呼ばれる。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/module-dev/SKILL.md`** — OSS モジュール型リポの設計標準。型と配布形態・デモ方式を決める。相互参照: 規範の正は `module-guide.md`。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/comment-cleanup/SKILL.md`** — WHAT を説明するだけの冗長なコメント・日付入り履歴コメントを検出して削除・圧縮する。行数の機械的な強制はしない。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/skill-dev/SKILL.md`** — 新しい Skill の配置ルール。global とリポ固有の判断、frontmatter の必須項目、既定の `disable-model-invocation: true`。相互参照: `.claude/hooks/block-new-skill-md.sh` が Write 時にこの規約を検査する。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/consolidate-rules/SKILL.md`** — 本索引を起点に規則ファイルの矛盾・陳腐化を棚卸しする。相互参照: 索引は本ファイル、対象は CLAUDE.md群・docs-agents・日本語 description の Skill。棚卸し: 8dd42e6 2026-08-15

### インフラ運用

- **`.claude/skills/sops-secrets/SKILL.md`** — sops / age による secret の暗号化・復号・追加・再暗号化。カテゴリと format の対応、新デバイスの鍵登録。相互参照: `devices/secrets.nix` の `legacyBinaryCategories` 機構が format 判定の実体、OS 別手順は `references/{linux,macos}.md`。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/nix-tool-install/SKILL.md`** — 新しい CLI ツールの導入手順。Nix 外のパッケージマネージャを禁止する。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/netboot-stateless/SKILL.md`** — ディスクレス機を netboot で配信・起動する運用手順と、netboot 系エラーの対処。棚卸し: 8dd42e6 2026-08-15
- **`.claude/skills/cf-private-deploy/SKILL.md`** — Cloudflare Pages + Access で自分だけに閉じたアプリを配信する。GUI を排し REST API で通す。相互参照: `cicd-guide.md` §3・§4 の具体化。棚卸し: 8dd42e6 2026-08-15
