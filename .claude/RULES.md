# RULES.md — 規則棚卸しの索引

`consolidate-rules` Skill が読み書きする索引。規則の実体はここに書かず、対象ファイルへのポインタ・一言要約・相互参照・正本の向き・直近棚卸し時点の内容ハッシュのみを記録する。次回実行時はここを起点に、`git hash-object` が記載と食い違うファイルだけを深読みする。`棚卸し: 未` は「まだ精読していない」であって「変更が無い」ではない。

## CLAUDE.md群

- **`CLAUDE.md`**（リポ直下） — 実行者向けの動作フロー・検証コマンド・アーキテクチャの要点。禁止と強制は書かず `.claude/settings.json` の deny と `.claude/hooks/` に委ねると宣言している。相互参照: `docs-agents/harness-guide.md` §2〜§4 の層構成を実装した例であり、`pr-workflow/SKILL.md` へ実装手順を委譲。棚卸し: 5a19b05c 2026-08-16

## docs-agents（基準の実体）

判断層（リポごとに答えが変わる）と定型層（一度決めれば機械適用できる）に分かれ、その上に両者の前提を述べる原理層が1本ある。英語版 `*.en.md` は日本語版の従属物であり、規則の実体ではないため索引の対象にしない。

- **`docs-agents/principles.md`**（原理層） — 注意し続ける人間を前提にしない開発体系。三役・フェーズ・駆動文書・保証の用語定義と、導入5段（型を決める / 禁止を仕組みに置く / 知識を配置する / 保証を裁可する / 決める人と作る人を分ける）の本質・機構・完了条件。相互参照: 各段の末尾から判断層・定型層の全ガイドへ参照を張る側であり、他ガイドからは参照されない（依存は片方向）。正本: public。棚卸し: 960dea65 2026-08-16
- **`docs-agents/repo-guide.md`**（定型層） — ファイル衛生・`.gitignore` の基準・repo 面のシークレット・公開前チェックリスト。相互参照: `repo-standardize/SKILL.md` が基準として読む、`repo-publish/SKILL.md` の公開前スキャンが §3・§4 を前提にしている。正本: 双方向。棚卸し: 1930d55a 2026-08-16
- **`docs-agents/harness-guide.md`**（定型層） — リポ類型と検証手段・`.claude/` の層構成（層1 settings.json とフック / 層2 指示ファイル）・新規リポのチェックリスト。相互参照: `repo-standardize/SKILL.md` が基準として読む、リポ直下 `CLAUDE.md` はこの層2の実装例。正本: public（§3.5・§4.5・§4.6 は公開側が先行）。棚卸し: 767f154d 2026-08-16
- **`docs-agents/issue-driven-workflow.md`**（定型層） — フェーズ（MVP期 / Issueドリブン期）・担当分離・Issue フォーマット・シェル関数。相互参照: `new-issue/SKILL.md` が Issue フォーマットと担当分離を実装、`pr-workflow/SKILL.md` が実行者側の手順を担う、`docs-agents/test-policy.md` の保証節を Issue フォーマットに組み込んでいる。正本: private。棚卸し: ae793eed 2026-08-16
- **`docs-agents/cicd-guide.md`**（定型層） — 2つのリポパターン・CI・デプロイ・デモ公開・Secrets・Dependabot・担当分離との接続。相互参照: `dependabot-triage/SKILL.md` の判断基準の正本は §6、`cf-private-deploy/SKILL.md` が §3・§4 の具体化、`readme-guide.md` §8 の Deploy 節が本ガイドへ委譲。正本: private。棚卸し: db9bd6ed 2026-08-16
- **`docs-agents/test-policy.md`**（定型層） — テストの位置づけ・Guarantee-Driven Development・濃淡のリスクベース判断・保証台帳 `docs/guarantees.md` の構成と敷設・追従。相互参照: `guarantee-audit/SKILL.md` が台帳の敷設と棚卸しを実装、`issue-driven-workflow.md` の Issue 保証節と対応。正本: public（台帳集約の節は公開側が先行）。棚卸し: 49f53c0a 2026-08-16
- **`docs-agents/readme-guide.md`**（判断層） — README の種別判定（Type A/B/C）・下限・コアメッセージとターゲット・アウトラインの組み立て・`docs/` 分離。相互参照: `repo-readme/SKILL.md` が基準として読む、`repo-standardize/SKILL.md` は §1・§3 のみ使う、§8 の図は `diagram-guide.md` へ委譲。正本: private。棚卸し: 7460c05a 2026-08-16
- **`docs-agents/module-guide.md`**（判断層） — リポの型の判定手順（組み込み型 / ツールキット型 / 研究型）・モジュール境界の切り方・デモ・既存リポへの追加。相互参照: `module-dev/SKILL.md` が規範として読む、§1 が `readme-guide.md` §1 の Type A/B/C との対応と優先順位を規定（参照は片方向）。正本: public。棚卸し: 9e0a8baa 2026-08-16
- **`docs-agents/diagram-guide.md`**（判断層） — 図を描くかの判断・幅の制約・形と線種・抽象度・分割の軸。相互参照: `readme-guide.md` §8 から委譲される、描く手順は `mermaid-diagram/SKILL.md` が持つ（本ガイドは基準のみで手順を持たない）。正本: 双方向。棚卸し: 6204c929 2026-08-16

