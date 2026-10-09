## PR記録: feat: ブランチ切り替えとメモリ書き込みのガードを足し、エージェントのモデルを ID で固定する
issue: 28 (28_guards-and-model-ids.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/85

## 変更内容
- `no-branch-in-checkout.sh` を追加。元のチェックアウトでブランチを作る・切り替える `git switch` / `git checkout` を拒否し、worktree を作るコマンドを拒否文で案内する。main へ戻ることと `--` 付きのファイル復元は通す。回帰テスト `tests/no-branch-in-checkout.test.sh` を併せて追加
- `gate-memory-write.sh` を追加。`~/memory/`（実体 `~/dotfiles/memory/` を含む）への Edit・Write と、Bash のリダイレクト・tee・cp・mv・install・rm・sed -i・perl -pi で user の承認（ask）を求める。宛先が `~/memory` のようにディレクトリそのもので末尾に `/` が無い形も捕まえる。テスト `tests/gate-memory-write.test.sh` を追加
- `.claude/settings.json` の PreToolUse に2本を登録（ブランチ側は Bash、メモリ側は Edit|Write|Bash）
- subagent の `model:` を別名から ID に固定（`opus` → `claude-opus-5-5`、`sonnet` → `claude-sonnet-5-5`）
- `i` が起こす実行者の引数を `--model claude-sonnet-5-5 --effort high` にする
- Issue の保証節を、フックが実際に捕まえる Bash の書き込み形に絞った（touch・mkdir・ln・dd・インタプリタ経由は対象外）。対象に `gate-memory-write.test.sh` を足した

## 保証
- 元のチェックアウトで `git switch`・`git checkout` によるブランチの作成・切り替えは止まり、main へ戻ることと `--` 付きの復元は通る → `.claude/hooks/tests/no-branch-in-checkout.test.sh`
- `~/memory/` への書き込み（Edit・Write と、Bash のリダイレクト・tee・cp・mv・install・rm・sed -i・perl -pi）は承認を求める → `.claude/hooks/tests/gate-memory-write.test.sh`
- worktree の中でのブランチ操作は止めない（維持）→ `no-branch-in-checkout.test.sh` の「通す: worktree」

## 静的確認結果
- `for t in .claude/hooks/tests/*.test.sh; do bash "$t"; done`: すべて通過
- `zsh -n home-manager/modules/zsh/functions/aiagent.sh`、`jq . .claude/settings.json`、`nix flake check`: 通過
- `grep -rn '^model:' .claude/agents/`: すべて ID
- 追加ファイルに会社名・ホスト名なし

## 検証手順
rebuild のあと次を確認する。
- 元のチェックアウトで `git switch -c x` が止められ、拒否文に worktree を作るコマンドが出ること。worktree の中では通ること
- `~/memory/` への書き込みで承認を求められること
- `i` で起こした実行者が `claude-sonnet-5-5`・effort high で立ち上がること

## 検収
| 確認・保証 | 判定 |
|---|---|
| hook テスト全件・`zsh -n`・`jq`・`nix flake check` | 合 |
| `model:` が ID、追加ファイルに会社名・ホスト名なし | 合 |
| 保証: 元のチェックアウトでのブランチ操作が止まる | 合 |
| 保証: `~/memory/` への書き込みで承認を求める（絞った文言） | 合 |
| 保証（維持）: worktree 内は止めない | 合 |

範囲の外（検収役の指摘）:
- 保証の文言を絞った件は user が裁可済み
- `gate-memory-write.sh` は稼働側から正規表現を広げている（`/memory` で終わるパスも ask になる）
- 前提の 27 は未マージ。テキスト上の衝突は無いが、27 を先にマージする場合は rebase してテストを流し直す

---

## ブランチの切り替えとメモリの書き込みのガードを足し、エージェントのモデルを ID で固定する
id: 28
branch-slug: guards-and-model-ids
status: close
type: feat
対象:
- .claude/hooks/no-branch-in-checkout.sh（新規）
- .claude/hooks/tests/no-branch-in-checkout.test.sh（新規）
- .claude/hooks/gate-memory-write.sh（新規）
- .claude/hooks/tests/gate-memory-write.test.sh（新規）
- .claude/settings.json（PreToolUse への登録）
- .claude/agents/issue-inspector.md・screen-operator.md（`model:`）
- home-manager/modules/zsh/functions/aiagent.sh（実行者のモデルと effort）
内容: 稼働側にあって公開側に無いガードが2つある。1つは、元のチェックアウトでブランチを作る・切り替える `git switch`・`git checkout` を止めるフックである。2つのセッションが同じチェックアウトで切り替えると、未コミットの変更が互いのブランチへ運ばれて混ざる。もう1つは、永続メモリ（`~/memory/`）への書き込みに user の承認を挟むフックである。対話の流れで勝手に増えるのを止める。あわせて、subagent の定義のモデルを別名から ID に固定する。別名は版ごとの解決先に従い、新しい世代へ自動では上がらない。`i` が起こす実行者のモデルも、稼働側の `claude-sonnet-5-5 --effort high` に合わせる。
対象外: README.md・README.en.md（29 で扱う）。tmux のエージェント表示（稼働側は状態ごとの件数にしたが、今回は扱わない）。会社のリポ向けの関数とフック。
仮定: `gate-memory-write.sh` は、稼働側では `~/memory/` と実体の置き場の両方の綴りを見ている。公開側では `memory.nix` が置く実体の置き場に合わせて書き換える。27 と同じ `settings.json` と `aiagent.sh` に触れるので、27 のあとに実装する。
確認: `for t in .claude/hooks/tests/*.test.sh; do bash "$t"; done` がすべて通る。`zsh -n home-manager/modules/zsh/functions/aiagent.sh` が通る。`jq . .claude/settings.json` が通る。`nix flake check` が通る。`grep -rn '^model:' .claude/agents/` がすべて ID になっている。追加したファイルに会社名・ホスト名が無い。
人が見るもの: rebuild のあと、元のチェックアウトで `git switch -c` が止められ、`~/memory/` への書き込みで承認を求められること（実機）。

---

### 前提
- 27 がマージされていること（`settings.json` と `aiagent.sh` を続けて触るため）

### 保証
- 新たに宣言する保証:
  - 元のチェックアウト（worktree でない側）で、ブランチを作る・切り替える `git switch`・`git checkout` は止まる。main へ戻ることと、`--` を付けたファイルの復元は通る
  - `~/memory/` への書き込み（Edit・Write と、Bash のリダイレクト・tee・cp・mv・install・rm・sed -i・perl -pi）は、user の承認を求める。touch・mkdir・ln・dd・インタプリタ経由の書き込みは対象外
- 維持する保証: worktree の中でのブランチ操作は止めない

### .claude/hooks/no-branch-in-checkout.sh とテスト・gate-memory-write.sh
稼働側を写す。止めた理由と正しい経路（worktree を作るコマンド）を拒否文に書く形は変えない。

### .claude/settings.json
PreToolUse に2本を、稼働側と同じ matcher・timeout・statusMessage で登録する。

### .claude/agents/
`model: opus` を `claude-opus-5-5`、`model: sonnet` を `claude-sonnet-5-5` にする。

### home-manager/modules/zsh/functions/aiagent.sh
実行者を起こす引数を `--model claude-sonnet-5-5 --effort high` にする。
