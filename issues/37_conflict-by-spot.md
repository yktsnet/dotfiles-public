## 動いている実行者とのぶつかりを、ファイル名ではなく直す箇所で判定する
id: 37
branch-slug: conflict-by-spot
status: open
type: cleanup
対象: .claude/skills/local-issue/SKILL.md, .claude/skills/local-issue/reference/issue-template.md
内容: local-issue の手順4の「動いている実行者とぶつからないか」と、テンプレートの `depends` の説明を、同じファイルを触るかではなく、同じ箇所（関数や節）を書き換えるかで判定する書き方に改める。ファイル名だけで判定すると何でも重なって見え、並行できる Issue まで順番待ちになるためである
対象外: 分割の判断基準（Issue 36 で済み）。`i` の `depends:` の扱い。issue-verifier
仮定: 文は `~/dotfiles/.claude/skills/local-issue/` の同じ箇所に揃える
確認: SKILL.md の手順4の該当の箇条と、テンプレートの `depends` の行が、`~/dotfiles/.claude/skills/local-issue/` の同じ行と一致する（`diff` で該当行に差が無い）。ほかの行は変わっていない。`.claude` 配下の `*.test.sh` と `check-refs.py` が終了コード0
人が見るもの: なし

---

### 保証
- 新たに宣言する保証: なし
- 維持する保証:
  - 動いている実行者と同じ箇所を書き換えるか連番を取り合う Issue には、そのブランチの Issue の id を `depends:` に書く
- 廃止する保証:
  - 同じファイルを触るだけで、動いている実行者とぶつかると見なす

### .claude/skills/local-issue/SKILL.md

手順4の「動いている実行者とぶつからないかを」で始まる箇条を、`~/dotfiles/.claude/skills/local-issue/SKILL.md` の同じ箇条と同じ文にする。「同じファイルや連番を取り合うなら」を「同じファイルの同じ箇所を書き換えるか連番を取り合うなら」にし、続けて次の3文を足す。

```
箇所は関数や節の単位で見る。同じファイルでも、別の関数や節を直すだけの Issue と、多くの Issue が1行ずつ追記する一覧へ追記するだけの Issue はぶつからない。ファイル名だけで判定すると何でも重なって見え、並行できる Issue まで順番待ちになる
```

### .claude/skills/local-issue/reference/issue-template.md

`depends` の行の「同じファイルや連番を、動いている実行者と取り合う場合も」を「同じファイルの同じ箇所や連番を、動いている実行者と取り合う場合も」にする。
