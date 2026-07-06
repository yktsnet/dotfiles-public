---
name: repo-about
description: GitHub リポの About（description）と topics を README から生成し gh repo edit で設定する。
manual: true
---

# repo-about

README.md（英語版があれば README.en.md）を読み、GitHub の About と topics を設定する。

## 対象の決定

1. `$ARGUMENTS` にリポのパスがあればそのリポを対象にする
2. なければカレントディレクトリを対象にする
3. カレントに README.md がなければ、1階層下のサブディレクトリで README.md を持つものを列挙し、対象一覧をユーザーに提示して確認を得てから一括処理する

README.md 以外のファイル（CLAUDE.md・context/ 等）は読まない。

## 手順（リポごと）

### 1. README を読む

README.en.md があればそちらを優先して読む（description は英語で書くため）。なければ README.md を読む。

### 2. description の生成

- README の内容から、リポが何であるかを英語 100〜120 文字で要約する
- 技術的に正確で、初見の人がリポの目的を理解できる1文にする

### 3. topics の生成

README の内容から 5〜10 個を目安に選ぶ。以下の優先順で検討する:

- 言語 / フレームワーク（`python`, `astro`, `nix`）
- プラットフォーム（`cloudflare-workers`, `raspberry-pi`）
- ドメイン / 用途（`attendance`, `weather-api`）

既存の topics は一度すべて削除してから新規設定する（クリーンリセット）。削除は `gh repo view --json repositoryTopics` で取得し、各 topic を `--remove-topic` で除去する。

### 4. ユーザー確認

設定する description と topics を提示し、確認を得る。

### 5. 適用

```
gh repo edit --description "..." --add-topic topic1,topic2,...
```

一括処理の場合は各リポで `gh repo edit -R owner/repo` を使う。

### 6. 結果報告

処理したリポ一覧と設定内容を表示する。
