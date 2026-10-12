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
