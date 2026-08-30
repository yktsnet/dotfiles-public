## PR記録: feat: aiagentにissue-statusを足し、選択UIとy/N確認を共通関数へ寄せる
issue: 19 (19_aiagent-issue-status-and-shared-menu.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/55
Merged: 72b6a9cdb186fcef0ec8ce75cea77976adb3e262

## 変更内容
公開しているIssue駆動ワークフローに、フローのどの段に球があるかを見る手段が無かった。
`issue-status` を足し、あわせて関数ごとに割れていたy/N確認を共通の `_confirm` に寄せた。

- `zsh/functions/menu.sh`（新規）: 選択UIの共通実装 `_pick` と、既定値・非対話時のフォールバックを持つ y/N 確認の共通実装 `_confirm` を置く。
- `zsh/common.nix`: `functions/menu.sh` を `functions/utils.sh` より前に読み込む（`_pick` / `_confirm` は他の関数ファイルの土台のため）。
- `zsh/functions/aiagent.sh`:
  - `_aiagent_confirm` を削除し、3箇所の呼び出しをすべて `_confirm`（既定値 `n`）へ置き換え。既存の挙動（Enterで No）を変えない。
  - `_aiagent_is_template` を追加し、`_aiagent_select_issue` / `_aiagent_select_draft_issue` から `00_template.md` を除外する。
  - `_aiagent_count_status` / `_aiagent_count_worktrees` / `_aiagent_count_unmerged` を追加。
  - `issue-status` を追加。draft/openの件数、open issueファイル一覧、`claude/*` worktree一覧（ブランチ・パス）、未マージ `claude/*` ブランチ一覧（コミット数）を、フローの段の順に表示する読み取り専用の関数。
- `zsh/README.md`: 関数表に `issue-status` と `functions/menu.sh` 行を追加し、公開範囲を4本→5本に更新。
- `docs-agents/issue-driven-workflow.md` / `.en.md`: `## シェル関数` 節に `### issue-status` を `issue` の直前に追加（実装は書かず、何を一覧するか・読み取り専用であることのみ）。

## 保証
- `issue-status` がカレントリポジトリの `issues/` 直下から draft/open の件数を数え、worktree・未マージブランチをパス・コミット数つきで一覧する → `zsh -c` での手動実行で確認済み（下記「静的確認結果」参照）。zshテスト基盤が本リポに無いため自動テストは付けない（Issueの「テスト欠落について」で申告済み、既存 `zsh/functions/*.sh` と同じ扱い）。
- `issue-status` がgitリポジトリ外でエラーをstderrに出し非ゼロで終わる → 同上、手動実行で確認済み。
- `_confirm` がEnterのみで既定値に倒れ、非対話（stdinクローズ）でもハングしない → 同上、手動実行で確認済み。
- `issue()` / `issue-open()` の選択候補と `issue-status` の件数から `00_template.md` を除外する → `_aiagent_is_template` を両選択関数と `_aiagent_count_status` のループに組み込み済み。手動での自動テストなし（同上の理由）。
- 維持する保証（`issue` / `issue-abort` / `issue-finish` / `issue-open` / `issue-import-pr` の既存挙動、`_aiagent_sed_inplace` のBSD/GNU吸収、台帳を `issues/` 単一に保つ）→ 該当ロジックは無変更。`_aiagent_confirm` の呼び出し置換のみで、各呼び出しの既定値は置換前と同じ「Enterで No」を維持。

## 静的確認結果
- `zsh -n zsh/functions/menu.sh` / `zsh -n zsh/functions/aiagent.sh`: 構文エラーなし。
- `grep -n "_aiagent_confirm" zsh/functions/aiagent.sh`: ヒットなし（コメント含め置換済み）。呼び出し3箇所はすべて `_confirm ... n` に置換済み。
- `nix flake check`（環境のunfreeパッケージ許可設定を一時的に渡して実行。本変更に起因しない既存の環境差分）: 全構成で `all checks passed!`。
- 手動実行（`zsh -c 'source menu.sh; source aiagent.sh; ...'`）で `_confirm` の既定値/非対話フォールバック、`_aiagent_is_template`、`_aiagent_count_status`（リポ内外双方）、`issue-status` の出力フォーマット（インデント・件数・一覧）を確認。実装中に `status` がzshの読み取り専用特殊変数（`$?`の別名）であることを発見し、ローカル変数名を `want_status` に変更して修正済み。
- `git diff --name-only --cached`: docs-agents/issue-driven-workflow.en.md, docs-agents/issue-driven-workflow.md, zsh/README.md, zsh/common.nix, zsh/functions/aiagent.sh, zsh/functions/menu.sh（Issueの対象と完全一致）。

## 検証手順
- 各デバイスで `home-manager switch` 適用後、新しいシェルで `issue-status` を実行し、出力（draft/open件数・openファイル一覧・worktree一覧・unmerged一覧）が実際のリポ状態と一致することを確認する。
- `issue` / `issue-abort` / `issue-finish` を実際に1回ずつ通し、確認プロンプトでEnterのみ押した場合に既定どおり中断される（Noに倒れる）ことを目視確認する。



## aiagent.sh に issue-status を足し、選択 UI と y/N 確認を共通関数へ寄せる
id: 19
branch-slug: aiagent-issue-status-and-shared-menu
github_issue: 56
status: close
type: feat
対象: zsh/functions/menu.sh (新規), zsh/functions/aiagent.sh, zsh/common.nix, zsh/README.md, docs-agents/issue-driven-workflow.md, docs-agents/issue-driven-workflow.en.md
内容: 公開している Issue 駆動ワークフローには、フローのどの段に球があるかを見る手段が無い。README の Role Separation 節が「実際には複数の worktree と相談者セッションが同時に走る」と書いている一方で、走っている worktree と未マージのブランチを一覧する関数が公開されていない。`issue-status` を足し、あわせて関数ごとに割れている選択 UI と y/N 確認を共通の `_pick` / `_confirm` に寄せる。
確認: `zsh -n` で `zsh/functions/menu.sh` と `zsh/functions/aiagent.sh` の構文確認（`nix flake check` は CI が回す）。加えて `aiagent.sh` 内の `_aiagent_confirm` 呼び出しがすべて置換済みであることを grep で確認する。

---

### 保証
- 新たに宣言する保証:
  - `issue-status` は、カレントリポジトリの `issues/` 直下から `status: draft` と `status: open` の件数を数え、`claude/*` の worktree と main に未マージの `claude/*` ブランチをパス・コミット数つきで一覧する
  - `issue-status` は git リポジトリ外で実行されたとき、エラーメッセージを stderr に出して非ゼロで終わる
  - `_confirm` は Enter だけを押されたとき第2引数の既定値（省略時は `n`）に倒す。標準入力が読めない（非対話・Ctrl-D）ときも既定値に倒し、ハングしない
  - `issue()` / `issue-open()` の選択候補と `issue-status` の件数から `00_template.md` を除外する
- 維持する保証:
  - `issue` / `issue-abort` / `issue-finish` / `issue-open` / `issue-import-pr` の既存の振る舞いを変えない（worktree の隔離作成、push・PR 作成を `issue-finish` だけが行う、`.wt` 配下の残骸掃除）
  - macOS (nix-darwin) と Linux (NixOS) の両エントリポイントから同じ実装が読まれる。`_aiagent_sed_inplace` の BSD / GNU 吸収を残す
  - 台帳は `issues/` 単一のままとする。稼働側にある backlog-md 台帳アダプタは持ち込まない

**テスト欠落について（user の裁可が要る）**: 上記の新保証はシェル関数の外から観測できる契約だが、本リポに zsh を対象にしたテスト基盤が無く、`docs/guarantees.md` も存在しない。既存の `zsh/functions/*.sh` も同じ扱い（CI は `zsh -n` の構文確認まで）。本 Issue では静的確認に留める。

---

### zsh/functions/menu.sh（新規）

選択 UI と y/N 確認の共通実装を置く。既存の各関数が fzf 呼び出しと `read` を個別に書いているため、既定値（Enter だけ押したとき）と Esc / Ctrl-C の扱いが関数ごとに割れる。破壊的な操作でどちらに転ぶか読めなくなるので1本に寄せる。

```sh
# 使い方:
#   choice=$(_pick "prompt" "key1<TAB>label1" "key2<TAB>label2") || return 1
# key と label はタブ区切り。選ばれた key だけが stdout に出る。
_pick() {
  emulate -L zsh
  local prompt="$1"
  shift

  local sel
  sel=$(printf '%s\n' "$@" \
    | fzf --prompt="${prompt}> " \
          --delimiter=$'\t' --with-nth=2..) || return 1
  [[ -z "$sel" ]] && return 1

  printf '%s\n' "${sel%%$'\t'*}"
}

# 使い方:
#   _confirm "delete branch?" || return 0     # 既定 No
#   _confirm "continue?" y || return 0        # 既定 Yes
_confirm() {
  emulate -L zsh
  local msg="$1"
  local default="${2:-n}"

  local hint="[y/N]"
  [[ "$default" == [yY] ]] && hint="[Y/n]"

  local ans
  print -n "${msg} ${hint}: "
  # 読み取り自体が失敗する（Ctrl-D / 非対話）ときは既定値に倒す
  read -r ans || ans=""
  [[ -z "$ans" ]] && ans="$default"

  [[ "$ans" == [yY]* ]]
}
```

`--height` / `--reverse` / 配色は `programs.fzf` の既定に任せ、ここには書かない。

### zsh/common.nix

`functions/menu.sh` を `functions/utils.sh` より **前** に読み込む。`_pick` / `_confirm` は他の関数ファイルから呼ばれる土台なので、読み込み順で先に定義されている必要がある。

### zsh/functions/aiagent.sh

1. **`_aiagent_confirm` を削除し、呼び出しをすべて `_confirm` へ置き換える。** 現行の `_aiagent_confirm` は既定値の引数を取らず、標準入力が読めないときの扱いも持たない。置き換えにあたり、各呼び出し箇所で現行の挙動（Enter が No）が保たれるよう既定値を指定する。破壊的な操作（worktree 破棄・ブランチ削除）は必ず既定 `n` のままにすること。

2. **`_aiagent_is_template` を足す。** `00_template.md` は `status: draft` を持つが着手対象ではないため、候補にも件数にも混ぜない。

```sh
_aiagent_is_template() {
  [[ "${1:t}" == "00_template.md" ]]
}
```

`_aiagent_select_issue` / `_aiagent_select_draft_issue` のループ先頭でこれを呼んで `continue` する。

3. **件数と一覧の関数を足す。**

- `_aiagent_count_status <draft|open>` — リポルートの `issues/` 直下を走査し、`head -n 15` で frontmatter を見て `status:` が一致するものを数える（既存の選択関数と同じ判定方法を使う）。git リポジトリ外では `0` を返す
- `_aiagent_count_worktrees` — `git worktree list --porcelain` の `branch refs/heads/claude/*` を数える
- `_aiagent_count_unmerged` — `git branch --no-merged main` のうち `claude/` で始まるものを数える

稼働側は複数の `issues/` ディレクトリを束ねる台帳アダプタ層を持つが、**本リポには持ち込まない**。走査対象はリポルート直下の `issues/` 1本に固定する。

4. **`issue-status` を足す。** 出力はフローの段の順（draft → open → worktree → unmerged）に並べ、件数の下にそれぞれの内訳を字下げして出す。worktree は `claude/*` のブランチ名とパス、unmerged は `main..{branch}` のコミット数を添える。

出力例:

```
issue status — dotfiles-public
  draft    1
  open     2
           19_aiagent-issue-status-and-shared-menu.md
           20_xxxx.md
  worktree 1
           claude/19-aiagent-issue-status  (/home/user/dotfiles-public.wt/19)
  unmerged 1
           claude/18-module-guide-judgment  (3 commits)
```

`issue-status` は読み取り専用で、`issues/` にも git にも書き込まない。

### zsh/README.md

「## 関数」の表の `functions/aiagent.sh` 行に `issue-status` を足し、`functions/menu.sh` の行を新設する（`_pick` `_confirm`（選択 UI と y/N 確認の共通実装））。「### 公開範囲」の「そのうち Issue 駆動ワークフローに直接必要な4本」を5本に直す。

### docs-agents/issue-driven-workflow.md / .en.md

`## シェル関数` 節に `### issue-status` を足す。`issue` の直前に置く（フローに入る前に現在地を見る関数なので）。書くのは「何を一覧するか」と「読み取り専用であること」までで、実装は書かない。英語版は日本語版の従属物として同じ構成で追随させる。
