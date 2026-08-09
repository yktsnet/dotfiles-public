## 並列セッションを横から観測・介入する層（session-nudge）を公開する
id: 11
branch-slug: multi-session-nudge
github_issue: 37
status: close
type: feat
対象:
- home-manager/modules/tmux.nix
- .claude/skills/session-nudge/SKILL.md (新規)
- zsh/functions/claude.sh
- docs/tui_environment.md
- README.md
- README.en.md
内容: 私物 `~/dotfiles` で動いている「別の稼働中セッションを外から客観視して、必要なら cross-session messaging で気づきを送る」仕組みを本リポへ反映する。本リポの Role Separation は「1 Issue = 1 worktree = 1 エージェント」で閉じており、複数セッションが同時に走っている状態を扱う記述が無い。M-y / M-Y / M-u（起動とピッカー）まではすでに公開済みなので、その上に乗る観測・介入の層だけを足す。
確認: `nix flake check`（評価エラーの検出）、`zsh -n zsh/functions/claude.sh`（構文チェック）、目視確認（`docs/tui_environment.md` のキーバインド表と `tmux.nix` の bind-key の一致、README 日英の記述内容の一致）。実際のポップアップ動作確認は user が macbook / linux-desktop で行う。

---

### 保証
- 新たに宣言する保証:
  - `hasClaudeSessionManager` が偽のホスト（サーバ系）では `M-m` の bind-key が設定されない。既存の `M-y` / `M-Y` / `M-u` と同じ条件分岐に入れる
  - 対象セッションの一覧から、呼び出し元のセッション自身は必ず除外される
  - 対象セッションが1つも見つからない場合、メッセージを表示して終了する（fzf が空リストで開いたままにならない）
  - `session-nudge` は対象セッションへ送信する前に必ず文案を user に提示する。user の承認なしに `SendMessage` を実行しない
  - `zsh/functions/claude.sh` に追加する2関数は、選択肢以外の入力を受けたとき何も起動せず終了する
- 維持する保証:
  - `M-y` / `M-Y` / `M-u` の既存の挙動（押すたびに新規セッションを隠しセッションとして起動し popup でアタッチ、離脱後も継続、`M-u` から復帰）を変えない
  - `zsh/functions/claude.sh` の既存関数 `skill()` の挙動を変えない
  - `docs/tui_environment.md` の既存キーバインド表の記述を変えない（追記のみ）

**テスト欠落について（裁可済み・見送る）**: 上記のうち「呼び出し元の除外」「候補ゼロ時の終了」「送信前の承認」は外部から観測可能な契約だが、対象が tmux 設定・シェル関数・skill 本文であり、検証には実行環境（tmux セッションと稼働中の Claude）が要る。妥当なテスト手段が無いため裏付けテストを含めない。既存の `zsh/functions/*.sh` も同様に `zsh -n` の構文チェックのみで運用している。

### 背景

本リポの README は Role Separation を「WebChat（設計）／ AI Agent（実装）／ User（裁可）」の3ロールで説明し、`issue` / `issue-abort` / `issue-finish` で受け渡す形にしてある。これは1本の Issue を1本のエージェントが処理する流れの説明であり、**複数の Issue を並列で走らせている最中に何が起きるか**には触れていない。

実運用では `issue` を複数回叩いて worktree を複数立て、同時に相談者セッションも開いている。この状態で問題になるのは「あるセッションが方向を外していることに、そのセッション自身は気づけない」ことで、同じモデル・同じ規則で動いている以上、内部から検出できない。外部の読み手を用意するしかない。

私物側ではこれを tmux のポップアップとして実装している。`M-m` を押すと、走っている対話セッションの一覧が fzf で出る。各行にはセッション名・状態・リポ名・そのセッションが何の話をしているか（トランスクリプト冒頭の最初の実ユーザー発言）が並び、プレビュー枠に直近の会話が流れる。選ぶと専用の Claude が popup で起動し、`session-nudge` skill の手順に入る。

### 仕様

#### home-manager/modules/tmux.nix

現状の `let` には `claudeSessionManager` / `claudeLaunchVariant` / `termPopup` / `sessionizer` / `agentStatus` がある。ここに2つ足し、`hasClaudeSessionManager` の分岐（現在 `M-y` / `M-Y` / `M-u` が入っている `lib.optionalString` ブロック）に bind を1つ足す。

**1. `nudgePreview`（新規、`sessionizer` の手前あたり）**

fzf のプレビュー枠に、選択中セッションの直近の会話を出す。引数は `sessionId` 1つ。

- トランスクリプトは `~/.claude/projects/<プロジェクト>/<sessionId>.jsonl` にある。**cwd からディレクトリ名を組み立てず glob で引くこと**（プロジェクト名への変換規則に依存させないため）
- `jq` で `user` / `assistant` の行だけ取り、`user` 発言に目印を付ける。content が文字列の場合と配列の場合の両方を扱う。配列内の `tool_use` はツール名だけ出す
- 空行と `<` で始まる行（system-reminder 等）を落とし、末尾60行を出す
- `sessionId` が空、またはファイルが見つからない場合は、その旨を1行出して正常終了する

**2. `nudgePickAndLaunch`（新規）**

対象セッションを fzf で選び、選んだ相手を引数に `session-nudge` を起動する。

