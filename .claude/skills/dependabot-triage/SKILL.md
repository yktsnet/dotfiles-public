---
name: dependabot-triage
description: 溜まった Dependabot PR（主に major）を横断棚卸しし、github-actions major(CI green)はその場でマージまで実行する。「溜まってる PR 見て」「Dependabot 棚卸しして」と頼まれたときに使う。対象リポは固定リストを保守せず、dotfiles / github-public / github-private 配下を毎回動的に探索する。判断基準の正本は `~/dotfiles/docs-agents/cicd-guide.md` §6。
---

Dependabot の自動マージ運用（`cicd-guide.md` §6）は minor/patch を無条件マージするため、放置してよいのは major だけになる。本 Skill はその major の溜まりを棚卸しする作業を代行する。

## 対象リポの探索（固定リストを持たない）

対象リポの一覧はこの Skill 内にハードコードしない。都度以下で動的に見つける。

```bash
find ~/dotfiles -maxdepth 2 -name dependabot.yml -path '*/.github/*' 2>/dev/null
find ~/github-public ~/github-private -maxdepth 3 -name dependabot.yml -path '*/.github/*' 2>/dev/null
```

`dotfiles` はそれ自体が1リポ(`.github/` は深さ1)なのに対し、`github-public`/`github-private` は配下に個別リポが並ぶ層が1つ多い(`<repo>/.github/` は深さ2)。深さが異なるため探索コマンドを分けている。

ヒットしたリポを次の3種類に分ける。`.github/workflows/dependabot-auto-merge.yml` の有無だけでは判定を誤る（後述の未標準化リポを本当に CI が無いリポと誤認する）ため、`.github/workflows/` 自体の有無も見る。

- CI あり ＋ auto-merge あり → 「CI ありリポの棚卸し」
- CI あり ＋ auto-merge なし → 未標準化。`repo-standardize` の4点セット未適用の疑いがあるので、棚卸しより先にその旨を報告する（後述）
- CI 自体が無い(dotfiles 等) → 「CI なしリポ」

## CI ありリポの棚卸し

`gh` は cwd の git remote から対象リポを自動判定するため、**実行時の cwd に関わらず必ず対象リポの絶対パスへ `cd` してから**叩く（呼び出し元がどのディレクトリにいたかに依存させない。`.github/dependabot.yml` から2階層上がリポルート）:

```bash
(cd <repo-root-abs-path> && gh pr list --author app/dependabot --state open --json number,title,labels,statusCheckRollup)
```

サブシェル `( )` で `cd` するのは、複数リポを順に処理する際にある1件の `cd` が後続の処理に残って別リポの結果を誤って読む事故を防ぐため。

1. major（PR タイトルの `x.y.z` 差分、または `dependency-name` の semver 差分で判定）だけを対象にする。minor/patch は自動マージ待ちなので触らない。
2. CI が red の PR はマージ提案の対象から外し、「close 候補」として提示する（`@dependabot ignore this major version` で恒久無視できる旨を添える）。
3. CI が green の major PR は、依存先の changelog / release notes を読み、次のいずれかを提案する。断定せず提案止まりにし、実行は user の指示を待つ。
   - マージしてよい(破壊的変更が実質無害、または既に対応済み)
   - close する(追従不要、または影響が大きく今は見送り)
   - 追従 Issue 化する(対応が要るが今すぐではない)
4. `github-actions` エコシステムの major(例: checkout 4→7)は大半が無害なので、まとめて先に流してよい。

Compatibility score(他リポの CI 統計)は判断材料にしない。自リポ CI > semver 種別 >> score。

## 未標準化リポ（CI はあるが auto-merge workflow が無い）

棚卸し判断はしない。「`repo-standardize` の4点セットが未適用と見られる」とだけ報告し、適用するかは user の判断に委ねる。ここを CI なしリポと同じ扱いにしない（CI がある以上、放置すると minor/patch も無条件で溜まり続けるため運用上の意味が異なる）。

## CI なしリポ(dotfiles 等)

自動マージなし。棚卸しは「グループ PR が来ているか」の確認のみで、マージ判断は求めない。Web でマージされていたら、近いうちに `u` (pull) で取り込むよう user に一言添える。nix input は週1本のグループ PR に集約されるため、rebuild が実質のテストになる。

## 出力形式

リポごとに「対象 PR 数 / 提案内訳(マージ n・close n・Issue化 n)」を短くまとめ、CI red と CI green の理由がひと目で分かるように提示する。マージ・close・Issue 作成そのものは本 Skill の範囲外(user の裁可を得てから別途実行する)。
