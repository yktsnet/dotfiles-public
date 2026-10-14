## PR記録: chore: 日本語の校正を Stop フックからコミット前の手順へ移す
issue: 31 (31_proofread-before-commit.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/91

## 変更内容
- Stop / UserPromptSubmit の配線と `jp-proofread-{stop,run,notice}.sh`・テスト3本を外した
- `_aiagent_wt_clean` から校正の終わりを待つループを外し、`aiagent-wt-clean.test.sh` を未コミットの判定のケースだけにした
- `common.md` に「日本語の文書はコミットの前に校正させる」を足し、pr-workflow 手順6から引いた
- jp-proofreader の description と、README（日・英）の仕組みの段落を呼ばれ方に合わせた

稼働側で済ませた同じ変更の写し。Issue 31 は相談者の開放チャットで、user の指示による例外として実装した。

## 理由
Stop フックは比べる相手を HEAD に取っていたため、同じターンでコミットまで済ませると差分が無く、校正が起動しなかった。コミットの前に書き手が呼べば漏れが無く、比べる相手もブランチの分岐元に定まる。

## 保証
- 維持: `_aiagent_wt_clean` は未コミットの変更が残る worktree を畳まず、変更の一覧を出して失敗で返す → `.claude/hooks/tests/aiagent-wt-clean.test.sh`
- 廃止: Stop フックによる裏の校正と結果の受け渡し、`_aiagent_wt_clean` の校正待ち（`jp-proofread-*.test.sh` 3本を削除、待ちのケースを外した）

## 静的確認結果
- `hooks/tests/*.test.sh` 5本全通過
- `jq . .claude/settings.json` 通過、settings.json が参照するフックは全て存在
- `zsh -n` 通過、`nix flake check` 通過
- `jp-proofread` の grep は `issues/` 以外で校正役の名前 `jp-proofreader` だけ
- 変更した日本語の .md は jp-proofreader に通し、直し無し

## 確認者の判定
確認者（issue-verifier）は通していない。開放チャットでの例外の実装のため。

## 検証手順
`home-manager switch` で配布した後、日本語の .md を書き換えたセッションでターンを終えても、裏の校正が起動しないこと（実機。user が実施）

---

## 日本語の校正を Stop フックからコミット前の手順へ移す
id: 31
branch-slug: proofread-before-commit
status: close
type: cleanup
対象: .claude/settings.json, .claude/hooks/jp-proofread-stop.sh (削除), .claude/hooks/jp-proofread-run.sh (削除), .claude/hooks/jp-proofread-notice.sh (削除), .claude/hooks/tests/jp-proofread-stop.test.sh (削除), .claude/hooks/tests/jp-proofread-run.test.sh (削除), .claude/hooks/tests/jp-proofread-notice.test.sh (削除), .claude/hooks/tests/aiagent-wt-clean.test.sh, home-manager/modules/zsh/functions/aiagent.sh, .claude/agents/jp-proofreader.md, .claude/skills/pr-workflow/SKILL.md, home-manager/config/claude/common.md, README.md, README.en.md
内容: 書き換えた日本語の .md を Stop フックが裏で校正役へ回す仕組みをやめ、コミットの前に書き手のセッションが `jp-proofreader` を呼ぶ手順に置き換える。稼働側（dotfiles）で同じ変更を済ませてあり、その一般化した写しに揃える。
対象外: jp-proofreader の規範の読み方・直す範囲・モデルの変更。Issue / PR の本文を校正の対象に加えること
仮定: 稼働側の変更（Stop / UserPromptSubmit の配線とフック3本の撤去、`_aiagent_wt_clean` の待ちの撤去、common.md の節の追加、pr-workflow 手順6の追記、校正役の description の書き換え）を、そのまま公開側の正とする
確認: `for t in .claude/hooks/tests/*.test.sh; do bash "$t"; done` が全て通る。`jq . .claude/settings.json` が通り、settings.json が参照するフックが全て存在する。`zsh -n home-manager/modules/zsh/functions/aiagent.sh` が通る。`jp-proofread` と `Stop フック` の grep が `issues/` 以外で0件。`nix flake check` が通る
人が見るもの: `home-manager switch` の後、日本語の .md を書き換えたセッションでターンを終えても裏の校正が起動しないこと（実機）

---

### 保証
- 新たに宣言する保証: なし（手順の追加は規約で、テストで固定できない）
- 維持する保証: `_aiagent_wt_clean` は、未コミットの変更が残る worktree を畳まず、変更の一覧を出して失敗で返す。ほかのフックの配線とテストの結果は変わらない
- 廃止する保証: Stop フックが書き換えた日本語の .md を裏で校正に回すこと、結果を次のターンで渡すこと、`_aiagent_wt_clean` がその worktree を対象に走っている校正の終わりを待つこと（`jp-proofread-*.test.sh` 3本は削除し、`aiagent-wt-clean.test.sh` は待ちのケースを外して未コミットの判定のケースだけを残す）

### 理由
Stop フックは、比べる相手を git の HEAD に取っていた。書き手が同じターンでコミットまで済ませると、ターンの終わりには差分が無く、校正が起動しない。PR を通る作業は必ずコミットを経るので、コミットの前に書き手が呼べば漏れが無く、比べる相手もブランチの分岐元に定まる。

### .claude/settings.json
`hooks.Stop` と `hooks.UserPromptSubmit`（どちらも jp-proofread の1本だけ）を外す。

### home-manager/modules/zsh/functions/aiagent.sh
`_aiagent_wt_clean` から、`jp-proofread` の状態を見て待つループと `state_dir` を外す。関数の上のコメントは「未コミットの変更が残っていれば畳まない」だけにする。

### home-manager/config/claude/common.md
「ブランチは worktree で切る」の後に「日本語の文書はコミットの前に校正させる」の節を足す。中身は次のとおり。
- 日本語の Markdown を書き換えたら、コミットの前に `jp-proofreader` を呼ぶ。リポが校正の手順を持つならそちらに従う
- 渡すのは、`git merge-base HEAD origin/main` から書き換えた日本語の `.md` のパスと、`git diff -U0` の hunk 見出しから取った行の範囲
- `issues/` の Issue ファイルと、Issue / PR の本文は渡さない
- 直しを読み、意図を変えた直しは戻してからコミットする

### .claude/skills/pr-workflow/SKILL.md
手順6の先頭に「日本語の `.md` を書き換えたなら、共通ガイドの節に従って `jp-proofreader` に校正させる。そのあと `git add`…」を足す。

### .claude/agents/jp-proofreader.md
description の「Stop フックが会話の外で自動的に回すので、会話からは呼ばない」を「日本語の .md を書き換えたら、コミットの前に書き手のセッションが呼ぶ」に替える。Write を持たせない理由のコメントは「全体を書き直させず、直した箇所だけを差分に残すため」に、行の範囲の括弧書きは「呼び出し元は、ブランチで書き換えた行だけを渡してくる」に替える。

### README.md / README.en.md
「仕組み」の段落末の、Stop フックが校正役へ回す一文を、コミットの前に書き手が校正役を呼ぶ旨へ書き換える。「subagent を呼ぶことも、頼まずに仕組みに置く」の文は、校正が手順側へ移るので段落の流れに合わせて直す。英語版も同じ。
