## PR記録: feat: Publish a weekly showcase of public guarantee ledgers
issue: 41 (41_guarantees-showcase.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/126

## 変更内容
- `.github/scripts/guarantees-showcase.sh`: `yktsnet` の public リポ（archive・fork を除く）から `docs/guarantees/README.md` を持つものを探し、リポ・保証件数・対象ファイル数を保証の多い順（同数はリポ名の順）に並べた表を書き出す。`*.en.md` と README は数えない。表の上に、全リポの台帳の最終更新日のうち最も新しいものを1行で出す。台帳の一覧の取得が 404 のときだけ「台帳なし」として飛ばし、ほかの API エラーでは止めて書き出さない。出力先は第1引数か `SHOWCASE_OUT`、既定は `docs/guarantees-showcase.md`
- `.github/workflows/guarantees-showcase.yml`: 週1回（月曜 00:00 UTC）と手動で走らせ、差分があるときだけ `github-actions[bot]` でコミットし、デプロイキー `SHOWCASE_DEPLOY_KEY` の SSH remote で main へ push する。`permissions: contents: read`、API の読み取りは `GITHUB_TOKEN`。重ねて走らないよう `concurrency` を付けた
- `docs/guarantees-showcase.md`: スクリプトの出力（12 リポ・1309 件・95 ファイル）
- `README.md`: GDD の段落から一覧へリンク

起票時から、表は件数だけの3列に絞り（Gaps・状態・行ごとの最終更新を外した）、並びを保証の多い順に変えた。

## 保証
なし（このリポに保証台帳もテスト基盤も無い。出力の正しさは確認の項目で確かめた）

## 静的確認結果
- スクリプトを続けて走らせ、出力が一致
- ccreel の 153 件・6 ファイルを独自に数え直して一致。etax-prep は `*.en.md` を除いて 69 件・4 ファイル
- 一覧の12行が、`gh repo list` と contents API で突き合わせた集合と一致
- 404 以外の失敗（偽の `gh` で 403 を返す）では rc=1 で止まり、出力ファイルを作らない
- `check-refs.py` 通過、`bash -n` 通過、`check-scope.sh` 通過

## 検証手順
マージ後に `gh workflow run guarantees-showcase` を1回走らせる。差分があればデプロイキー経由でコミットと main への push ができ、無ければ何も起きないことを確かめる。

## 確認者の判定
| # | 項目（要約） | 判定 |
|---|---|---|
| 1 | 書き出し、2回走らせても差分なし | 合 |
| 2 | 一覧の行が対象リポの集合と一致 | 合 |
| 3 | ccreel の保証件数と対象ファイル数 | 合 |
| 4 | etax-prep が `*.en.md` を数えない | 合 |
| 5 | 合計の行が各行の和と一致 | 合 |
| 6 | 台帳が変わらなくても変わる値が無い | 合 |
| 7 | 起動・権限・トークン・secret の要件 | 合 |
| 8 | 差分が無ければコミットしない | 合 |
| 9 | README からのリンクと check-refs | 合 |

範囲: 合。目的に届かない点: なし。

## 手戻り

| 何が起きたか | 失ったもの | 原因の分類 | 仕組みで防げたか |
|---|---|---|---|
| Issue の `対象` が全角の「、」区切りで、`check-scope.sh` が半角カンマでしか分割せず、範囲の判定が否になった | 判定のやり直し1回。10分 | Issue の切り方 | 防げた：`check-scope.sh` が「、」も区切りとして扱うか、local-issue skill のテンプレートに半角カンマ区切りを明記していれば |
| 台帳の一覧の取得で、404 以外の失敗も「台帳なし」として飛ばしており、確認者に目的に届かない点として挙げられた | 追加のコミット1回。10分 | 実装者の不注意 | 防げない |

---

## Publish a weekly showcase of public guarantee ledgers
id: 41
branch-slug: guarantees-showcase
status: close
type: feat
対象: .github/scripts/guarantees-showcase.sh (新規), .github/workflows/guarantees-showcase.yml (新規), docs/guarantees-showcase.md (新規・スクリプトの出力), README.md（GDD の段落）
目的: README の GDD の説明を読んだ人が、実際に台帳を持つ public リポとその約束の規模を1か所で見て、各リポの台帳へ辿れるようにする。台帳を足したり直したりしても、手を動かさずに一覧が追従するようにする。
内容: `yktsnet` の public リポから保証台帳を探して一覧の MD を書き出すスクリプトと、それを週1回と手動で走らせ、差分があるときだけ main へコミットするワークフローを置く。生成した一覧を同じ変更で載せ、README の GDD の段落からリンクする。
対象外: 台帳の本文のコピー・要約。private リポ。各リポの台帳の書式の変更。デプロイキー・secret・ルールセットの変更（設定済み）
仮定: 台帳の有無は `docs/guarantees/README.md` の存在で決める。etax-prep のように `*.en.md` の英訳を並べるリポは、英訳を数えない。
確認:
- `bash .github/scripts/guarantees-showcase.sh` を手元（`gh` ログイン済み）で走らせると `docs/guarantees-showcase.md` が書き出され、2回続けて走らせても差分が出ない
- 一覧の行は、`yktsnet` の public かつ archive でも fork でもないリポのうち `docs/guarantees/README.md` を持つものと一致する（`gh repo list` と各リポの contents API で突き合わせる）
- ccreel の行の保証件数が、ccreel の `docs/guarantees/` の README 以外のファイルにある表のデータ行（見出し行と区切り行を除く）の合計と一致し、対象ファイル数がそのファイルの数と一致する
- etax-prep の行が `*.en.md` を数えず
- 合計の行のリポ数・保証件数・対象ファイル数が、各行の和と一致する
- 出力に生成日時など、台帳が変わらなくても変わる値が無い
- ワークフローは `schedule`（週1回）と `workflow_dispatch` で起動し、`permissions` は `contents: read` だけである。API の読み取りは `GITHUB_TOKEN`、main への push は secret `SHOWCASE_DEPLOY_KEY`（デプロイキー）で行い、それ以外の secret を参照しない
- ワークフローは出力に差分が無いときコミットしない（`git diff --quiet` 等で分岐している）
- README の GDD の段落から `docs/guarantees-showcase.md` へのリンクがあり、`python3 .claude/skills/consolidate-rules/scripts/check-refs.py` が通る
人が見るもの: マージ後に user が `gh workflow run guarantees-showcase` で1回走らせて、コミットができること（差分が無ければ何も起きないこと）を確かめる。一覧の見た目が README から辿る読み手に通じるか

---

### 保証
保証: なし（このリポに保証台帳もテスト基盤も無い。出力の正しさは確認の項目で一度確かめる）

### main への push の経路（設定済み）
main のルールセット `require-ci-for-dependabot` は CI の通過を必須にしているので、`GITHUB_TOKEN` では main へ push できない。GitHub Actions を bypass に入れると、同じトークンで `gh pr merge --auto` を打つ `dependabot-auto-merge.yml` まで CI を待たずにマージしうる。そこで書き込み権限付きのデプロイキー `guarantees-showcase` を登録し、秘密鍵を secret `SHOWCASE_DEPLOY_KEY` に入れ、ルールセットの bypass にデプロイキー（`DeployKey`）を足してある。実行者は設定を変えない。

### .github/scripts/guarantees-showcase.sh
- `gh api` で `yktsnet` の public リポを列挙し、archive と fork を除く。リポ名をスクリプトに書かない
- 各リポで `docs/guarantees/` の一覧を contents API で取り、`README.md` が無ければ飛ばす。一覧が 404 なら台帳なしとして飛ばし、ほかの失敗では止めて書き出さない
- 1リポにつき1行、次の列を出す
  - リポ名（`https://github.com/yktsnet/<repo>/tree/<default_branch>/docs/guarantees` へのリンク）
  - 保証の件数: README と `*.en.md` を除くファイルの、表のデータ行の合計
  - 対象ファイル数: README と `*.en.md` を除くファイルの数
- 並びは保証の多い順（同数はリポ名の順）。末尾に合計の行（リポ数・保証件数・対象ファイル数）
- 表の上に、全リポの `docs/guarantees` を最後に変えたコミットのうち最も新しい日付を「最終更新」として1行で出す（commits API の `path=docs/guarantees`）
- 表の上に、GDD を2〜3文で説明し、Zenn の記事と README の GDD の段落へリンクする固定の前文を置く。前文は日本語、実行時メッセージは英語
- 出力先は第1引数か環境変数で変えられるようにし、既定は `docs/guarantees-showcase.md`
- トークンは `gh` の認証に任せる（Actions では `GH_TOKEN: ${{ github.token }}`）

### .github/workflows/guarantees-showcase.yml
- 週1回の `schedule` と `workflow_dispatch`
- `permissions: contents: read`
- `actions/checkout` に `ssh-key: ${{ secrets.SHOWCASE_DEPLOY_KEY }}` を渡し、push はその SSH の remote で行う。API の読み取りは `GH_TOKEN: ${{ github.token }}`
- スクリプトを走らせ、`docs/guarantees-showcase.md` に差分があるときだけ `github-actions[bot]` でコミットして main へ push する。件名は `docs: update guarantees showcase`
- 既存の action の版は `ci.yml` に揃える

### docs/guarantees-showcase.md
- スクリプトで生成したものを載せる。手で直さない旨を前文の末尾に1文で書く

### README.md
- GDD の段落（「台帳に載っていない振る舞いは約束ではない」の文）の後に、各リポの台帳の一覧として `docs/guarantees-showcase.md` へのリンクを1文で足す
