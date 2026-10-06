## 18 までの閉じた Issue を `done/` の1ファイルに畳み、起票の番号を `done/` まで見て振る
id: 24
branch-slug: issues-done-layout
status: open
type: cleanup
対象:
- issues/01_*.md 〜 issues/18_*.md（削除、18本）
- issues/done/01_*.md 〜 issues/done/18_*.md（変更、18本）
- .claude/skills/local-issue/SKILL.md（L12 の手順2）
内容: Issue 19 から、閉じた Issue は本文ごと `issues/done/` へ移り、PR の記録を先頭に足した1ファイルになった。18 までは旧い置き方のままで、本文が `issues/` 直下に `status: close` で残り、`done/` には PR の記録だけが別に置かれている。リモートの `issues/` 直下が 18 で止まって見え、新しい Issue が反映されていないように読める。18 までを今の形に畳み、直下には何も追跡しない状態にする。あわせて、`local-issue` の手順2が `issues/*.md` だけを見て番号を振っているのを、`issues/done/*.md` も見るように直す。直下が空のときに 01 から振り直し、`done/` と番号が重なるため。
対象外: 19 以降の `done/` のファイル。`issues/done/` 以外の置き場。旧い本文にある `github_issue:` 欄（記録としてそのまま残す）。
仮定: 対象のファイル数が目安（7本）を超えるが、同じ機械的な操作の繰り返しで確認も1種類なので分けない。畳んだファイルの形は、今の `pr-workflow` の手順11-4 が作る形（PR の記録 → 空行 → `---` → 空行 → Issue 本文）に揃える。
確認: `git ls-files issues/` に `issues/done/` の外のファイルが（この Issue 自身を除き）残っていないこと。`issues/done/01_*.md` 〜 `18_*.md` のすべてに、`## PR記録:` の行と `^id: ` の行が両方あること。各ファイルの PR の記録の部分が、変更前と一致すること（`git diff` で、追記だけになっていることを見る）。

---

### 保証
- 新たに宣言する保証: なし（記録の置き方を揃えるだけで、ツールの振る舞いは変えない）
- 維持する保証: なし（同上）

### issues/01〜18 と issues/done/01〜18

同じ番号の対は、ファイル名が一致している（作業前に確かめ済み）。対ごとに次を行う。

1. `issues/done/NN_*.md` の末尾に、空行・`---`・空行を挟んで `issues/NN_*.md` の全文を足す。PR の記録の部分は書き換えない
2. `git rm issues/NN_*.md`

### local-issue（L12）

手順2の確認先を「`issues/*.md` と `issues/done/*.md`」にし、直下だけを見ると番号が重なる理由を一言添える。作者の手元の dotfiles の同じ手順と同じ文にする。
