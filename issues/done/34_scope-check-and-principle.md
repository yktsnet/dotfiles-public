## PR記録: feat: 差分と Issue の対象の一致をスクリプトで確かめ、確かめ方の振り分けを README に書く
issue: 34 (34_scope-check-and-principle.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/96

## 変更内容
- `check-scope.sh <Issue ファイル>` を新設。分岐元から見たステージ済みの変更（`issues/` 配下を除く）のファイル一覧を Issue の `対象` と比べ、一致なら無言で0、食い違えば足りないパスと余計なパスを分けて出して1
- `対象` は1行のカンマ区切りと `- ` 箇条書きの両方を読み、括弧の注記（半角・全角）とバッククォートは無視する
- pr-workflow の手順6・7と issue-verifier の「範囲」を、このスクリプトを流す記述に替えた。確認者の受け持ちは `対象外`・`内容`・保証節・`仮定` の判断に絞った
- README.md / README.en.md の Design 2 に、確かめ方の振り分け（決定的な検査→別の文脈→人）の段落を足した。重なっていた「他から導ける値」の文は新しい段落へ移して1つにした
- 確認者の指摘を受け、`--cached` の有無と箇条書きの終端を固定するテストを2件足した

## 保証
- 一致で0・食い違いで非0、足りないと余計を分けて出す → `check-scope.test.sh`（一致／足りない／余計／両方／分岐元／未ステージは見ない）
- `issues/` 配下は比べない → 「issues/ 配下の変更は比べない」
- 1行・箇条書き・注記・バッククォートを読む → 書式ごとのケースと「対象の後ろの別の箇条書きを対象に数えない」
- 確認者が `対象外` などを自分で読む（維持）→ `issue-verifier.md` の「範囲」

## 静的確認結果
- `check-scope.test.sh` 終了コード0（23件）
- `.claude` 配下の `*.test.sh` 7本と `check-refs.py` が終了コード0
- `check-scope.sh` を Issue 34 に流して終了コード0

## 確認者の判定
全項目「合」（再判定後）。初回に否だった「未ステージを見ないこと」「箇条書きの終端」のテストは補強済み。

| 項目 | 判定 |
|---|---|
| テストが終了コード0、CI が拾う | 合 |
| 手順6・7と issue-verifier の「範囲」がスクリプトを呼ぶ | 合 |
| README の Design 2 の段落が日英で対応 | 合 |
| テストの正しさ（期待値の出し直し・壊して落ちるか） | 合 |
| 保証3項目 | 合 |

## メモ
- `SKILL.md` 手順6の「共通ガイド」は既存の文言で、今回は手を付けていない

---

## 差分と Issue の対象の一致をスクリプトで確かめ、確かめ方の振り分けを README に書く
id: 34
branch-slug: scope-check-and-principle
status: close
depends: 33
type: feat
対象: .claude/skills/pr-workflow/scripts/check-scope.sh (新規), .claude/skills/pr-workflow/tests/check-scope.test.sh (新規), .claude/skills/pr-workflow/SKILL.md, .claude/agents/issue-verifier.md, README.md, README.en.md
内容: 差分のファイル一覧が Issue の `対象` と一致するかを、実行者（pr-workflow 手順6）と確認者（範囲）が目で比べている。これをスクリプトにし、確認者の受け持ちを中身の判断に絞る。あわせて、33 とこの Issue で入れた振り分け（決定的に確かめられるものは仕組みが、残りは別の文脈が、書いて渡せないものだけを人が）を README の Design 2 に書き、公開している説明と CI の実体を揃える。
対象外: CI での `check-scope.sh` の実行（PR では Issue ファイルが `done/` へ移り記録も足されるので、手元の手順で回す）。Issue テンプレートの `対象` の書式の変更。sdlc-kit への反映
仮定: `対象` の書き方は過去の Issue にある2通り（カンマ区切りの1行、または `対象:` の次行からの `- ` 箇条書き）と、パスの後ろの注記（`(新規)`・`（削除）`・括弧の説明）とバッククォートで尽きる
確認: `bash .claude/skills/pr-workflow/tests/check-scope.test.sh` が終了コード0（33 の CI ジョブでも拾われる）。テストは一時リポで、一致・過不足（足りない／余計）・2通りの書式・注記付き・削除・未コミットのステージ済み変更の各場合を流す。`pr-workflow` の手順6と `issue-verifier` の「範囲」が `check-scope.sh` を呼ぶ記述になっている。README.md と README.en.md の Design 2 に振り分けの段落があり、両者の内容が対応している
人が見るもの: README の Design 2 の段落が、ショーケースとして思想を言い表せているか

---

### 保証
- 新たに宣言する保証:
  - `check-scope.sh <Issue ファイル>` は、ブランチの分岐元から見た変更（コミット済みとステージ済みの両方）のファイル一覧が、Issue の `対象` に挙がったパスと一致すれば終了コード0、食い違えば非0で、足りないパスと余計なパスを分けて出す
  - `issues/` 配下の変更は比べる対象から外す
  - `対象` は1行のカンマ区切りと箇条書きのどちらでも読め、パスの後ろの注記とバッククォートは無視する
- 維持する保証:
  - 確認者は、`対象外`・`内容`・保証節に無い振る舞いの変化と、`仮定` との食い違いを引き続き自分で読んで判定する

### .claude/skills/pr-workflow/scripts/check-scope.sh（新規）
- 引数は Issue ファイルのパス。比べる変更は `git diff --name-only --cached $(git merge-base origin/main HEAD)`（作業ツリーの未ステージは見ない）
- 終了コード0のときは無言でよい

### .claude/skills/pr-workflow/tests/check-scope.test.sh（新規）
- `.claude/hooks/tests/` のテストと同じ流儀（一時ディレクトリにリポを作り、`check` 関数で期待と結果を比べ、`fail` で終了コードを決める）

### .claude/skills/pr-workflow/SKILL.md
- 手順6の「`git diff --name-only --cached` が `対象` と完全一致することを確認する」を、`check-scope.sh` を流して終了コード0を確かめる記述に替える
- 手順7のコミット本文の「静的確認結果」には、`check-scope.sh` の結果を載せる

### .claude/agents/issue-verifier.md
- 「範囲」の「差分のファイル一覧が `対象` と一致しているか」を、`check-scope.sh` を流して出力を証拠にする記述に替える。残りの3項目は自分で読む

### README.md / README.en.md
- Design 2 の「仕組み」の段落の後ろ（mermaid の図より前）に、確かめ方の振り分けを1段落で足す。要点：
  - 確かめる手段は、決定的な検査（フック・スクリプト・CI）→ 別の文脈（確認者などの LLM）→ 人、の順に振り分ける
  - LLM の確認は同じ入力でも判定が揺れる。決定的に確かめられるものを LLM に読ませない。別の文脈が受け持つのは、読まないと答えられないもの（期待値の出し直し、約束から外れていないか、規則同士の矛盾）だけにする
  - このリポでの例：フックの回帰テスト・文書の参照切れ・フックの配線は CI が、差分と Issue の `対象` の一致はスクリプトが落とす
- 既存の「件数・一覧・索引のように他から導ける値は…」の文と重なるなら、1つにまとめる
- 英語版は日本語版と同じ内容を、既存の英語版の文体で書く
