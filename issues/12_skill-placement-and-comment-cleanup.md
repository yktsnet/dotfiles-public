## skill の配置基準（skill-dev / module-dev）と comment-cleanup を公開する
id: 12
branch-slug: skill-placement-and-comment-cleanup
github_issue:
status: open
type: feat
対象:
- .claude/skills/skill-dev/SKILL.md (新規)
- .claude/skills/module-dev/SKILL.md (新規)
- .claude/skills/comment-cleanup/SKILL.md (新規)
- plugins/public-skills/skills/comment-cleanup/SKILL.md (新規)
- plugins/public-skills/.claude-plugin/plugin.json
- .claude-plugin/marketplace.json
- README.md
- README.en.md
内容: 本リポは `block-new-skill-md.sh` で「新規 skill の配置先と frontmatter を検査する」フックを公開しているが、**検査に落ちたあと何を判断すればよいかの基準**（global か repo-local か）が公開されていない。その基準である `skill-dev` を足す。あわせて、公開済み `docs-agents/module-guide.md` への入口である `module-dev` と、CLAUDE.md のコメント規約を事後適用する `comment-cleanup` を足す。`comment-cleanup` はリポ非依存なので `public-skills` プラグインにも収録する。
確認: 目視確認（3 skill の frontmatter が `block-new-skill-md.sh` の検査項目を満たすこと、`.claude/skills/comment-cleanup/` と `plugins/public-skills/skills/comment-cleanup/` の内容が一致すること、`plugin.json` / `marketplace.json` / README 日英の skill 数と列挙が一致すること）。`jq empty` で2つの JSON の構文確認。

---

### 保証
- 新たに宣言する保証:
  - `plugins/public-skills` に収録する skill の一覧が、`plugin.json` の description・`marketplace.json` の description・README 日英の記述の4箇所で一致する
  - `.claude/skills/comment-cleanup/SKILL.md` と `plugins/public-skills/skills/comment-cleanup/SKILL.md` は同一内容である
  - 追加する3 skill の frontmatter は `name` と `description` を持つ
- 維持する保証:
  - `plugins/public-skills` に既存の6 skill（readme-i18n / repo-about / jp-writing / jp-writing-code / vhs-demo / app-demo-gif）の収録と内容を変えない
  - `.claude/skills/` の既存 skill を変更しない
  - `/plugin marketplace add` → `/plugin install public-skills` の導入手順を変えない

**テスト欠落について（裁可済み・見送る）**: 「4箇所の一覧が一致する」「2箇所の comment-cleanup が同一内容」は機械的に検証できる契約だが、本リポに skill 群を対象にしたテスト基盤が無く、目視確認に留める。既存の6 skill も同じ扱いになっている。Python のテスト基盤は Issue 16 で `apps/lpt/` にのみ敷く。

### skill-dev / module-dev は自動発火のまま公開する（裁可済み）

本リポの `block-new-skill-md.sh` は、新規 SKILL.md の frontmatter に `disable-model-invocation: true`（または `manual: true`）が無ければ **Write を拒否する**。フリートの既定が「skill は明示呼び出し専用」だからである。

一方 `skill-dev` と `module-dev` は、私物側では**意図的にこの行を持たない**。`skill-dev` は「SKILL.md を書き始める前に」発火してこそ意味があり、user が名前を思い出して `/skill-dev` と打てるなら、そもそも配置を間違えていない。`module-dev` も同様に、モジュール型リポを始める場面で自動的に出てほしい。

つまりこの2つは既定に対する意図的な例外であり、そのまま移植すると**本リポのフック自身が作成を拒否する**。

**裁可の結果、自動発火のまま公開する。** 実行者は `disable-model-invocation: true` を付けた状態で Write し、その直後に Edit でその行だけ削ること（フックが検査するのは Write による新規作成のみ）。「フックの既定を、フックを説明する skill 自身が破る」形になるが、この2 skill が自動発火してこそ意味があるという判断を公開物としても保つ。

`comment-cleanup` は私物側でも `disable-model-invocation: true` なので、この論点に関係しない。

### 仕様

#### .claude/skills/skill-dev/SKILL.md（新規）

