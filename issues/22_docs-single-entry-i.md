## README と構造の文書を、`i` 1本と実行者が PR を出す流れに合わせる
id: 22
branch-slug: docs-single-entry-i
status: open
type: cleanup
対象:
- README.md
- README.en.md
- context/structure.md
- home-manager/modules/zsh/README.md
- .claude/skills/repo-standardize/SKILL.md
- docs/issue-workflow.md（新規）
内容: Issue 21 で入口を `i` 1本にし、実行者が user の動作確認を受けてから PR を出す流れに変える。文書がそれを追うようにする。README の中心の主張は2つ変わる。リモートへの関門は「user の `issue-finish`」から「実行者のセッションで user が出す OK と、マージ」の2か所になる。Issue は「1本ずつ（直列が裁可の条件）」から「依存し合わないものに限り同じリポで3本まで並行」になる。並行でも裁可が成り立つのは、確認と直しが実行者のセッションごとに閉じているからである。
対象外: 実装と skill の変更（Issue 21）。README の他の節の書き直し。
仮定: Issue 21 がマージされてから open にする。`docs/issue-workflow.md` は作者の手元の dotfiles の `docs/issue-workflow.md`（ローカルの `~/dotfiles/` にある）を下敷きにし、横断するリポを `AIAGENT_REPO_ROOTS` の説明に置き換え、作者の環境に固有な記述（会社用のリポの扱い・裏の校正の待ち合わせ）を外す。README.en.md は README.md の書き換えに合わせて訳し直し、英語版だけの言い回しは足さない。
確認: `issue-finish`・`issue-open`・`issue-abort`・`issue-import-pr`・`issue-status` と、コマンドとしての `` `issue` `` への参照が `issues/` 以外に残っていないことを grep で確かめる。README の mermaid は目視確認。

---

### 保証
- 新たに宣言する保証: なし（文書の追従のみ）
- 維持する保証: なし（文書の追従のみ）

### README.md・README.en.md（「決める役と作る役を分ける」の節、L80-110 付近）

- 役割の箇条書きで、実行者を「実装・テスト・静的確認・コミットまで進め、user の確認を受けて直し、OK を受けて PR を出す。main へは push せず、マージしない」に直す。user は「保証節を裁可し、実行者のセッションで動作を確かめ、マージする」
- mermaid の図で、`issue-abort` と `issue-finish` の矢印をやめる。実行者のセッションの中で「コミット → crit と動作確認 → 直し」が回り、user の OK で実行者が PR を出し、user がマージする形にする。破棄は `i` の abort から出す。後片付けは人の操作に置かない
- 関数の箇条書き（L101-105）を `i` 1つに置き換え、選べる動作（run / approve / merge / abort / status）を短く並べる。詳細は `docs/issue-workflow.md` へリンクする
- L107 の段落を書き換える。関門は上の2か所であること、crit で行単位にレビューして指摘をそのセッションへ戻すこと（今の記述を残す）、並行は依存し合わない Issue に限ることと、その理由を書く
- デバイス表（L123）の「`issue` の起動元」を `i` に直す

### docs/issue-workflow.md（新規）

一周の流れ（誰が・どこで）、`i` の一覧の各行と選んだときの動き、並行で走らせるときの条件、実行者のセッションでやること（crit → `Review:` と `Verify:` を見て確かめる → 直し → 「PR を出して」→ セッションを閉じる）、後片付け、実装の在りかを書く。

### context/structure.md（L35・L43）

ワークフロー層の説明を `i` に直す。`done/` は「実行者が PR を出すときに、同じ枝の中で Issue を移し、PR の題・URL・本文の記録を先頭に足したもの」に直す。

### home-manager/modules/zsh/README.md（L21）

`aiagent.sh` の説明を `i`（全リポ横断の Issue 駆動の入口）に直す。

### repo-standardize（L51）

実行者がリモートに触れない分業の根拠に `issue-finish` を挙げている箇所を、「実行者は main に push せず、マージもしない（`pr-workflow`）」に直す。
