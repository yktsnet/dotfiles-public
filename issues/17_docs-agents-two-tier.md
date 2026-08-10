## docs-agents の2層構造を README と Skill に明示する
id: 17
branch-slug: docs-agents-two-tier
github_issue: 49
status: close
type: cleanup
対象:
- README.md
- README.en.md
- .claude/skills/repo-standardize/SKILL.md
- .claude/skills/repo-readme/SKILL.md
- .claude/skills/module-dev/SKILL.md
内容: `docs-agents/` の7ガイドは「リポを立てる/公開するたびに判断が要るもの」と「一度決めれば機械的に適用できるもの」の2層に分かれており、Skill 側の分担も既にその線で割れている。しかし README の一覧表は7行フラットで層が見えず、各 Skill も自分がどちらを扱うかを書いていない。構造が設計であることを両方に明示する。あわせて README.en.md の表のリンク不揃いを直す。
確認: 目視確認（README 日英の記述内容が一致すること、表のリンク先がすべて存在すること、Skill の frontmatter を変更していないこと）

---

### 保証
- 新たに宣言する保証: なし（ドキュメントと Skill 説明文のみの変更。実行される処理・判定ロジックを変えない）
- 維持する保証: なし（本リポに `docs/guarantees.md` は存在しない。既存テスト `apps/lpt/tests/` は本 Issue の対象範囲に触れない）

### 背景

`docs-agents/` の7ファイルは、費用がいつ発生するかで2層に分かれる。

**判断層** — リポの生涯で1回、しかしリポを作るたびに毎回フルコストで発生する。答えがリポごとに違うためテンプレート化できない。
- `repo-guide.md`（誕生・ファイル衛生）
- `module-guide.md`（配布形態の決定）
- `readme-guide.md`（公開・種別判定）

**定型層** — 一度決めれば次のリポでは同じものを適用するだけで、正解が1つに収束する。実際 `.claude/settings.json` と `hooks/` に実装として落ちている部分もある。
- `issue-driven-workflow.md`
- `harness-guide.md`
- `cicd-guide.md`
- `test-policy.md`

一般論では後者が「開発の基盤」とされるが、それは1つのリポを長く育てる前提での話になる。多数のリポを並行して立ち上げる運用では、リポ1本あたりに支払う判断コストが総量を支配するため、**前者がスループットの律速**になる。

この2層は Skill 側の分担と既に一致している。`repo-standardize` が定型層4本を読んで機械的に適用し、`repo-readme` と `module-dev` が判断層に伴走する。構造は正しいが、**それが偶然でなく設計であることがどこにも書かれていない**。読み手（外部の読者・将来の実行者・Agent）は7ファイルの平坦なリストしか見えない。

なお `repo-standardize` が `test-policy.md` を読まないのは欠落ではない。同 Skill 12行目の公開パイプライン（`repo-standardize → guarantee-audit → repo-readme → ...`）で保証台帳は `guarantee-audit` の管轄と定められている。**この分担を変更しないこと。**

### README.md / README.en.md

`## Agent Development Guides` 節（README.md:95-107、README.en.md:95-107）を書き換える。

現状はリード文1文＋7行の表。これを、リード文＋2つの小見出しに分けた2つの表にする。

小見出しの区分と所属は前節「背景」のとおり。表の各行の役割説明（現在の右カラム）は既存の文言を活かし、書き直す必要はない。

リード文は差し替える。現在の「7ファイルをセットで AI に渡し、標準的な開発環境を構築する」は実際の使われ方とずれている（Skill は必要な分だけを読み、`repo-standardize` は4本、`repo-readme` は1本を参照する）。新しいリード文に含めること。

- 2層に分かれていること、その区分の基準（リポごとに判断が変わるか、一度決めれば適用するだけか）
- 判断層のほうが、多数のリポを並行して立ち上げる運用では効いてくること
- 各層がどの Skill から使われるか（判断層 = `repo-readme` / `module-dev`、定型層 = `repo-standardize`）

**層の分類理由を長々と論じない。** リード文は数文に収め、区分と根拠が伝わればよい。詳細を書きたくなったら、それは各ガイド本体の仕事になる。

英語版は日本語版と記述内容を一致させる。既存の英語表現（`Process layer.` `Harness layer.` 等の書き出し）の調子に合わせること。

#### README.en.md のリンク不揃い（同時に直す）

README.en.md:107 の `test-policy.md` の行だけがリンク先を `docs-agents/test-policy.en.md` にしており、他6行が日本語ファイル（`docs-agents/*.md`）を指しているのと不揃いになっている。**他6行に合わせて `docs-agents/test-policy.md` に直す。**

（英語版の表全体を `.en.md` へ向けるという逆向きの統一もありうるが、それは7行すべてに影響する別の判断になる。本 Issue では既存の多数派に揃えるだけに留める。）

### .claude/skills/{repo-standardize,repo-readme,module-dev}/SKILL.md

各 Skill の「0. 基準を読む」節（`module-dev` は冒頭の規範参照）に、自分がどちらの層を扱うかを1文添える。

- `repo-standardize` — 定型層を機械的に適用する側。ガイドの4本が定型層であること
- `repo-readme` — 判断層に伴走する側。`readme-guide.md` §1 のリトマス試験がリポごとに答えが変わることを含意する
- `module-dev` — 判断層に伴走する側

**frontmatter（`name` / `description` / `manual`）は変更しない。** 本文への1文追加のみ。

層の定義そのものを Skill 側に転記しない。定義の正本は README の当該節であり、Skill は「本 Skill は判断層を扱う」程度の自己申告に留める（基準は本ファイルでなくガイドが正、という既存の方針と揃える）。

### 実装順序

1. README.md の節を書き換え
2. README.en.md を README.md に合わせて書き換え（リンク不揃いの修正を含む）
3. Skill 3本に1文ずつ追加

日英の記述内容が一致していることを最後に突き合わせること。
