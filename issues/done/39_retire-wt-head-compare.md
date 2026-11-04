## PR記録: fix: マージ後の worktree を、PR の head と比べて片付ける
issue: 39 (39_retire-wt-head-compare.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/110

## 変更内容
- `_aiagent_retire_wt` が、未 push の判定で比べる先を `refs/remotes/origin/<branch>` から PR の `headRefOid` に変えた（`gh pr view --json state,headRefOid` で一度に取る）。マージ時にリモートのブランチを消すリポでは、`fetch --prune` のあとに比べる先が無くなり、マージ済みの worktree が毎回残っていた。不一致のときの文言は `has commits not in the PR.`
- `i()` の冒頭で、カレントディレクトリが消えていればホームへ移る。消えた worktree の中で呼ぶと、fzf のプレビューが getcwd で失敗していた

## 保証
- OPEN/MERGED で head が一致し、未コミットの変更が無ければ、追跡ブランチが無くても消す → aiagent-retire-wt.test.sh「追跡ブランチが無くても head が一致すれば消す」「OPEN でも head が一致すれば消す」
- head に無いコミットがあれば残し、その旨を出す → 同「head に無いコミットがあれば残す」「残した理由を出す」
- PR が無いか CLOSED なら残す → 同「PR が無ければ残す」「CLOSED なら残す」
- 未コミットの変更があれば残す → 同「未コミットの変更があれば残す」、aiagent-wt-clean.test.sh
- ブランチは消さない → 同「ブランチは消さない」
- `i` はカレントディレクトリが消えていればホームへ移る → 同「i はカレントディレクトリが消えていればホームへ移る」

## 静的確認結果
- `zsh -n home-manager/modules/zsh/functions/aiagent.sh`: OK
- `bash .claude/hooks/tests/aiagent-retire-wt.test.sh`: 9件すべて通過
- `bash .claude/hooks/tests/aiagent-wt-clean.test.sh`: すべて通過

## 検証手順
- 適用後に Issue を1本マージし、セッションを閉じたあと worktree が残らないこと
- worktree が消えたあとのシェルで `i` を呼び、fzf のプレビューに getcwd のエラーが出ないこと

## 確認者の判定
| 対象 | 判定 |
|---|---|
| `zsh -n aiagent.sh` | 合 |
| 新しいテスト（9件）・既存の aiagent-wt-clean.test.sh | 合 |
| 保証6件 | すべて合 |
| 範囲の外 | なし |

---

## マージ後の worktree を、PR の head と比べて片付ける
id: 39
branch-slug: retire-wt-head-compare
status: close
type: fix
対象: home-manager/modules/zsh/functions/aiagent.sh, .claude/hooks/tests/aiagent-retire-wt.test.sh (新規)
内容: `_aiagent_retire_wt` は、ローカルのブランチを `refs/remotes/origin/<branch>` と比べて未 push のコミットが無いかを見ている。本リポはマージ時にリモートのブランチを消す設定で、`_aiagent_pull_main` の `fetch --prune` のあとは比べる先が無くなるため、マージ済みの worktree が「未 push のコミットあり」と判定されて毎回残る。比べる先を PR の `headRefOid` に変える。あわせて、消えた worktree の中で `i` を呼ぶと fzf のプレビューが getcwd で失敗する問題を直す。
対象外: 実行者がセッション中にマージまで行う流れ（pr-workflow の手順11）と、マージ済みならブランチも消して main を追従させる処理。`i` の確認の省略や fzf のプレビュー配置の変更。Builder のモデル指定
仮定: dotfiles 側の同じ修正（`gh pr view --json state,headRefOid`）を下敷きにしてよい。テストは gh を関数で差し替えて流す
確認: `zsh -n home-manager/modules/zsh/functions/aiagent.sh` が通る。新規テストが CI と同じ呼び方（`bash .claude/hooks/tests/aiagent-retire-wt.test.sh`）で通り、既存の `aiagent-wt-clean.test.sh` も通る
人が見るもの: 適用後に Issue を1本マージし、セッションを閉じたあと worktree が残らないこと

---

### 保証
- 新たに宣言する保証:
  - PR が OPEN か MERGED で、ローカルのブランチの先頭が PR の head と一致し、worktree に未コミットの変更が無ければ、リモートのブランチが消えていても worktree を消す
  - ローカルのブランチに PR の head に無いコミットがあれば worktree を残し、その旨を出す
  - `i` は、カレントディレクトリが消えていてもホームへ移ってから一覧を出す
- 維持する保証:
  - PR が無いか CLOSED のブランチの worktree は消さない
  - 未コミットの変更がある worktree は消さない（`_aiagent_wt_clean` の判定、既存テスト）
  - ブランチは消さない（マージ後に `_aiagent_reap` が消す）

### aiagent.sh
- `_aiagent_retire_wt`（194行付近）: `gh pr view "$branch" --json state,headRefOid` で state と head を一度に取り、`git rev-parse "$branch"` を head と比べる。不一致の文言は `has commits not in the PR.` にする。コメントは、origin の追跡ブランチと比べない理由（マージ時にリモートのブランチを消すリポでは prune 後に参照が無くなる）に直す
- `i()`（548行付近）: 冒頭で `[[ -d "$PWD" ]] || cd ~`。理由のコメントを1行添える

### tests/aiagent-retire-wt.test.sh（新規）
`aiagent-wt-clean.test.sh` と同じく aiagent.sh を source し、一時リポで worktree を作って `_aiagent_retire_wt` を呼ぶ。`gh` は関数で差し替え、state と head を返させる。少なくとも次を確かめる: origin の追跡ブランチが無く head が一致すれば消える／head が不一致なら残る／state が CLOSED なら残る
