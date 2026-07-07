## harness-guide に知識の配置基準を追加し README Philosophy に4項目目を追記
id: 02
branch-slug: knowledge-layering-docs
github_issue: 13
status: close
type: feat
対象: docs-agents/harness-guide.md, docs-agents/harness-guide.en.md, README.md, README.en.md
内容: ハーネス設計ガイドに「知識ドキュメントをどこに置くか」の判断基準（読み込みの契機で決める）を新節として追加し、README の Philosophy に4項目目「暗黙知の宣言化」を追記する。英語版2ファイルも同期する。
確認: 目視確認（追加節へのリンクが README から辿れること・既存節の番号や参照が壊れていないこと）
---

## 背景

harness-guide には Skills の節（§4 層2 内）があるが、「どの知識をいつ skill にするか」の判断基準が書かれていない。実運用で確立した基準を規範として明文化する。

動機となった実例: sops の運用手順書が `devices/docs/`（どこからも参照されない場所）にあり、暗号化のたびに user が手でファイルを渡していた。skill 化して description に起動条件を書いたことで、手渡しが不要になった。「どのファイルをいつ渡すか」が人間の頭にだけある状態が暗黙知であり、skill の description はそれをコミットされる宣言に変える。

## docs-agents/harness-guide.md

§4「層2 — 指示ファイル」の末尾（`### Skills` 小節の後）に小節「知識の配置基準」を追加する。盛り込む内容:

- 置き場は「読み込みの契機」で決める。4分類:
  - 毎回効く短い規則 → CLAUDE.md に1行
  - 「〜するとき」と条件を言える手順・規範 → skill（description が起動条件の宣言になる）
  - 規則から指す共有辞書・ガイド → 独立ディレクトリに置き、CLAUDE.md / skill から絶対パスで参照（例: `secrets-agents/`・`docs-agents/`）
  - 人間の下書き・未整理の思考 → ハーネスの外。AI に自動で読ませない
- 移住のトリガー: 「またこのドキュメントを手で渡したな」と気づいた瞬間が skill 化のタイミング。一括移行はしない
- skill の骨格をコード片で1つ示す（frontmatter の `name` / `description` と、description に「〜するとき使用する」と起動条件を列挙する書き方。数行でよい）
- skill の更新は自動抽出せず、作業中にズレへ気づいたら提案止まりにする（レビューされない規範を量産しない）

文体は既存の harness-guide の規範（断定・簡潔・表とコード片中心）に合わせる。jp-writing skill の規範に従う。

## README.md

「Philosophy & Core Architecture」の `### 3. 機密情報・インフラ設定の分離` の後に `### 4.` として追記する。要件:

- 課題→解の構成を既存3項目と揃える。課題: 運用知識が「どのファイルをいつ AI に渡すか」という人間の暗黙知に依存する。解: 知識を読み込みの契機で配置し、条件起動の手順は skill の description に起動条件として宣言する
- 3〜4文の要約に留め、詳細は harness-guide の新節へのリンクで委譲する
- Tips 口調にしない。既存項目と同格の設計思想として書く

## 英語版の同期

- `docs-agents/harness-guide.en.md`: 追加節を翻訳して同期
- `README.en.md`: readme-i18n skill の手順に従い追記分を同期

## 実装順序

harness-guide.md → README.md（リンク先を確定させてから README を書く）→ 英語版2ファイル。
