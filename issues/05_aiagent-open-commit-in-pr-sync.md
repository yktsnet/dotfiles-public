## aiagent.sh: issue open コミットのブランチ同乗化を private 側から同期
id: 05
skill: pr-workflow
branch-slug: aiagent-open-commit-in-pr-sync
github_issue: 21
status: close
type: feat
対象:
- zsh/functions/aiagent.sh（`_aiagent_run()` の issues コミット処理 L269-293 付近と `_aiagent_finish()` の main 事前 push・pull 前処理）
内容: private 側（~/dotfiles Issue 16）で実装した「`chore(issues): open` コミットを main 直積みからワークツリーブランチ同乗に変更」を公開ミラーに移植する。これにより main は Issue 1件あたり「squash された実装（issue ファイル込み）」＋「close chore」の2コミットになり、open 分の main 直 push（保護ルールバイパス）も解消される。移植元 diff は本ファイル末尾に記載済みのため、private リポを参照する必要はない。
確認: `zsh -n zsh/functions/aiagent.sh`。実マージを伴う動作確認は user が次回の issue()〜issue-finish で行う
---
## 変更の要点（3箇所）

1. `_aiagent_run()`: main 上での `chore(issues): open` コミット（`issues_rel_path` を add する既存処理）を削除し、`git worktree add` 後に issue ファイル1本だけを worktree へ `cp` して**ブランチ上で**コミットする。main 側では untracked のまま残す。
2. `_aiagent_finish()`: PR 作成前の `git push origin main || return 1` とそのコメントを削除する。
3. `_aiagent_finish()`: squash マージ後の `git pull --prune` 直前に、head_branch の id に一致し untracked（`??`）な issue ファイルを削除する処理を追加する（マージ後に origin 由来の tracked ファイルとして戻るため）。あわせて `issues_dir` の定義を関数冒頭へ前倒しし、後方の重複定義を削除する。

## 移植元 diff（~/dotfiles zsh/neo/aiagent.sh、コメント含めそのまま適用してよい）

```diff
@@ _aiagent_finish() 冒頭
   local base
   base=$(git rev-parse --show-toplevel)
+  local issues_dir="$base/issues"
   local close_file=""
   local head_branch=""
@@ PR 作成前
       pr_title=$(git log -1 --format='%s' "$head_branch")
       pr_body=$(git log -1 --format='%b' "$head_branch")
-      # issues/ の open コミットを先に main に載せ、PR diff に混ぜない
-      git push origin main || return 1
       git push -u origin "$head_branch" || return 1
@@ squash マージ成功後、git pull --prune の直前
+      # squash マージ後の pull は、main 側に残る untracked の issue ファイルと衝突する
+      # （マージ後は origin 由来の tracked ファイルとして戻ってくるため、pull 前に退避する）
+      local merge_pid=""
+      [[ "$head_branch" =~ ^claude/([0-9]+[a-z]?)- ]] && merge_pid="${match[1]}"
+      if [[ -n "$merge_pid" ]]; then
+        local f
+        for f in "$issues_dir"/*.md(N); do
+          [[ -f "$f" ]] || continue
+          grep -q "^id: ${merge_pid}$" "$f" || continue
+          [[ "$(git status --porcelain -- "$f")" == '??'* ]] && rm -f "$f"
+        done
+      fi
+
       if ! git pull --prune; then
@@ _aiagent_sweep_wt 呼び出し後
-  local issues_dir="$base/issues"
-
@@ _aiagent_run()
-  local issues_rel_path
-  if [[ "$git_root" == "$PWD" ]]; then
-    issues_rel_path="issues/"
-  else
-    issues_rel_path="${rel_path}/issues/"
-  fi
@@ _aiagent_confirm 後
-  # issues/ をコミット（worktree ブランチに issue を含める。push は issue-finish が PR 作成前に行う）
-  if [[ -n "$(git status --porcelain -- "$issues_rel_path")" ]]; then
-    git add "$issues_rel_path"
-    git commit -m "chore(issues): open $(basename "$issue_file")"
-  fi
-
   # worktree に隔離して実行（main のチェックアウトを汚さない・並列実行可）
   git worktree add "$wt_dir" -b "$branch_name" || return 1

   local wt_app_dir="$wt_dir"
   [[ "$git_root" != "$PWD" ]] && wt_app_dir="${wt_dir}/${rel_path}"

+  # issue ファイル（main 側では untracked のまま）をブランチにコピーしてコミットする。
+  # 各ブランチ上でのみ open コミットを行うことで、main 直積みに伴う並行 Issue の混入や
+  # 後発ブランチへの先発 open コミットの混入を防ぐ
+  local issue_file_rel="${issue_file#${git_root}/}"
+  if [[ -n "$(git status --porcelain -- "$issue_file")" ]]; then
+    cp "$issue_file" "${wt_dir}/${issue_file_rel}"
+    git -C "$wt_dir" add "$issue_file_rel"
+    git -C "$wt_dir" commit -m "chore(issues): open $(basename "$issue_file")"
+  fi
+
```

## 移植時の注意

- 本リポの aiagent.sh は private 側と行番号・周辺コードが完全一致とは限らない（例: `pr_merge_sha` 関連の行の有無）。diff の文脈行に固執せず、上記「変更の要点」の3箇所に対応する位置へ適用する。
- 適用後、squash マージ化（適用済み）を含む `_aiagent_run` / `_aiagent_finish` の全体構造が private 側と同じ流れになっていることを目視確認する。
- `issue-abort` は変更しない。
