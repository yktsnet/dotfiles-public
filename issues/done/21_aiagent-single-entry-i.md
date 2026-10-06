## PR記録: feat: Issue駆動の入口を `i` 1本にし、実行者が確認を受けてから PR を出す
issue: 21 (21_aiagent-single-entry-i.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/76

## 変更内容
今の流れは、実行者がローカルコミットまで走り、user が `issue-finish` で push・PR・マージをまとめて行う。動作を確かめて直す道が実行者のセッションに無く、入口も `issue` / `issue-open` / `issue-abort` / `issue-finish` / `issue-import-pr` / `issue-status` と散っていた。これを作者の手元で回している現行の形に揃えた。実行者はコミットしたら止まり、user が同じセッションで動作を確かめて直させ、OK を受けて実行者が Issue を `done/` へ閉じて PR を出す。人が打つコマンドは、全リポを横断する `i` だけになった。後片付けは人が呼ばずに進む。

- `aiagent.sh`: 移植元（作者の手元の dotfiles）をほぼそのまま移し、4点を一般化した
  - 横断するリポ: `AIAGENT_REPO_ROOTS`（空白区切り）で指定。要素自体が git リポならそれを、そうでなければ直下の git リポを対象にする。未設定なら `$HOME/dotfiles-public` の1つだけ。Backlog.md 台帳の除外条件は持ち込まない
  - Issue の置き場: リポ直下の `issues/` だけ（`apps/*/issues` は見ない）
  - config dir: `CLAUDE_CONFIG_DIR` が設定されていればそれを使い、隠しセッションへは設定されているときだけ渡す
  - 校正の待ち合わせ: 公開版に無い仕組みなので外し、未コミットの変更だけを見る
- `pr-workflow` / `local-issue`（SKILL.md・issue-template.md）: 移植元に揃え、実行者が動作確認を受けてから Issue を閉じて PR を出す手順に更新。テンプレートの `github_issue:` 欄を外す（記録用の GitHub Issue は作らない）
- `local-issue/reference/proposal.md`（新規）: 報告の表の型を追加
- `CLAUDE.md`: 「動作フロー」を実行者が確認を受けてから PR を出す形に直し、入口が `i` であることを明記

## 保証
- 新たに宣言する保証・維持する保証・廃止する保証: Issue の保証節に記載した内容（下記 Issue 記録を参照）。aiagent.sh のテスト基盤がリポに無いため対応する自動テストはなし（理由: zsh の実行系はリポにテスト基盤が無い既存の扱いと同じ）。確認は下記の静的確認と、user が2つ以上のリポに Issue を置いて `i` で起票から後片付けまで通す手動確認で担保する

## 静的確認結果
- `zsh -n home-manager/modules/zsh/functions/aiagent.sh` → OK
- `nix flake check` → ✅ darwinConfigurations.macbook（x86_64-linux は評価省略、既存の警告のみ）
- grep で `issue-finish` / `issue-open` / `issue-abort` / `issue-import-pr` / `issue-status` / `_aiagent_finish` への参照を確認: 対象ファイル（aiagent.sh・pr-workflow/SKILL.md・local-issue 配下・CLAUDE.md）からは消えており、`issues/` 以外で残るのは Issue の対象外に明記した README.md・README.en.md・context/structure.md・home-manager/modules/zsh/README.md・repo-standardize skill のみ（Issue 22 で対応予定）
- caller/import整合性: aiagent.sh 内の呼び出し元を確認。`_claude_config_dir` 呼び出しは削除済みで呼び出し元も残っていない。`_aiagent_get_issues_dirs` / `_aiagent_repos` の全呼び出し元（`_aiagent_count_status` / `_aiagent_purge_untracked` / `_aiagent_entries` / `_aiagent_reap_all` / `_aiagent_status_all` / `_aiagent_run`）は新しいシグネチャ（引数・戻り値とも変更なし）のまま動作する
- `crit --base-branch main` によるレビュー: 承認済み、指摘なし（7ファイル・23秒）

## 検証手順
- 各デバイスで `home-manager switch` を適用する
- 2つ以上のリポ（`AIAGENT_REPO_ROOTS` で指定）に Issue を置き、`i` で一覧→実装→動作確認→PR までを1本通して確認する
- `AIAGENT_REPO_ROOTS` 未設定時に `$HOME/dotfiles-public` だけが対象になることを確認する

---

## Issue 駆動の入口を `i` 1本にし、実行者が確認を受けてから PR を出す
id: 21
branch-slug: aiagent-single-entry-i
status: close
type: feat
対象:
- home-manager/modules/zsh/functions/aiagent.sh
- .claude/skills/pr-workflow/SKILL.md
- .claude/skills/local-issue/SKILL.md
- .claude/skills/local-issue/reference/issue-template.md
- .claude/skills/local-issue/reference/proposal.md（新規）
- CLAUDE.md
内容: 今の流れは、実行者がローカルコミットまで走り、user が `issue-finish` で push・PR・マージをまとめて行う。動作を確かめて直す道が実行者のセッションに無く、入口も `issue` / `issue-open` / `issue-abort` / `issue-finish` / `issue-import-pr` / `issue-status` と散っている。これを作者の手元で回している現行の形に揃える。実行者はコミットしたら止まり、user が同じセッションで動作を確かめて直させ、OK を受けて実行者が Issue を `done/` へ閉じて PR を出す。人が打つコマンドは、全リポを横断する `i` だけにする。後片付けは人が呼ばずに進む。
対象外: README.md・README.en.md・context/structure.md・home-manager/modules/zsh/README.md・repo-standardize skill・新しい手順書（Issue 22）。`.claude/settings.json` の deny の見直し。tmux の M-u ピッカー（既にある）。
仮定: 移植元は作者の手元の dotfiles の `zsh/functions/aiagent.sh`・`.claude/skills/pr-workflow/SKILL.md`・`.claude/skills/local-issue/`（公開リポには無い。ローカルの `~/dotfiles/` を読む）。移植元の環境に固有な部分は、下の「一般化」のとおりに置き換える。記録用の GitHub Issue は作らず、テンプレートの `github_issue:` 欄も外す（既存の `issues/done/` のファイルにある欄はそのまま残す）。
確認: `zsh -n home-manager/modules/zsh/functions/aiagent.sh`、`nix flake check`。`issue-finish`・`issue-open`・`issue-abort`・`issue-import-pr`・`issue-status` と `_aiagent_finish` への参照が、対象ファイルと `issues/` 以外に増えていないこと、対象ファイルからは消えていることを grep で確かめる（README 等の残りは Issue 22 で消す）。

---

### 保証
- 新たに宣言する保証:
  - `i` はどのディレクトリから呼んでも、`AIAGENT_REPO_ROOTS` が指すリポを横断した同じ一覧を出す。並びは run（open の Issue）→ approve（draft の Issue）→ merge（`claude/*` の open な PR）→ abort（`claude/*` の枝）→ status の順で、各行にリポ名が付く。候補が1件も無ければ一覧を出さず、Issue か枝の残るリポの現在地だけを出す
  - open の Issue でも、対応する `claude/{id}-{slug}` の枝があるもの（実装中か PR 待ち）は run に出さない。abort で枝を消すと run に戻る
  - abort は worktree の有無に関わらず `claude/*` の枝を並べ、確認（既定 No）のあと枝を消す。worktree が残っていれば一緒に消す
  - 複数選べるのは同じリポの run だけで、3件まで。1件ごとに worktree を切り、tmux の隠しセッションで実行者を起動する。tmux の外では起動せずに止まる
  - 実行者は、user が PR を出すよう明示するまで push も PR 作成もしない。main へ push せず、user に頼まれない限りマージしない
  - PR を出すとき、Issue ファイルは同じ枝の中で `done/` へ移り `status: close` になり、先頭に PR の題・URL・本文の記録が付く
  - 1件で起動した実行者のセッションが終わったとき、PR が出ていて、枝が origin と揃い、未コミットの変更が無い場合に限り worktree を消す。枝は残す。どれかを欠けば worktree を残し、push していないコミットがあればその旨を出す
  - `i` は一覧を出す前に、全リポの PR がマージ済みの `claude/*` を畳み（worktree・ローカルとリモートの枝・main 側に残った untracked の Issue ファイル）、畳んだリポだけ main を origin に追従させる。`claude/*` の枝が無いリポには gh を呼ばない
  - main 側の untracked の Issue ファイルを消すのは、マージした枝に同じパスか `done/` 配下の同じ名前のファイルがあるものだけである
  - merge を選ぶと、確認のあと squash でマージし、畳んで main を追従させる
- 維持する保証:
  - draft と open の Issue は main では untracked のままで、公開されない
  - 実行者はスコープ外の作業に気づいたら AskUserQuestion で扱いを聞き、新しい Issue にするなら main のチェックアウトの `issues/` に draft で書く
  - 未コミットの変更が残る worktree は畳まずに残し、その旨を出す
- 廃止する保証:
  - リモートへ出る経路は user の `issue-finish` だけである
  - `issue`・`issue-open`・`issue-abort`・`issue-finish`・`issue-import-pr`・`issue-status` の各入口の振る舞い

自動テストは無い。上の確認に加えて、user が2つ以上のリポに Issue を置き、1本を `i` で起票から後片付けまで通して確かめる。

### aiagent.sh

移植元をほぼそのまま持ってくる。次の4点だけ一般化する。

- **横断するリポ**: 移植元の `_aiagent_repos` は作者のディレクトリを直書きしている。変数 `AIAGENT_REPO_ROOTS`（空白区切り）で与える。各要素は、それ自体が git リポならそのリポを、そうでなければ直下の git リポを対象にする（`{repo}.wt/` のように `.git` を持たないものは外れる）。未設定なら `$HOME/dotfiles-public` を1つだけ対象にする。移植元にある Backlog.md 台帳のリポを除く条件は持ち込まない
- **Issue の置き場**: 移植元の `_aiagent_get_issues_dirs` は作者のリポだけ `apps/*/issues` も見る。公開版はリポ直下の `issues/` だけにする
- **config dir**: 移植元の `_claude_config_dir` は作者の環境のラッパにある関数で、公開版には無い。`CLAUDE_CONFIG_DIR` が設定されていればそれを、無ければ既定（`~/.claude.json` は `$HOME` 直下）を使う。tmux の隠しセッションへは、設定されているときだけ `CLAUDE_CONFIG_DIR` を渡す
- **校正の待ち合わせ**: 移植元の `_aiagent_wt_clean` は、作者の環境の裏の校正（`jp-proofread`）が走り終わるのを待ってから未コミットの変更を見る。公開版にその仕組みは無いので、待ち合わせを外して未コミットの変更だけを見る

ファイル冒頭の、`_confirm` と `_sed_i` に頼る旨のコメントは残す。`i` の定義の直前に用途を1行で書く。

### pr-workflow

移植元に揃える。「`i`」「`done/`」の記述はそのまま使える。

### local-issue（SKILL.md・issue-template.md・proposal.md）

移植元に揃える。テンプレートのパスの説明（本リポの `.claude/skills/` が正本で home-manager が配る）は公開版の記述を残す。`proposal.md` は報告の表の型で、移植元をそのまま置く。

### CLAUDE.md

「動作フロー」の `issue-finish` の記述を、実行者が user の確認を受けてから PR を出す形に直す。入口は `i` であることを1行で書く。
