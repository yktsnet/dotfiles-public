---
name: pr-workflow
description: Issueファイルに基づく実装から、user の動作確認を経て PR を出すまでの標準フロー。マージは user が行う
disable-model-invocation: true
---
以下の手順でissueを実行する。$ARGUMENTSにissueファイルのパスを渡す。
**前提: AI は実装してコミットし、止まって user の動作確認を受け、指摘をこのセッションで直す。user が OK を出したら、Issue を閉じて PR を出すまでが担当。マージは user が `i` か GitHub で押す。リモートへは自分のブランチを push するだけで、main には push しない。**

1. issueファイルを読む
2. `git status` で、ブランチが `claude/{id}-{branch-slug}` かつワーキングツリーがクリーンなことを確認する（ブランチとworktreeは `i` が作成済み）。違えば報告して止まる
3. 対象ファイルを読んで実装
   - Issue の「対象」と「内容」から外れる作業に気づいたら、手を付ける前に AskUserQuestion で「新しい Issue にする / この Issue の中で直す / 見送る」を聞く。黙って直さず、黙って捨てない
   - 「新しい Issue にする」なら、local-issue skill の書式（テンプレート・`id` の振り方）で `status: draft` の Issue を書き、本筋に戻る。置き場は worktree ではなく**元リポ（main のチェックアウト）の `issues/`** で、ステージもコミットもしない。main 側の Issue ファイルは untracked のまま `i` に拾われる前提で、worktree に置くと手順6の対象一致を崩し、worktree の削除で消える。`id` は書く直前に元リポの `issues/`（`done/` を含む）を見て決める。並行で走る別の Builder と番号がぶつからないようにするため
   - 他の Issue ファイルの `status:` は変えない。この Issue は手順11で閉じる
4. issueの「確認」項目と、リポ CLAUDE.md の「静的チェック / 検証手段」に従い提出前確認を行う。コードを読んでcaller・importの整合性も確認する。実行系・デプロイ系コマンド（rebuild / deploy / 本番起動）は実行しない
5. issueの保証節がリポの保証台帳 `docs/guarantees.md` の記載に影響する場合（新保証・変更・廃止）、テストと同じPR内で台帳（保証の文言と対応テストの表）を更新する。台帳の更新漏れは実装未完了として扱う
6. `git add {変更したファイル}` し、`git diff --name-only --cached` がissueの「対象」フィールドと完全一致することを確認する（保証台帳を更新した場合はそれも対象に含まれていること）。不一致なら実装に戻る
7. コミットする（保証台帳を更新した場合は同じコミットに含める）。メッセージ本文に報告を入れる（手順11で PR 本文の下敷きにする）。一時ファイルは作らず、heredoc で標準入力から渡して1コマンドに収めること:
   ```
   git commit -F - <<'EOF'
   {type}: {タイトル}

   ## 変更内容
   {issueの内容フィールドを展開}

   ## 保証
   {issueの保証節の各項目 → それを固定したテスト（ファイル・テスト名）の対応。テストを伴わない場合は Issue と同じく `なし（理由）` }

   ## 静的確認結果
   {確認項目に対する結果。git diff --name-only --cached の出力を含める}

   ## 検証手順
   {Agent側で完結しない確認（実行・デプロイ・目視）を、リポ CLAUDE.md の検証手順の雛形に従って記載。なければ省略}
   EOF
   ```
8. `crit` でレビューを受ける。`crit --base-branch main` を `run_in_background: true` で起動し、出力された URL（`http://localhost:<port>`）を「ブラウザでレビューし、終わったら Finish Review を押してください」と添えてそのまま伝える。user が Finish Review を押すまでブロックし、**先にレビューファイルを読んだり、user に何かを入力させたりしない**。完了したら stdout の指示に従って指摘に対応し、必要なら追加コミットする。指摘が無ければそのまま次へ進む（この往復は1周だけ。対応後に再度 crit は開かない）
9. push・PR作成はせずに止まり、user の動作確認を待つ。以下を出力する:
   ✅ Committed on {branch}: {type}: {タイトル}
   Review: git diff main...{branch}
   Verify: 動作を確かめて直す点があれば、このセッションで伝えてください。問題なければ PR を出すよう伝えてください
   動作確認に開発サーバーの起動などが要り、user に頼まれたら起動してよい。rebuild・deploy・本番起動は user が行う
10. 直しを頼まれたら、Issue の範囲内なら追加コミットで直す（手順3のスコープ外の扱いは同じ）。直した範囲について手順4の確認をやり直し、手順9の出力に戻る。直しで新しい Issue は起こさない
11. user が PR を出すよう明示したら、次の順で進める。明示が無いまま進めない
    1. Issue ファイルを同じ階層の `done/` へ `git mv` し、frontmatter の `status: open` を `status: close` に変える。`chore(issues): close {id}` でコミットする
    2. `git push -u origin {branch}`
    3. PR を出す（base は main、題は手順7の実装のコミットの題）。本文はそのコミットの本文を下敷きにし、手順10の直しを反映した最終の状態に書き直す
    4. `done/` のファイルの先頭に次の記録を足し、`chore(issues): record PR for {id}` でコミットして push する
       ```
       ## PR記録: {PR の題}
       issue: {id} ({ファイル名})
       PR: {PR の URL}

       {PR 本文}

       ---

       ```
    5. 以下を出力して終える。マージは user が `i` か GitHub で押す。user に頼まれたときだけ squash でマージする
       ✅ PR: {PR の URL}
       Next: このセッションを閉じる → `i` でマージ（worktree は閉じたときに、枝はマージで畳まれる）
