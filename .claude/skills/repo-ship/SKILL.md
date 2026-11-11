---
name: repo-ship
description: リポを公開できる形に整える。足場（類型・衛生・LICENSE・CLAUDE.md・CI）→ README → 英語版 README → Public 化 → About と topics の5段を、段ごとの基準を reference から読んで進める。新規リポの組成、既存リポの公開前点検、README の作成・更新、英語版の同期、Public 化、About の設定のどれを頼まれたときにも使う。
disable-model-invocation: true
---

# repo-ship

リポを公開できる形にする段の順と、段をまたぐ判定を書く。段ごとの基準と手順は `reference/` にあり、いま進める段のファイルだけを読む。

## 段の順

| 段 | 読むもの | やること |
|---|---|---|
| scaffold | `reference/scaffold.md`（CI/CD は `reference/cicd.md`） | 類型と検証手段を決め、衛生・LICENSE・CLAUDE.md・CI を整え、README にコアメッセージ1文を置く |
| readme | `reference/readme.md` | 種別を判定し、README を1本の主張として書く |
| i18n | `reference/i18n.md` | トップの README と重要な文書の英語版を作る・同期する |
| publish | `reference/publish.md` | 全履歴のシークレットスキャンをして、Public にする |
| about | `reference/about.md` | README から About と topics を設定する |

順は固定で、都度は判断し直さない。足場とコアメッセージを先に決め、README の本格化はその後にする。英語版は日本語の README が固まってから訳す（先に訳すと二度手間になる）。

`guarantee-audit` はこの順の外にある。共有のリポでテストを持つときだけ、readme の前に入れる（README から台帳へリンクするため）。

## 段の選び方

- `/repo-ship <段>` と段の名前を渡されたら、その段から始める。名前の後ろの引数は、その段に渡す（i18n の対象パスなど）
- 段の名前が無ければ、リポの状態から次の段を判定し、どの段から始めるかを user に一言示してから進める。目安は、CLAUDE.md・LICENSE・コアメッセージが無ければ scaffold、README が1文だけなら readme、`README.en.md` が無いか古ければ i18n、Private なら publish、About が空なら about
- 1つの段が終わったら止まり、次の段へ進むかを user に聞く。まとめて進めるよう頼まれていれば止まらない。publish で公開してよいかの確認は `reference/publish.md` §3 に従う

## 共有のリポ

共有のリポは、持ち主以外が開発するリポと、人に使ってもらうリポ（デプロイする・配布して導入させる）を指す。それ以外は持ち主だけのリポとする。Public かどうかとは別に決める。

| 足場 | 共有のリポ | 持ち主だけのリポ |
|---|---|---|
| `.claude/settings.json`・`pr-workflow` のコピー | 置く | 置かない。force push の deny と attribution はユーザー設定（`~/.claude/settings.json`）で適用されている。作業の進め方は CLAUDE.md に数行で書く |
| dependabot・auto-merge・ruleset | CI があれば入れる | 入れない。更新の PR が溜まるだけになる |
| 保証台帳（`guarantee-audit`） | テストがあれば敷く | 敷かない |

## コミットはしない

どの段も、変更はワーキングツリーに残して差分を要約し、止まる。コミット・push は user の指示があったときだけ実行する。publish の `gh repo edit --visibility` と about の `gh repo edit` は、リポの設定を変える段の本体なので、段の手順に従って実行する。
