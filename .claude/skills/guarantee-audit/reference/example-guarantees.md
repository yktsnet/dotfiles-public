この下の区切り線から先が `docs/guarantees.md` のサンプル（ダミーの `packages/example/` を対象とした汎用化サンプル）。実在のリポではパッケージ名・関数名・テスト名をそのリポのものに置き換える。

## サンプルから読み取るべきポイント

- **見出し（H1〜H3）は英語、本文（箇条書き・表・注釈）は日本語**。見出しの丸括弧も半角 `()` を使う（全角「（）」は本文のみ）。
- **区切りは常にテストファイル単位**。`### N. \`tests/....py\` — target module/class (function)` の形式で、ファイルパスは常にバッククォートで囲む。
- **主語の反復ルール**: 区切り内が単一の関数・メソッドだけを扱うなら、箇条書きのたびに主語（関数名）を書き直さない（サンプルの区切り1）。区切り内に複数の異なる関数・メソッドが混在するなら、行ごとに主語を明示する（サンプルの区切り2）。前者で毎回主語を書くと型の反復になり、後者で主語を省くとどの対象の保証か分からなくなる。
- **本文の項目数と表の行数は一致させる**（1行に複数保証をまとめて集約した場合を除き、単純に「本文にあるのに表に無い」が起きないようにする）。
- **表は索引であって保証の宣言場所ではない**。「保証（要約）」列は本文の言い換えの短縮形であり、そこだけ読んでも保証の全文にはならない。
- **Gaps は本体と明確に区別**し、なぜ未保証と判断したかが分かる粒度で書く。空になったら節ごと削除する（「無し」と書き残さない）。
- **About は注釈程度に短く**。対象範囲・対象外・欠落の意味論を1〜2文にまとめる。「対象範囲」「対象外」を別見出しに割らない。

---

# Guarantee Ledger

## Guarantees

### 1. `tests/example/test_loader.py` — packages/example/loader.py (load_widget)

- 存在する YAML パスを渡すと `Widget` インスタンスを返し、`name`/`size` フィールドをそのまま反映する
- 拡張子が `.yaml`/`.yml` 以外のパスは `ValueError` を送出する
- ファイルが存在しない場合は `FileNotFoundError` を送出する

| 保証（要約） | 対応テスト |
|---|---|
| YAML から `Widget` を復元 | `test_load_widget_parses_yaml` |
| 拡張子検証 | `test_load_widget_rejects_bad_extension` |
| 存在しないファイル | `test_load_widget_missing_file` |

*（区切り内は `load_widget` 一つだけなので、箇条書きのたびに「`load_widget` は」を繰り返さない）*

### 2. `tests/example/test_widget.py` — packages/example/widget.py (Widget / WidgetRegistry)

- `Widget.render()` は `size` に応じてインデントされた文字列を返す
- `WidgetRegistry.register(widget)` は同名の `Widget` が既に登録されていると `KeyError` を送出する
- `WidgetRegistry.get(name)` は未登録の名前に対して `None` を返す

| 保証（要約） | 対応テスト |
|---|---|
| レンダリング | `test_widget_render_indents_by_size` |
| 重複登録の拒否 | `test_registry_rejects_duplicate_name` |
| 未登録名の照会 | `test_registry_get_returns_none_for_unknown` |

*（区切り内に `Widget.render` と `WidgetRegistry` の2メソッドが混在するので、行ごとに主語を明示する）*

## Gaps

以下は保証すべきと思われるが、対応するテストが無い。

- `load_widget` は相対パスを渡した場合の解決基準（呼び出し元の cwd 基準か、モジュール基準か）が未保証
- `WidgetRegistry` のスレッドセーフ性（並行 `register` 呼び出し時の挙動）が未保証

## About

対象は `packages/example/` の公開関数・クラスとその送出例外。対象外はアンダースコア始まりの関数・メソッドと `app/` 配下（未着手）。**ここに載っていない振る舞いは約束ではなく、予告なく変わりうる。** 地位は design-decisions.md 相当のドキュメントと同格。
