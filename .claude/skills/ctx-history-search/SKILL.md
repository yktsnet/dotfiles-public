---
name: ctx-history-search
description: 過去の相談者セッション（直前の続きを読む・設計判断や議論の経緯を確認する・直近/今日何を作業したかの振り返り）を ctx で検索する。対象は運用しているリポのうち相談者セッションが動くものすべて。「さっきの続きをやりたい」「これ前に決めたはず」「今日/直近何をしたか」を確認したいときに使う。git log は commit された変更点しか分からないので、議論の経緯や作業内容の粒度が要る要約はこちらを優先する。
disable-model-invocation: true
---

対象は運用しているリポの相談者セッションのみ。`issue()` 起動の実行者セッションは
`<repo>.wt/<slug>` という別ディレクトリ名（`-wt-` を含む）で動いており対象外。
`--workspace` フィルタでこれを除外する。

## 最頻出のケース: 直前の続きを読む

新しい会話で「さっきの続きをやりたいから読んで」と言われたときの主用途。検索クエリを考える必要はなく、
このリポで一番新しいセッションを直接引く。

```sh
ctx sql "SELECT ctx_session_id, source_path, MAX(occurred_at_ms) as last_ts
         FROM ctx_events
         WHERE source_path LIKE '%<repo-name>/%'
         GROUP BY source_path ORDER BY last_ts DESC LIMIT 1" --format table
```

- `<repo-name>` は今動いているリポ名。末尾スラッシュで `-wt-`（実行者セッション）を除外する
- 出てきた `ctx_session_id` を `ctx show session <id> --mode full` で読む。継続作業の把握には `--mode lite`（最終応答のみ）より `--mode full`（全メッセージ）の方が安全
- `ctx search` は検索クエリが必須(空では実行できない)なので、この「ただ一番新しいのを読みたい」用途には使えない。SQLで直接引くのが正しい経路

## トピック検索(「前にこれ決めたはず」)

```sh
ctx search "<query>" --workspace "<repo-name>/" --since 14d
```

- `<repo-name>` は今動いているリポ名。**絶対パスではなくリポ名のみ**を渡す
  - `--workspace` は Claude Code のプロジェクトディレクトリ名(`~/.claude/projects/-Users-<user>-<repo-name>/...` のようなハイフン区切り形式)への部分一致で判定される。絶対パス(`/Users/<user>/<repo-name>/`)を渡すと0件になる(実データで検証済み)
- 末尾スラッシュを付けることで `<repo-name>-wt-15-.../`(実行者セッション)を部分一致から除外する(実データで検証済み: `--workspace "<repo-name>/"` は `-wt-` セッションを含まない)
- 既定は直近14日。結果が薄い場合のみ `--since 30d` 等に広げてよい

## 既知の制約

- `ctx_sessions.cwd` 列はほぼ全件 NULL(import元がClaude Codeのjsonl treeの場合、cwdは記録されない)。ワークスペース判定は `cwd` ではなく `--workspace` フィルタ(内部的にはプロジェクトディレクトリ名への部分一致)に依存すること

## セッション本文を読む

```sh
ctx show session <ctx-session-id> --mode lite
```

詳細が要る場合のみ `--mode full`(メッセージ全体)や `--mode log`(tool/command含む全イベント)を使う。

同じ jsonl ファイル(= 同じ作業の一連の流れ)に複数の `ctx_session_id` が紐づくことがある
(compaction・サブエージェント等)。1ファイルにつき代表1セッションを見れば十分。

## 直近/今日の作業まとめ(頻度は低いが対応可能)

「今日/直近何をしたか」を要約する場合、まず対象ファイル数(=作業の本数)を把握してから読み方を決める。
`ctx show` をセッションごとに呼ぶのはファイル数が多いと非効率(呼び出し回数・トークン消費が線形に増える)。

1. まず件数を数える(重い処理はしない):
   ```sh
   ctx sql "SELECT source_path, COUNT(*) FROM ctx_events
            WHERE event_type='message' AND role='user'
              AND occurred_at_ms >= <today-start-epoch-ms>
              AND source_path LIKE '%<repo-name>%'
            GROUP BY source_path" --format table
   ```
   (`<today-start-epoch-ms>` はローカル日付の00:00をmsで。`date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 00:00:00" +%s` 等を1000倍する)
2. 対象ファイルが**少ない場合(目安10件以下)**: 上記のトピック検索 → ファイルごとに代表 `ctx_session_id` を1つ選び
   `ctx show session --mode lite` で本文を読む(通常の流れ)
3. 対象ファイルが**多い場合(目安10件超)**: `ctx show` を連発せず、SQLで全ファイル分の冒頭ユーザーメッセージを
   一括取得してから要否を選別する:
   ```sh
   ctx sql "SELECT source_path, ctx_session_id, MIN(occurred_at_ms) as first_ts, payload_json
            FROM ctx_events
            WHERE event_type='message' AND role='user'
              AND occurred_at_ms >= <today-start-epoch-ms>
              AND source_path LIKE '%<repo-name>%'
            GROUP BY source_path ORDER BY first_ts" --format json --max-value-bytes 800
   ```
   `payload_json` 内の `body.content_preview.text` が冒頭メッセージのプレビュー。これでトピックの見当がつく。
   込み入った内容・要約に自信が持てないものだけ `ctx show session --mode lite` で深掘りする。
