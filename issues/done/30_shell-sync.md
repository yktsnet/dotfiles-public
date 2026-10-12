## PR記録: chore: zsh 関数と home-manager を稼働側に追従させる
issue: 30 (30_shell-sync.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/89

## 変更内容
- aiagent.sh: 実行者の system prompt に「指摘の無い crit の Finish Review を PR を出す明示とみなす」を追加。`i` の fzf に C-o（エディタで開く）・折り返し・bat によるプレビューを足し、draft の裁可の前にエディタで全文を読ませて確認を挟む
- menu.sh: `_pick_multi`（Tab で複数選択する fzf ピッカー）を追加
- tmux.nix: status-right のエージェント表示を、エージェントごとのチップから状態別の件数（waiting / idle / busy）に変更。M-u の説明コメントを実態（起動は c() に一本化）に合わせた
- ctx.nix: daemon を有効にする `~/.ctx/config.toml` を宣言
- common.md: 応答の言語、コメント/実行時メッセージの言語規則、経緯を永続メモリに置く規則、worktree でブランチを切る節、memory-write への参照を追加

持ち込まない差は Issue のとおり: 横断リポの `AIAGENT_REPO_ROOTS` と issues/ の場所、会社面、ホスト名、`~/github-corp/` の節。
tmux.nix のうち、公開範囲を絞った際に外した pane 格子・スクラッチ popup・sessionizer・基本設定とテーマ・コピー設定は戻していない（user と合意）。

## 保証
なし（公開側は clone して適用する想定がなく、確かめられるのは評価と構文まで。挙動は稼働側で確かめ済み）

## 静的確認結果
- `zsh -n` aiagent.sh / menu.sh: ok
- `nix flake check`: ok（darwinConfigurations.macbook）
- `nix eval .#nixosConfigurations.linux-desktop.config.system.build.toplevel.drvPath`: ok
- tmux.nix の jq フィルタを waiting / shell / busy / status なしの入力で実行し、3 状態の件数が出ることを確認
- `git diff --name-only --cached`:
  - home-manager/config/claude/common.md
  - home-manager/modules/ctx.nix
  - home-manager/modules/tmux.nix
  - home-manager/modules/zsh/functions/aiagent.sh
  - home-manager/modules/zsh/functions/menu.sh

## 検証手順
- 各デバイスで `home-manager switch`（または `darwin-rebuild` / `nixos-rebuild`）を適用し、tmux の status-right が件数表示になること、`~/.ctx/config.toml` が生成されることを確認する
- `i` で C-o と draft の裁可前のエディタ表示が動くことを確認する


## 確認者の判定
| 確認 | 判定 |
|---|---|
| aiagent.sh の差が持ち込まない差だけ | 合 |
| menu.sh（`_pick_multi`） | 合 |
| tmux.nix | 否（公開範囲を絞った際に外した部分を戻さないことは user と合意済み。Issue の「持ち込まない差」には未記載） |
| ctx.nix | 合 |
| common.md | 合 |
| `nix flake check` | 合 |
| `zsh -n`（aiagent.sh・menu.sh） | 合 |
| 保証 | なし（Issue どおり） |

---

## zsh 関数と home-manager を稼働側に追従させる
id: 30
branch-slug: shell-sync
status: close
parent: dotfiles-fe
type: cleanup
対象: home-manager/modules/zsh/functions/aiagent.sh, home-manager/modules/zsh/functions/menu.sh, home-manager/modules/tmux.nix, home-manager/modules/ctx.nix, home-manager/config/claude/common.md
内容: 公開の基準（`.claude/skills/README.md`）に従い、Issue 駆動の入口 `i` とセッション管理まわりを稼働側 `~/dotfiles/` に追従させる。対応する稼働側は `zsh/functions/aiagent.sh`・`zsh/functions/menu.sh`・`home-manager/modules/tmux.nix`・`home-manager/modules/ctx.nix`・`home-manager/config/claude/common.md`。
対象外: `.claude/` の追従（29）。`claude.nix`（公開側の `extraGuides` の方が進んでいる）。`os.sh`・`memory.nix`・`secrets-agents.nix`（差がコメントの一般化だけ）。`git.nix`・`crit.nix`（差が個人の設定と wsl 向けの分岐だけ）
仮定: なし
確認: 対象ファイルごとに稼働側との diff を取り、残る差が下の「持ち込まない差」だけになる。`nix flake check` が通る。`zsh -n` が aiagent.sh と menu.sh で通る
人が見るもの: なし

---

### 保証
保証: なし（公開側は clone して適用する想定がなく、確かめられるのは評価と構文まで。挙動は稼働側で確かめ済み）

### 持ち込まない差（全ファイル共通）
- aiagent.sh: 横断するリポを `AIAGENT_REPO_ROOTS` で受ける形、issues/ の場所を1つに決める形（dotfiles の `apps/*/issues` を見ない）は公開側のまま残す
- 会社面: `~/github-corp/`、`~/.claude-corp`、Backlog.md 台帳のリポの除外
- 個人の運用: ホスト名、稼働側だけにある関数・アプリへの依存
- common.md: 「`~/github-corp/` 配下の扱い」節、機密マスクの辞書の実パス

### 取り込むもの
- aiagent.sh: `i` で候補を出し、複数選べば並行で起動する流れ、crit の段取り、ほか稼働側で進んだ分
- menu.sh: `_pick_multi`（aiagent.sh が使う）
- tmux.nix: 稼働側で進んだ分（実行者の隠しセッション・ステータス表示など）
- ctx.nix: daemon を有効にする `~/.ctx/config.toml` の宣言（`~/.claude-corp` に触れる注釈は外す）
- common.md: 応答の言語、実行時メッセージを英語で書く規則、経緯を永続メモリに置く規則
