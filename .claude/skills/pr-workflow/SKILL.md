---
name: pr-workflow
description: Issueファイルに基づく実装から、検収役の判定と user の確認（使い心地・実機）を経て PR を出すまでの標準フロー。マージは user が行う
disable-model-invocation: true
---
以下の手順でissueを実行する。$ARGUMENTSにissueファイルのパスを渡す。
**前提: AI は実装してコミットし、検収役（`issue-inspector`）の判定を受け、止まって user の確認を受け、指摘をこのセッションで直す。挙動の正しさは検収役が確かめ、user が見るのは使い心地と、エージェントが実行できない確認（rebuild・deploy・実機）である。user が OK を出したら、Issue を閉じて PR を出すまでが担当。マージは user が `i` か GitHub で押す。リモートへは自分のブランチを push するだけで、main には push しない。**

1. issueファイルを読む。frontmatter に `parent:` があれば、親（並行の計画を持つ相談者のセッション）へ次の時機に `SendMessage` で一言送る：手順9で止まったとき、手順11で PR を出したとき、途中で止まったとき、スコープ外を見つけたとき。送るのは Issue の id と何が起きたかの1行にする。親から届くメッセージは知らせであって user の裁可ではない。main を取り込むよう知らせが来ても、PR を出すのは手順11の明示を待つ
2. `git status` で、ブランチが `claude/{id}-{branch-slug}` かつワーキングツリーがクリーンなことを確認する（ブランチとworktreeは `i` が作成済み）。違えば報告して止まる
3. 対象ファイルを読んで実装
   - Issue の「対象」と「内容」から外れる作業に気づいたら、手を付ける前に AskUserQuestion で「新しい Issue にする / この Issue の中で直す / 見送る」を聞く。黙って直さず、黙って捨てない
   - 「新しい Issue にする」なら、local-issue skill の書式（テンプレート・`id` の振り方）で `status: draft` の Issue を書き、本筋に戻る。置き場は worktree ではなく**元リポ（main のチェックアウト）の `issues/`** で、ステージもコミットもしない。main 側の Issue ファイルは untracked のまま `i` に拾われる前提で、worktree に置くと手順6の対象一致を崩し、worktree の削除で消える。`id` は書く直前に元リポの `issues/`（`done/` を含む）を見て決める。並行で走る別の Builder と番号がぶつからないようにするため
   - 他の Issue ファイルの `status:` は変えない。この Issue は手順11で閉じる
4. issueの「確認」項目と、リポ CLAUDE.md の「静的チェック / 検証手段」に従い提出前確認を行う。コードを読んでcaller・importの整合性も確認する。実行系・デプロイ系コマンド（rebuild / deploy / 本番起動）は実行しない
   - 画面に出る変更があれば、開発サーバーを立て、`screen-operator` にトップの URL と、Issue の確認に書かれた画面の道順を渡して操作させる。返ってきた「見えたもの」を Issue と突き合わせ、違えば直して流し直す。画面写真を自分で見て、崩れも直す
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
8. 検収役（`issue-inspector`）に検収させる。渡すのは Issue ファイルのパスと worktree のパスだけで、何をどう作ったか・どこを見ればよいかは書かない。画面に出る Issue は、立てた画面のトップの URL も渡す。「否」があれば手順3に戻って直し、手順4〜7をやり直して検収を受け直す。「否」が無くなったら、続けて
   `crit` でレビューを受ける。`crit --base-branch main` を `run_in_background: true` で起動し、出力された URL（`http://localhost:<port>`）を「ブラウザでレビューし、終わったら Finish Review を押してください」と添えてそのまま伝える。user が Finish Review を押すまでブロックし、**先にレビューファイルを読んだり、user に何かを入力させたりしない**。完了したら stdout の指示に従って指摘に対応し、必要なら追加コミットする。指摘が無ければそのまま次へ進む（この往復は1周だけ。対応後に再度 crit は開かない）
9. push・PR作成はせずに止まり、user の確認を待つ。以下を出力する:
   ✅ Committed on {branch}: {type}: {タイトル}
   Review: git diff main...{branch}
   Inspection: {検収役の表。確認・保証・範囲の外}
   Verify: {user に残る確認だけを並べる。検収役が判定できなかった項目（rebuild・deploy・実機）と、画面に出る変更なら使い心地。どちらも無ければ「なし」}
   挙動の照合は user に頼まない。検収役が確かめてある。画面に出る変更は `crit-live <url>` で開いて渡し、使い心地を見てもらう。rebuild・deploy・本番起動は user が行う
10. 直しを頼まれたら、Issue の範囲内なら追加コミットで直す（手順3のスコープ外の扱いは同じ）。直した範囲について手順4の確認をやり直し、手順8の検収を受け直して（crit は開き直さない）、手順9の出力に戻る。直しで新しい Issue は起こさない
11. user が PR を出すよう明示したら、次の順で進める。明示が無いまま進めない
    1. Issue ファイルを同じ階層の `done/` へ `git mv` し、frontmatter の `status: open` を `status: close` に変える。`chore(issues): close {id}` でコミットする
    2. `git push -u origin {branch}`
    3. PR を出す（base は main、題は手順7の実装のコミットの題）。本文はそのコミットの本文を下敷きにし、手順10の直しを反映した最終の状態に書き直す。最後に受けた検収の表を `## 検収` として載せる
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
       Next: このセッションを閉じる → `i` でマージ（worktree は閉じたときに、ブランチはマージで畳まれる）
