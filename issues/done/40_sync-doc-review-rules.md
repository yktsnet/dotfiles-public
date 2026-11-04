## PR記録: feat: 文書の校正・点検と画面確認の規範を dotfiles に揃える
issue: 40 (40_sync-doc-review-rules.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/109

## 変更内容
dotfiles で入った規範のうち、環境に依らないものを写した。
- common.md: 校正は1回で終える。校正役が報告に回した点は書き手が決め、決めた結果を報告に添える。新しい .md を作ったときと見出しを動かしたときは md-reviewer も呼ぶ
- md-writing skill と md-reviewer agent を新しく置き、skills/README.md の一覧に載せる
- screen-operator・issue-verifier・pr-workflow・issue-template: ヘッドレスのブラウザで再現できない操作の扱いと、見せる画面の準備
- mermaid-diagram: 「ノードの絵文字」の節

## 保証
なし（skill・agent・共通ガイドの文書だけの変更で、コードの挙動を変えない）

## 静的確認結果
- 確認の項目にある文言を grep で確かめた
- check-refs.py: 通過（rc=0）
- nix flake check: all checks passed
- 校正役と点検役の報告は採らず、dotfiles の文面のまま残した。例外は、screen-operator と issue-verifier の「ヘッドレスのブラウザで再現できない操作」で、Issue の確認の文言に揃えた

## 確認者の判定
| # | 項目 | 判定 |
|---|---|---|
| 1 | common.md に「校正は1回で終える」「点検も1回で終える」「md-reviewer」がある | 合 |
| 2 | md-writing/SKILL.md と md-reviewer.md があり、md-reviewer が md-writing を読む | 合 |
| 3 | skills/README.md の一覧に md-writing と md-reviewer がある | 合 |
| 4a | pr-workflow と issue-template に再現できない操作の扱いがある | 合 |
| 4b | screen-operator と issue-verifier に再現できない操作の扱いがある | 合 |
| 5 | mermaid-diagram に「ノードの絵文字」の節がある | 合 |
| 6 | check-refs.py が通る | 合 |

---

## 文書の校正・点検と画面確認の規範を dotfiles に揃える
id: 40
branch-slug: sync-doc-review-rules
status: close
type: feat
対象: home-manager/config/claude/common.md, .claude/skills/md-writing/SKILL.md (新規), .claude/agents/md-reviewer.md (新規), .claude/skills/README.md, .claude/skills/pr-workflow/SKILL.md, .claude/agents/screen-operator.md, .claude/agents/issue-verifier.md, .claude/skills/local-issue/reference/issue-template.md, .claude/skills/mermaid-diagram/SKILL.md
内容: dotfiles で入った規範のうち、環境に依らないものを持ってくる。(1) 校正を1回で終え、校正役が報告に回した点は書き手が決める。(2) 文書の組み立てを点検する `md-writing` skill と `md-reviewer` agent を足し、新しい `.md` を作ったか見出しを動かしたときに呼ぶ。(3) ヘッドレスのブラウザで再現できない操作の扱いと、user に見せる画面の準備。(4) mermaid-diagram の「ノードの先頭に絵文字」の規則（README の図には #108 で適用済み）
対象外: md-reviewer の呼び忘れを止めるフック（dotfiles の `route-md-to-reviewer.sh`）。pr-workflow のマージまで行う流れ、`crit-review` skill への置き換え、`check-scope.sh` を `git diff --name-only --cached` に戻すこと（公開版のほうが新しい）。`~/github-corp/`・gh アカウント・het など環境固有の節
仮定: 対象は目安の7本を超えるが、すべて文書で確認手段は1種類なので1本にまとめる。dotfiles の文面を下敷きにし、`~/dotfiles/` などの環境固有のパスは本リポの言い方（「本リポの .claude/ 配下」など）に直す。「報告に回した点は user に見せて決める」から「書き手が決め、結果を報告に添える」への変更は user と合意済み
確認: 次の文言が各ファイルにあること（grep で確かめる）。common.md に「校正は1回で終える」「点検も1回で終える」「md-reviewer」。md-writing/SKILL.md と agents/md-reviewer.md があり、md-reviewer が `~/.claude/skills/md-writing/SKILL.md` を読む。skills/README.md の一覧に md-writing と md-reviewer がある。screen-operator・issue-verifier・pr-workflow・issue-template に「ヘッドレスのブラウザで再現できない操作」の扱い。mermaid-diagram に「ノードの絵文字」の節。`python3 .claude/skills/consolidate-rules/scripts/check-refs.py`（リンク切れと skill 一覧の載せ漏れの検査）が通る
人が見るもの: なし

---

### 保証
保証: なし（skill・agent・共通ガイドの文書だけの変更で、コードの挙動を変えない）

### common.md
「日本語の文書はコミットの前に校正させる」の節を dotfiles の現行に揃える。
- 「報告に回した点は、書き手が一人で退けない。直すか残すかを user に見せて決める」→「書き手が直すか残すかを決める。user の判断は求めず、決めた結果を報告に添える」
- 「校正は1回で終える。校正役の直しを戻した行や、報告を受けて書き手が直した行のために呼び直さない」を足す
- md-reviewer を呼ぶ条件・md-writing を先に読むこと・点検も1回で終えることの段落を足す（dotfiles common.md の該当段落）

### md-writing/SKILL.md・agents/md-reviewer.md（新規）
dotfiles の同名ファイルを写す。環境固有の記述があれば一般の言い方に直す。

### skills/README.md
一覧に md-writing（skill）と md-reviewer（subagent）を足す。公開の基準に照らして載せる。

### pr-workflow/SKILL.md・screen-operator.md・issue-verifier.md・issue-template.md
dotfiles の 35d06898 で入った追記を写す。
- screen-operator: Playwright の `launch` で headless のまま起動し、ほかの起動方法を使わない（ウィンドウが出ると画面全体を写す操作で端末が固まる）。再現できない操作（画面全体の共有、OS の権限や共有のダイアログ、印刷、通知）は起動のしかたを変えて試さず、理由を返す
- issue-verifier: 画面の項目は headless のまま確かめ、再現できない操作が要る項目は「判定できない」にする
- pr-workflow 手順の画面確認: 再現できない操作は API を差し替えた道順に書き換え、本物の操作だけ user に頼む。見せる状態のデータは先に入れておく。渡す URL は未ログインのブラウザで本番のログインに止まらずに入れるものにする
- issue-template の `確認`: 再現できない操作は API を差し替えて確かめられる形で書き、本物の操作は `人が見るもの` に回す

### mermaid-diagram/SKILL.md
dotfiles の c65fd11d を写す（「ノードの絵文字」の節、ラベル長の規則に「絵文字を含めて」、手順4とチェックリストに絵文字を足す）。
