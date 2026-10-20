## PR記録: feat: 決定的に確かめられる規則を CI で走らせる
issue: 33 (33_ci-deterministic-checks.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/95

## 変更内容
- `.github/workflows/ci.yml` に `rule-checks` ジョブを追加。`find .claude -path '*/tests/*.test.sh'` で見つけたテストを1本ずつ bash で流し（全部流してから失敗を返す）、続けて `check-refs.py` を流す。フックテストのステップには git の identity を環境変数で渡す（ランナーには無く、`no-branch-in-checkout.test.sh` が初期コミットを作れず落ちたため）。参照チェックはテストが落ちても流れる（`if: always()`）。発火条件は既存ジョブと同じ（main への push と PR）
- `.claude/skills/consolidate-rules/scripts/check-refs.py` を新規追加（標準ライブラリのみ）。次を1件1行で出力し、あれば終了コード1
  - Markdown の相対リンク先の不在（フェンス・インラインコード・`issues/done/` は見ない）
  - settings.json のフック登録と `.claude/hooks/*.sh` の実体の食い違い（両方向）
  - `.claude/skills/README.md` の一覧から張られていない skill
- `.claude/skills/consolidate-rules/tests/check-refs.test.sh` を新規追加。最小のリポを一時に作り、壊した写しごとに終了コードと出力を確かめる。CI の find が自動で拾う
- `consolidate-rules/SKILL.md` の観点 4・6 から CI が検出するものを外し、CI が受け持つ理由を1文で書いた

## 保証
- PR ごとの CI で `.claude/` 配下の `tests/*.test.sh` がすべて走り、1本でも落ちればジョブが落ちる → `ci.yml` の find ループ（足したテストは設定を直さずに拾われる）
- 相対リンクの不在で落ち、ファイルとリンクを出す → `check-refs.test.sh` の broken-link / broken-link-with-anchor / fence-and-code-span-skipped / issues-done-skipped
- フックの登録と実体の食い違いで落ち、どちらに欠けているかを出す → hook-registered-without-file / hook-file-unregistered
- skill が README の一覧から張られていなければ落ちる → skill-unlisted

## 静的確認結果
- 既存のフックテスト5本と新テストの計6本が bash で終了コード0。`check-refs.py` は現状のリポで終了コード0
- リンク切れ・フック未登録・skill 未掲載の写しで、それぞれ終了コード1と該当箇所の出力を確認
- `ci.yml` は YAML として読め、PR と main への push で走る

## 検証手順
`Rule Checks` ジョブが ubuntu-latest で緑になることを、この PR の CI で確認済み（6本が通る）。

## 確認者の判定
| # | 項目 | 判定 |
|---|---|---|
| 1 | tests/*.test.sh の各ファイルを bash で流し、すべて終了コード0 | 合 |
| 2 | check-refs.py が現状のリポで終了コード0 | 合 |
| 3 | 存在しないリンクを足した写しで非0、ファイルとリンク先を出力 | 合 |
| 4 | フックの登録を外した写しで非0、フック名を出力 | 合 |
| 5 | ci.yml が YAML として読め、PR と main への push で走る | 合 |
| 6 | PR で CI の新しいジョブが緑になる | 判定できない（確認者はランナーで未実行）。PR の CI で `Rule Checks` が緑になったことを実行者が確認 |

保証の固定テストと効き目（実装を壊すと落ちるか）はすべて合。

---

## 決定的に確かめられる規則を CI で走らせる
id: 33
branch-slug: ci-deterministic-checks
status: close
type: feat
対象: .github/workflows/ci.yml, .claude/skills/consolidate-rules/scripts/check-refs.py (新規), .claude/skills/consolidate-rules/tests/check-refs.test.sh (新規), .claude/skills/consolidate-rules/SKILL.md
内容: フックの回帰テストと、文書の参照切れ・フックの配線の食い違いを、LLM の棚卸しから外して PR ごとの CI で落とす。今の CI は `nix flake check` と `zsh -n` だけで、`.claude/hooks/tests/` の5本は誰も走らせておらず、参照切れは `consolidate-rules` が LLM で全件を読んで探している。
対象外: 差分と Issue の `対象` の一致の検査（34 で扱う）。README の Design 節の書き換え（34 で扱う）。見出しへのアンカー（`#...`）の検査。散文中に書かれた skill 名・関数名の存在確認（LLM の棚卸しに残す）
仮定: GitHub の `ubuntu-latest` ランナーに入っている bash・git・jq・python3 と、apt で入れる zsh で、既存のテスト5本が通る
確認: ローカルで `find .claude -path '*/tests/*.test.sh'` の各ファイルを bash で流し、すべて終了コード0。`python3 .claude/skills/consolidate-rules/scripts/check-refs.py` が現状のリポで終了コード0。存在しないパスへのリンクを1本足した写し、および `settings.json` から1本のフックの登録を外した写しで、それぞれ非0で落ち、落ちた箇所（ファイルとリンク先、またはフック名）を出力する。`ci.yml` が YAML として読め、新しいジョブが PR と main への push で走る
人が見るもの: PR で CI の新しいジョブが緑になっていること

---

### 保証
- 新たに宣言する保証:
  - PR ごとの CI で、`.claude/` 配下の `tests/*.test.sh` がすべて走り、1本でも落ちればジョブが落ちる。テストを足せば CI の設定を直さずに拾われる
  - Markdown の相対リンクのうち、リンク先が存在しないものがあれば CI が落ち、どのファイルのどのリンクかを出す
  - `.claude/settings.json` が登録するフックのスクリプトと `.claude/hooks/*.sh` の実体が一致しなければ CI が落ち、どちらに欠けているかを出す
  - `.claude/skills/` の各 skill が `.claude/skills/README.md` の一覧から張られていなければ CI が落ちる
- 維持する保証:
  - 既存の `nix flake check` と `zsh -n` のジョブはそのまま走る
  - `consolidate-rules` は、規則の矛盾・陳腐化・description と本文の乖離を引き続き LLM で棚卸しする

### .github/workflows/ci.yml
- ジョブを1つ足す（名前は例えば `rule-checks`）。zsh を入れ、`find .claude -path '*/tests/*.test.sh'` で見つかったテストを1本ずつ bash で流し、どれかが落ちればジョブを落とす（全部流してから落とす）。続けて `check-refs.py` を流す
- 発火条件は既存ジョブと同じ（main への push と PR）

### .claude/skills/consolidate-rules/scripts/check-refs.py（新規）
- 標準ライブラリだけで書く。リポのルートで実行し、問題があれば1件1行で出力して終了コード1
- 相対リンク: 追跡しているすべての `.md`（`git ls-files '*.md'`）の `[...](相対パス)` を、そのファイルの置き場からの相対で解決して存在を見る。URL（`scheme:`）・`#` だけのアンカー・`<...>` は飛ばし、`#` 以降は落としてパスだけを見る。フェンスで囲んだコードブロックの中は見ない（`readme-i18n` の切り替えリンクの例が誤検知になるため）。`issues/done/` は過去の記録なので見ない
- フックの配線: `settings.json` の中の `hooks/<name>.sh` の参照と、`.claude/hooks/*.sh` の実体を両方向で突き合わせる
- skill の一覧: `.claude/skills/` 直下のディレクトリごとに、`.claude/skills/README.md` に `(<name>/` で始まるリンクがあるかを見る

### .claude/skills/consolidate-rules/SKILL.md
- 観点の「4. 参照切れ」と「6. 層1とガイドの乖離」から、`check-refs.py` が CI で落とすもの（Markdown の相対リンク・フックの登録と実体）を外し、CI が受け持つことを1文で書く。残すのは散文中の skill 名・関数名・見出しの指し先と、settings.json の deny・attribution とガイドの記述の乖離
- 理由を1文で添える：決定的に確かめられるものは CI が毎回落とし、棚卸しは読まないと答えられないものだけを受け持つ