コピー元: `~/dotfiles/.claude/skills/skill-dev/SKILL.md`（37行）。固有の接続情報は含まない。

内容は3節（置き場所の判断・作成前の重複確認・frontmatter の規約）で、次の骨格を保つこと。

- global（`~/dotfiles/.claude/skills/`）が既定。`home-manager/modules/claude.nix` が rebuild のたびに `~/.claude/skills/` へ丸ごとコピーするので、**`~/.claude/skills/` に直接書いても正本ではなく次回 rebuild で消える**
- repo-local が正しいのは「そのリポでしか意味を持たない手順」だけ。迷ったら「他のリポでこの手順が使われる場面があるか」で判断する
- 反映には dotfiles 側の rebuild が要るため、作成したセッションではまだ skill 一覧に出ない場合がある
- frontmatter の規約は `block-new-skill-md.sh` が検査する。詳細をここに二重化せず、フック本体を参照させる

`docs-agents/harness-guide.md` の「知識の配置基準」節と内容が重なるが、**あちらは「何を skill にするか」、こちらは「どこに置くか」**である。統合せず、`skill-dev` からは配置の話だけを扱う。

#### .claude/skills/module-dev/SKILL.md（新規）

コピー元: `~/dotfiles/.claude/skills/module-dev/SKILL.md`（13行）。

`docs-agents/module-guide.md` への薄い入口であり、本文は「まず module-guide.md を読む」と要旨4点（型を決める / 分離 / 構造 / デモ）だけ。**要旨を膨らませない。** 正本は `module-guide.md` で、この skill が育つと二重管理になる。

参照先のパスは本リポの相対パス表記（`docs-agents/module-guide.md`）に直す。

#### .claude/skills/comment-cleanup/SKILL.md（新規）

コピー元: `~/dotfiles/.claude/skills/comment-cleanup/SKILL.md`（55行）。frontmatter の `disable-model-invocation: true` を保つ。

移植にあたり1点だけ直す。**§3「適用」がワークフロールールの参照先として `~/dotfiles/.claude/CLAUDE.md` の章名を挙げているが、本リポにそのファイルは無い。** 参照先を `docs-agents/issue-driven-workflow.md` に差し替える。あわせて「dotfilesなど直接編集可のリポでは〜」という私物固有の例示を、リポ種別の一般形（Issue ドリブンのリポでは Issue 化フローに従い、そうでないリポでは直接編集してよい）に書き換える。

それ以外（検出の rg + awk、WHAT型は削除・WHY型は残す・日付入りの日記コメントは日付を落とす、sed/awk での一括置換をしない、完了報告の4項目）はそのまま移植する。この skill の要点は**行数の機械的な強制をしないこと**なので、閾値を足す方向に書き換えない。

#### plugins/public-skills/skills/comment-cleanup/SKILL.md（新規）

`.claude/skills/comment-cleanup/SKILL.md` と**同一内容**を置く。既存の6 skill が両方に同じものを持っている形に倣う。

#### plugins/public-skills/.claude-plugin/plugin.json

`description` に「コメント整理」を足す。`version` を `0.2.0` → `0.3.0` に上げる（skill が1つ増えるため）。

#### .claude-plugin/marketplace.json

`plugins[0].description` を `plugin.json` の description と同じ方針で更新する。

#### README.md / README.en.md

`## Role Separation` 節の末尾にある plugin marketplace の案内が「汎用性のある6 skill（readme-i18n, repo-about, jp-writing, jp-writing-code, vhs-demo, app-demo-gif）」となっている。7 skill に直し、列挙に `comment-cleanup` を足す。**この1文だけを変更する。** 追加した3 skill の説明を README に足さない（README は既に密度が高く、skill 個別の説明は各 SKILL.md が持つ）。

### 実装順序

1. `.claude/skills/comment-cleanup/SKILL.md`（参照先の差し替え込み）
2. `plugins/public-skills/skills/comment-cleanup/SKILL.md`（1 と同一内容）
3. `.claude/skills/skill-dev/SKILL.md`、`.claude/skills/module-dev/SKILL.md`（自動発火のまま。Write → Edit で作る）
4. `plugin.json` / `marketplace.json` と `jq empty`
5. `README.md` → `README.en.md`