## Skill（frontmatter description が日本語のもの）

ベンダー技術リファレンス系・Anthropic 標準搭載 Skill は対象外。判定は実行時に frontmatter を見て行い、固定の除外リストは保守しない。

### 公開パイプライン

固定順 `repo-standardize → guarantee-audit → repo-readme → readme-i18n → repo-publish → repo-about`。

- **`.claude/skills/repo-standardize/SKILL.md`** — 新規リポの組成・既存リポの公開前点検を docs-agents の4基準で行う（第1）。相互参照: 基準は `repo-guide.md` / `harness-guide.md` / `issue-driven-workflow.md` / `cicd-guide.md` の4本、README は `readme-guide.md` §1・§3 のみ使い残りは `repo-readme` に譲る。棚卸し: a2505d1b 2026-08-16
- **`.claude/skills/guarantee-audit/SKILL.md`** — 既存テストから公開面の保証を抽出し保証台帳のドラフトを user 裁可にかけ、欠落テストを追加する（第2）。相互参照: `test-policy.md` の台帳規定を実装。棚卸し: 593bb31f 2026-08-16
- **`.claude/skills/repo-readme/SKILL.md`** — 公開前の本格 README を作成・更新する（第3）。相互参照: 基準は `readme-guide.md`、図は `diagram-guide.md` 経由で `mermaid-diagram` へ委譲。棚卸し: 98ccccee 2026-08-16
- **`.claude/skills/readme-i18n/SKILL.md`** — 日本語 README から英語版を生成・同期し、言語切替リンクを挿入する（第4）。相互参照: 文章規範は `jp-writing/SKILL.md`。棚卸し: 5bca6c3d 2026-08-16
- **`.claude/skills/repo-publish/SKILL.md`** — Private リポの Public 化。全履歴のシークレットスキャンから公開時にしかできない設定までを一括で行う（第5）。相互参照: `repo-guide.md` §3・§4 を前提、公開後の CI 設定は `cicd-guide.md` §6。棚卸し: 684c72fd 2026-08-16
- **`.claude/skills/repo-about/SKILL.md`** — README から GitHub の About と topics を生成して設定する（第6）。棚卸し: fa1eaf62 2026-08-16

### Issue 駆動ワークフロー

- **`.claude/skills/new-issue/SKILL.md`** — 相談者として Issue ファイルを設計し `issues/` に書き出す。コードは書かない（軽量経路を除く）。相互参照: `issue-driven-workflow.md` の担当分離節と Issue フォーマットを実装、保証節は `test-policy.md` に依存。棚卸し: 6d40fbe8 2026-08-16
- **`.claude/skills/pr-workflow/SKILL.md`** — 実行者の実装からローカルコミットまでの標準フロー。push・PR 作成はしない。相互参照: `issue-driven-workflow.md` の実行者側、検証手段は各リポ `CLAUDE.md` に委ねる設計。棚卸し: d5cfc850 2026-08-16
- **`.claude/skills/session-nudge/SKILL.md`** — 別の稼働中セッションについて相談し、必要なら人間の裁可を経て送る。棚卸し: ec5d4b79 2026-08-16
- **`.claude/skills/hunk-comments/SKILL.md`** — 稼働中の Hunk に user が行単位で残したレビューコメントを取り込んで対応する。棚卸し: d14ad028 2026-08-16
- **`.claude/skills/ctx-history-search/SKILL.md`** — 過去の相談者セッションを ctx で検索する。棚卸し: da5a5de3 2026-08-16
- **`.claude/skills/dependabot-triage/SKILL.md`** — 溜まった Dependabot PR を横断棚卸しし、条件を満たすものはマージまで行う。相互参照: 判断基準の正本は `cicd-guide.md` §6。棚卸し: 39a39d34 2026-08-16

