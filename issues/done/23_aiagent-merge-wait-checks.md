## PR記録: fix: `i` の merge で、必須チェックが通ってマージされるまで待つ
issue: 23 (23_aiagent-merge-wait-checks.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/78

## 変更内容
`_aiagent_merge` で `gh pr merge --squash` が拒まれたとき（必須チェックが未完了）だけ、次の順で進める。
1. `gh pr merge --squash --auto` で auto-merge に切り替える
2. `gh pr checks --watch --fail-fast` でチェックの完了を待つ。落ちたら `--disable-auto` で外して止まる
3. `gh pr view --json state` を5秒おきに見て、MERGED になるまで最長3分待つ。超えたら止まる

MERGED を確認してから後片付け（`_aiagent_reap`）と main の追従に進む。即時マージが通るときの流れは変えない。
docs/issue-workflow.md の `merge` の行に、待ち合わせと、落ちたときの動きを足した。

## 保証
- 即時マージが拒まれたら auto-merge に切り替えてチェックを待ち、MERGED 後に後片付けへ進む: なし（自動テストは無い。user が CI 実行中の PR を `i` の merge で選んで確かめる）
- チェックが落ちたら auto-merge を外して止まる: なし（同上）
- チェック通過後3分で MERGED にならなければ止まる: なし（同上）
- 維持: 即時マージが通るときは従来どおり: なし（同上）
- 維持: merge は `_confirm` を経てからしか動かない: なし（`_confirm` の位置は変えていない）

## 静的確認結果
- `zsh -n home-manager/modules/zsh/functions/aiagent.sh`: OK
- `nix flake check`: 評価エラーなし（既存の非推奨警告のみ）
- caller: `_aiagent_merge` の呼び出しは `i` の `merge)` 分岐のみ。シグネチャは不変

## 検証手順
実マージを伴うのでエージェント側では確かめていない。home-manager switch で反映したあと、
- CI が走っている PR を `i` の merge で選び、チェックの完了を待ってマージ・後片付け・main の追従まで進むこと
- チェックが落ちる PR で、auto-merge が外れて止まること（`gh pr view <PR> --json autoMergeRequest` が null）
を確かめる。

---

## `i` の merge で、必須チェックが通ってマージされるまで待つ
id: 23
branch-slug: aiagent-merge-wait-checks
status: close
type: fix
対象:
- home-manager/modules/zsh/functions/aiagent.sh（L466-476 の `_aiagent_merge`）
- docs/issue-workflow.md（L38 の `merge` の行）
内容: 本リポの main は ruleset で CI の通過を求めるので、`i` の merge を CI の途中で選ぶと `gh pr merge --squash` が「base branch policy prohibits the merge」で拒まれ、そこで止まる。user は CI が終わるのを見計らって `i` を開き直すしかない。旧 `issue-finish` が持っていた待ち合わせ（Issue 04）を `_aiagent_merge` に戻し、1回の操作でマージから後片付けまで済むようにする。
対象外: 即時マージが通るリポでの振る舞い。GitHub の画面でマージした分の後片付け（次の `i` が拾う、今のまま）。ruleset の見直し。
仮定: 待ち合わせの上限は旧実装と同じく、チェック通過後に MERGED になるまで3分とする。チェックが落ちたときは auto-merge を外す。旧実装は外していなかったが、有効のまま残すと直しを push した時点で確認なしにマージされるため。
確認: `zsh -n home-manager/modules/zsh/functions/aiagent.sh`、`nix flake check`。

---

### 保証
- 新たに宣言する保証:
  - 即時マージが拒まれたら auto-merge（squash）に切り替え、チェックの完了を待つ。チェックが通り、PR が MERGED になってから後片付けと main の追従に進む
  - チェックが落ちたら auto-merge を外し、その旨を出して止まる。後片付けはしない
  - チェック通過後3分たっても MERGED にならなければ、その旨を出して止まる
- 維持する保証:
  - 即時マージが通るときは、確認のあと squash でマージし、そのまま後片付けと main の追従まで済ませる
  - merge は確認（`_confirm`）を経てからしか動かない

自動テストは無い。user が CI の走っている PR を `i` の merge で選び、待ってからマージと後片付けまで進むことを確かめる。

### `_aiagent_merge`

`gh pr merge "$pr" --squash` が失敗したときだけ次へ進む。

1. `gh pr merge "$pr" --squash --auto`
2. `gh pr checks "$pr" --watch --fail-fast`。失敗したら `gh pr merge "$pr" --disable-auto` で外して止まる
3. `gh pr view "$pr" --json state` を5秒おきに見て、MERGED になるまで最長3分待つ

なぜ auto-merge に切り替えて待つのか（必須チェックで即時マージが拒まれる）と、なぜ落ちたら外すのかを、コメントで短く残す。旧実装はリポの履歴（Issue 04 のマージ時点の `_aiagent_finish`）にある。

### docs/issue-workflow.md

`merge` の行に、必須チェックのあるリポではチェックが通ってマージされるまで待つこと、落ちたら auto-merge を外して止まることを足す。