- 候補は `claude agents --json` から `kind == "interactive"` のものを取り、`name` / `status` / `cwd` / `pid` / `sessionId` を使う
- **呼び出し元セッションを候補から外す。** `claude` のプロセス ID は tmux の `pane_pid`（シェル側の PID）と一致しないため、`ps -o ppid=` で親を辿って `tmux list-panes -a` の `pane_pid` と一致する pane を解決し、自分の pane と比較する
- 各行に「そのセッションが何の話か」を出す。トランスクリプト冒頭の**最初の実ユーザー発言**を見出しにする。冒頭にはスラッシュコマンド・system-reminder・添付・skill 本文が混ざるので、`<` 始まり・`/` 始まり・skill のヘッダ行を除外してから最初の1件を取り、48文字で切る
- 候補が0件なら「他に対話セッションが無い」旨を出し、入力を待って終了する（popup が即座に閉じて何も読めない状態を避ける）
- 選択後は `exec` で `claude` を起動し、`/session-nudge target=<選んだ name>` を渡す

起動時のフラグは次の形にする。判定と送信は確認を挟まず自走してよい作業なので Auto mode で起動する。

```
exec env CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 claude --model opus --effort medium --permission-mode bypassPermissions \
  "/session-nudge target=$target"
```

**3. `M-m` の bind（`hasClaudeSessionManager` ブロック内、`M-u` の次）**

```
bind-key -n M-m run-shell "${claudeLaunchVariant} nudge 90% 90% '#{q:pane_current_path}' ${nudgePickAndLaunch}"
```

`claudeLaunchVariant` をそのまま使う（隠しセッション化・popup アタッチ・二重起動防止の扱いを既存の `M-y` と共通にするため）。

**4. `M-y` / `M-Y` に `--permission-mode auto` を足す**

現状の2行には `--permission-mode` が付いていない。私物側は `auto` を明示している。同じ行に足すだけで、他は変えない。

#### .claude/skills/session-nudge/SKILL.md（新規）

コピー元: `~/dotfiles/.claude/skills/session-nudge/SKILL.md`（79行）。固有の接続情報を含まないためほぼそのまま移植できる。

移植にあたり次を守る。

- frontmatter の `disable-model-invocation: true` を残す（本リポの `block-new-skill-md.sh` が要求する）
- 「判定機ではない・判定表や長文分析を最初から出さない」という抑制の記述を削らない。この skill の要点は網羅性ではなく、**外から数行で見て user と話す状態に戻すこと**にある
- 「A の結論を根拠に使わない。A が見た一次情報に自分で当たる」の段落を削らない。観測側も同じモデルで動く以上、ここが唯一の担保になっている
- `ctx` を使わない理由（`ctx_events.occurred_at_ms` がインポート時刻で埋まり並べ替えに使えない）の記述を残す

#### zsh/functions/claude.sh

現状は `skill()` のみ。私物側の `zsh/common/claude.sh` から2関数を足す（`skill()` は既存のものと同一なので触らない）。

- `c()` — Claude の起動方法を番号で選ばせる。sonnet/medium、opus/low、履歴からの再開の3択。選択肢以外なら何も起動せず `return 1`
- `i()` — Issue ワークフローのどの段階かを番号で選ばせ、`issue-open` / `issue` / `issue-finish` / `issue-abort` へ振り分ける。選択肢以外なら何も起動せず `return 1`

`i()` が呼ぶ4関数は `zsh/functions/aiagent.sh` に既にある。`c()` の3択目が呼ぶ `claude-history` は本リポで公開済み（Issue 08）。

#### docs/tui_environment.md

「Claude Code 連携」相当のキーバインド表（現状 `Alt + y` / `Alt + Y` / `Alt + u` の3行がある箇所）に1行足す。既存行と同じ書式で、`macbook` / `linux-desktop` のみである旨も同じ書き方で入れる。

| `Alt + m` | 走っている別セッションを選び、外から客観視する相談セッションを popup で起動。`macbook` / `linux-desktop` のみ |

#### README.md / README.en.md

`## Role Separation（ロールの分離）` の節に、並列実行時の話を足す。現在この節は3ロールの定義とマクロ3つ、例外3経路で構成されている。その後ろ、`詳細は issue-driven-workflow.md を参照。` の手前に短い段落を1つ入れる。

含めること。

- ロール分離は1本の Issue の流れの話であり、実際には複数の worktree と相談者セッションが同時に走る
- 同じモデル・同じ規則で動くセッションは、自分が方向を外したことを自分では検出できない。外部の読み手を用意するのが `M-m`（`session-nudge`）である
- 送信は cross-session messaging で行うが、文案は必ず user が承認してから送る。自動で他セッションへ介入はしない

**長く書かない。** この節は既に長く、ロール定義とマクロの説明で密度が高い。段落1つ（3〜4文）に収め、詳細は `.claude/skills/session-nudge/SKILL.md` と `docs/tui_environment.md` へのリンクで済ませる。

`README.en.md` は `readme-i18n` skill の規約に従い、日本語版と同じ位置に同じ内容を置く。

### 実装順序

1. `.claude/skills/session-nudge/SKILL.md`（移植）
2. `home-manager/modules/tmux.nix`（`nudgePreview` → `nudgePickAndLaunch` → `M-m` bind → `M-y`/`M-Y` のフラグ）
3. `nix flake check`
4. `zsh/functions/claude.sh`（`c()` / `i()` 追加）と `zsh -n`
5. `docs/tui_environment.md`（表に1行）
6. `README.md` → `README.en.md`