### 執筆・設計

- **`.claude/skills/jp-writing/SKILL.md`** — 日本語の文章規範。冗長の排除・LLM口調の禁止・視点の一貫性・リライト時の一律適用の禁止。相互参照: `readme-i18n` / `repo-readme` が文章を書く際の前提。棚卸し: 937ba036 2026-08-16
- **`.claude/skills/mermaid-diagram/SKILL.md`** — Mermaid 図の新規作成・監査・修正の手順。相互参照: 基準は `diagram-guide.md`（本 Skill は手順のみで基準を持たない）、README 文脈では `repo-readme` から `readme-guide.md` §8 経由で呼ばれる。棚卸し: b4bd9ce5 2026-08-16
- **`.claude/skills/module-dev/SKILL.md`** — OSS モジュール型リポの設計標準。型と配布形態・デモ方式を決める。相互参照: 規範の正は `module-guide.md`。棚卸し: b9b3068f 2026-08-16
- **`.claude/skills/comment-cleanup/SKILL.md`** — WHAT を説明するだけの冗長なコメント・日付入り履歴コメントを検出して削除・圧縮する。行数の機械的な強制はしない。棚卸し: f0fe1091 2026-08-16
- **`.claude/skills/skill-dev/SKILL.md`** — 新しい Skill の配置ルール。global とリポ固有の判断、frontmatter の必須項目、既定の `disable-model-invocation: true`。相互参照: `.claude/hooks/block-new-skill-md.sh` が Write 時にこの規約を検査する。棚卸し: 6f29322f 2026-08-16
- **`.claude/skills/consolidate-rules/SKILL.md`** — 本索引を起点に規則ファイルの矛盾・陳腐化を棚卸しする。相互参照: 索引は本ファイル、対象は CLAUDE.md群・docs-agents・日本語 description の Skill。棚卸し: 9dfa044c 2026-08-16

### インフラ運用

- **`.claude/skills/sops-secrets/SKILL.md`** — sops / age による secret の暗号化・復号・追加・再暗号化。カテゴリと format の対応、新デバイスの鍵登録。相互参照: `devices/secrets.nix` の `legacyBinaryCategories` 機構が format 判定の実体、OS 別手順は `references/{linux,macos}.md`。棚卸し: d8b01e25 2026-08-16
- **`.claude/skills/nix-tool-install/SKILL.md`** — 新しい CLI ツールの導入手順。Nix 外のパッケージマネージャを禁止する。棚卸し: 98b30473 2026-08-16
- **`.claude/skills/netboot-stateless/SKILL.md`** — ディスクレス機を netboot で配信・起動する運用手順と、netboot 系エラーの対処。棚卸し: 2e90dbd3 2026-08-16
- **`.claude/skills/cf-private-deploy/SKILL.md`** — Cloudflare Pages + Access で自分だけに閉じたアプリを配信する。GUI を排し REST API で通す。相互参照: `cicd-guide.md` §3・§4 の具体化。棚卸し: 55b6d6f5 2026-08-16

## 裁可済みの差分（再検討しない）

- **`docs-agents/{issue-driven-workflow,harness-guide,cicd-guide,repo-guide}.md` ↔ 非公開側 `{workflow,harness,cicd,repo}.md`** — ファイル名と相互参照の一般化のみ。2026-08-16
- **`docs-agents/*.en.md`** — 本リポにのみ存在する英語版。非公開側へ戻さない。2026-08-16
- **`context/conventions.md`・`context/structure.md`** — 本リポ自身の構成・規約を記述する別文書であり、非公開側との同期対象にしない。2026-08-16
- **`docs-agents/diagram-guide.md`** — 適用先の列挙から非公開側にある個別の記事・文書名を落としてある。2026-08-16
- **`.claude/skills/{nix-tool-install,netboot-stateless,ctx-history-search,cf-private-deploy,sops-secrets,mermaid-diagram,consolidate-rules}/`** — 実デバイス名を役割名へ、非公開側の絶対パスをリポ相対パスへ置換済み。2026-08-16
- **`.claude/skills/{nix-tool-install,sops-secrets}/`** — 本リポは macOS（nix-darwin）手順を保持する。フリート表が macbook を凍結保持しているためで、非公開側（Linux のみ）とは揃えない。2026-08-16
