## PR記録: feat: README に、作る役と判定する役を分けることと、書いて渡せるかの軸を足す
issue: 26 (26_readme-judge-split.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/83

## 変更内容
- README.md の Why に、書いて渡せるかの分かれ目を足し、人間の仕事に「書いて渡せない感覚の判断」を加えた。動作の照合は人の仕事から外した
- Design 3 に subagent とスクリプト・CI という置き場を足した
- Design 5 に、作る役と判定する役を分けること（検収役には Issue だけを渡す・判定を足す段の基準・足す理由3つ）を足し、user の担当を使い心地と実機にし、図を「検収役 → crit と使い心地の確認」の流れにした
- Skills の表に issue-inspector・screen-operator と、skill-dev の持つ「subagent を足す段」を足した
- README.en.md に同じ節の変更を反映した
- CLAUDE.md の実行者の行を、検収役の判定を受けてから user の確認（使い心地・実機）へ進む流れに合わせた
- skill-dev に「6. subagent をどの段に足すか」と description を稼働側から写した（会社のリポの扱いは写していない）
- .claude/skills/README.md の一覧に、検収役・画面の操作役と、skill-dev の「subagent を足す段」を足した

## 保証
なし（文書と skill の記述だけで、実行されるコードに触れない）

## 静的確認結果
- README.md と README.en.md の見出し行番号が一致（17 見出し、diff なし）
- mermaid は TD・形（{{ }}）・線種を既存と揃え、ラベルは短いまま
- `grep -n 動作確認 README.md CLAUDE.md` は 0 件
- skill-dev に会社のリポ・ホスト名の記述なし
- git diff --name-only --cached:
  .claude/skills/README.md
  .claude/skills/skill-dev/SKILL.md
  CLAUDE.md
  README.en.md
  README.md

## 検証手順
- 前提の Issue 25 がマージされるまで、README が指す `.claude/agents/` の2ファイルのリンクは切れている。25 のマージ後に GitHub 上でリンクと mermaid の表示を確かめる
- 追記した文面が、自分の思想を自分の言葉で言えているかを読んで確かめる（書いて渡せない判断）

## 注意
Issue 25 が未マージの間、README が指す `.claude/agents/` の2ファイルはリンク切れ。25 より先にマージしない。

---

## README に、作る役と判定する役を分けることと、書いて渡せるかの軸を足す
id: 26
branch-slug: readme-judge-split
status: close
type: feat
対象:
- README.md（Why・Design 3・Design 5・Skills の表）
- README.en.md（同じ節）
- CLAUDE.md（「動作フロー」の実行者の行）
- .claude/skills/skill-dev/SKILL.md（「6. subagent をどの段に足すか」）
- .claude/skills/README.md（一覧の「分業」と「知識の置き場」）
内容: README の Why は「人間の仕事は、コードを書くことから約束を裁可することへ移る」と言うが、Design 5 と図では user が実行者のセッションで動作確認をしていて、主張と仕組みがずれている。25 で判定を検収役へ移したので、README の思想をそれに合わせる。軸は書いて渡せるかである。挙動は書いて渡せるので AI が確かめる。使い心地は AI が意図や感覚を持ちにくく、人が言葉にしても渡しきれないので人が判断する。
対象外: 25 で扱う skill・agent・`claude.nix`・`docs/issue-workflow.md`。Design 1・2・4 と Foundation。
仮定: 新しい原則を6番目として立てず、Design 3 と 5 への追記で表す。Principles の並びと依存の説明を変えずに済むため。
確認: README.md と README.en.md の節の対応が崩れていない（見出しの数と順が一致）。mermaid のブロックが `mermaid-diagram` の制約（幅・形・線種）を守っている。`grep -n 動作確認 README.md CLAUDE.md` に、user が挙動を照合する記述が残っていない。skill-dev の6節にホスト名・会社の事情が無い。
人が見るもの: 追記した文面が、自分の思想を自分の言葉で言えているか（書いて渡せない判断）。

---

### 前提
- 25 がマージされていること（README から `.claude/agents/` の定義を指すため）

### 保証
- 新たに宣言する保証: なし（文書と skill の記述だけで、実行されるコードに触れない）
- 維持する保証: なし（同上）

### README.md
- **Why**：人間の仕事に、「書いて渡せない感覚（使い心地）を判断すること」を足す。約束の裁可と並べ、動作確認は人の仕事から外れたことが読めるようにする
- **Design 3「読まれる場面ごとに知識を置く」**：置き場の並び（CLAUDE.md・skill・deny とフック）に、文脈を分ける subagent と、派生値を手で書かずにスクリプトと CI に持たせることを足す。subagent をどの段に足すかの基準は skill-dev を指す
- **Design 5「決める役と作る役を分ける」**：作る役と判定する役も分けることを足す。検収役（`issue-inspector`）には Issue だけを渡し、実行者の説明は渡さない。すでに別の文脈が確かめている段（相談者と実行者の分離、user の裁可）には足さない。足す理由は客観性・速さ・自動化の3つに限る
- **役割の箇条**：user の担当を「保証節の裁可・使い心地の判断・実機での確認・マージ」にする
- **図**：`V{{crit と動作確認}}` を、検収 → crit と使い心地の確認、の流れに置き換える
- **Skills の表**：「5. 分業」に `issue-inspector`・`screen-operator` の行を足す

### README.en.md
`readme-i18n` の手順で、README.md の変更を同じ節に反映する。

### CLAUDE.md
「動作フロー」の実行者の行を、「実装してコミットしたら検収役の判定を受け、止まって user の確認（使い心地・実機）を受けて指摘を直す」にする。

### .claude/skills/skill-dev/SKILL.md
稼働側の「6. subagent をどの段に足すか」を写し、description を合わせる。定義の置き場の段落にある会社のリポの扱いは、公開側の skill-dev が持たない例外なので写さない。

### .claude/skills/README.md
一覧の「分業」に検収役と画面の操作役を、「知識の置き場」の skill-dev の持つものに「subagent を足す段」を足す。
