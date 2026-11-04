## マージ後の worktree を、PR の head と比べて片付ける
id: 39
branch-slug: retire-wt-head-compare
status: open
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
