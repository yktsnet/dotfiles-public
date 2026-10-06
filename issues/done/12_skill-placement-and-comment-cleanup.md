## PR記録: feat(skills): skill配置基準とcomment-cleanupを公開する
issue: 12 (12_skill-placement-and-comment-cleanup.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/38
Merged: 4534a92e378931eff678a72c31af2e92f49a56c7

## 変更内容
- `.claude/skills/skill-dev/SKILL.md` を新規作成。skillの配置先（global の `~/dotfiles/.claude/skills/` か repo-local か）を判断する基準を公開する。裁可済みの例外として `disable-model-invocation: true` を付けずに公開する（自動発火してこそ意味がある2skillのため）。
- `.claude/skills/module-dev/SKILL.md` を新規作成。`docs-agents/module-guide.md` への薄い入口。参照パスを本リポの相対パスに直した。同じく自動発火のまま公開する。
- `.claude/skills/comment-cleanup/SKILL.md` を新規作成。§3「適用」の参照先を、私物 `~/dotfiles/.claude/CLAUDE.md` の章名から本リポの `docs-agents/issue-driven-workflow.md` に差し替え、私物固有の例示をリポ種別の一般形に書き換えた。それ以外（検出方法・分類基準・完了報告）はそのまま移植。
- `plugins/public-skills/skills/comment-cleanup/SKILL.md` を新規作成。`.claude/skills/comment-cleanup/SKILL.md` と同一内容。
- `plugins/public-skills/.claude-plugin/plugin.json`: description に「コメント整理」を追加、version を 0.2.0 → 0.3.0 に更新。
- `.claude-plugin/marketplace.json`: `plugins[0].description` を同じ方針で更新。
- `README.md` / `README.en.md`: plugin marketplace 案内の skill 数を6→7に直し、列挙に comment-cleanup を追加（この1文のみ変更）。

## 保証
- 新たに宣言する保証:
  - `plugins[0].description`（plugin.json・marketplace.json）と README 日英の skill 列挙が4箇所で一致する → 目視確認（本文参照）。テスト基盤なし（裁可済み・見送る、Issue本文の記載どおり）
  - `.claude/skills/comment-cleanup/SKILL.md` と `plugins/public-skills/skills/comment-cleanup/SKILL.md` が同一内容である → `diff` コマンドで確認（差分なしを確認済み）
  - 追加する3 skill の frontmatter が `name` と `description` を持つ → 目視確認（本文参照）
- 維持する保証:
  - 既存6 skill（readme-i18n / repo-about / jp-writing / jp-writing-code / vhs-demo / app-demo-gif）の収録・内容は無変更 → `git diff --name-only --cached` に該当ファイルが含まれないことで確認
  - `.claude/skills/` の既存 skill は無変更 → 同上
  - `/plugin marketplace add` → `/plugin install public-skills` の導入手順文言は無変更（skill数と列挙のみ変更）

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook ✅（既存の deprecated warning のみ、本変更に起因するエラーなし）
- `jq empty plugins/public-skills/.claude-plugin/plugin.json` / `jq empty .claude-plugin/marketplace.json`: 両方とも構文OK
- frontmatter確認: skill-dev / module-dev は `disable-model-invocation` を持たない（Issueで裁可された意図的例外）。comment-cleanup は `disable-model-invocation: true` を保持
- `diff .claude/skills/comment-cleanup/SKILL.md plugins/public-skills/skills/comment-cleanup/SKILL.md`: 差分なし
- plugin.json / marketplace.json / README.md / README.en.md の skill 列挙（6 skill + comment-cleanup = 7）が4箇所で一致することを確認
- `git diff --name-only --cached`:
  ```
  .claude-plugin/marketplace.json
  .claude/skills/comment-cleanup/SKILL.md
  .claude/skills/module-dev/SKILL.md
  .claude/skills/skill-dev/SKILL.md
  README.en.md
  README.md
  plugins/public-skills/.claude-plugin/plugin.json
  plugins/public-skills/skills/comment-cleanup/SKILL.md
  ```
  Issueの「対象」8ファイルと完全一致

## 検証手順
本Issueはドキュメント/skill定義の追加のみで実行系コマンドを伴わないため、Agent側の静的確認で完結。強いて言えば `/plugin install public-skills` 実行後にComment-cleanup skillが一覧に出ることの目視確認をuser側で行うと確実（必須ではない）。

---

## skill の配置基準（skill-dev / module-dev）と comment-cleanup を公開する
id: 12
branch-slug: skill-placement-and-comment-cleanup
github_issue: 39
status: close
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
