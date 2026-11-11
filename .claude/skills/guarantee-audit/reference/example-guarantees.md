この下の区切り線から先が `docs/guarantees/` のサンプル（ダミーの `packages/example/` を対象とした汎用化サンプル）。入口の `README.md` と、約束の対象ごとのファイル2つからなる。実在のリポではパッケージ名・関数名・テスト名をそのリポのものに置き換える。

## サンプルから読み取るべきポイント

- **README は台帳を初めて開いた人が決まりを読み取れるように書く**。目的・分け方・書き方を数行ずつ置き、ファイルの一覧・Gaps・About を続ける。書き足す人が README だけを読んで、どのファイルに何を足すかを決められる状態にする。
- **ファイルは約束の対象ごと**。テストファイルの単位でも Issue の単位でもない。サンプルでは `load_widget` と `Widget`/`WidgetRegistry` が別の対象で、テストが1つのファイルにあっても対象ごとに分ける。
- **対象のファイルは H1 と表1つだけ**。表の外に宣言の本文を書かない。表の1行が約束の全文で、要約ではない。
- **1行に約束を1つ**。「A し、B し、C する」と書きたくなったら行を分ける。
- 主語は行ごとに書く。ファイルが単一の関数だけを扱うなら省いてよい（サンプルの `loader.md`）。
- **Gaps は本体と明確に区別**し、なぜ未保証と判断したかが分かる粒度で書く。空になったら節ごと削除する（「無し」と書き残さない）。
- 見出しは英語（`# Guarantee Ledger`・`## Files`・`## Gaps`・`## About`）、対象のファイルの H1 は対象の名前。

---

`docs/guarantees/README.md`:

```markdown
# Guarantee Ledger

このリポが外へ約束している振る舞いと、それを守るテストの一覧である。約束が破れればテストが落ちるので、
ここに書いたことは気づかないうちに実装とずれていかない。**ここに載っていない振る舞いは約束ではなく、予告なく変わりうる。**

- 目的: いま何を約束しているかを1か所で読む。変更の前に、壊してはいけない約束をここから引く。テストの無い約束を Gaps に残す
- 分け方: 約束の対象（モジュール・公開 API の群・CLI のコマンド）ごとに1ファイル。テストファイルや Issue の単位では分けない。新しい対象を作ったときだけファイルを足す
- 書き方: 各ファイルに「保証｜対応テスト」の表を1つ置き、1行に約束を1つ、宣言文で書く。出典・経緯・設計の理由は書かない（`docs/design-decisions.md` が持つ）。UI の見た目と、手で確かめる操作は載せない

## Files

| 約束の対象 |
|---|
| [loader](loader.md) |
| [widget](widget.md) |

## Gaps

- `load_widget` は相対パスを渡した場合の解決基準（呼び出し元の cwd 基準か、モジュール基準か）が未保証
- `WidgetRegistry` のスレッドセーフ性（並行 `register` 呼び出し時の挙動）が未保証

## About

対象は `packages/example/` の公開関数・クラスとその送出例外。対象外はアンダースコア始まりの関数・メソッドと `app/` 配下（未着手）。地位は design-decisions.md 相当のドキュメントと同格。
```

`docs/guarantees/loader.md`（単一の関数だけを扱うので、主語の `load_widget` を省く）:

```markdown
# loader

| 保証 | 対応テスト |
|---|---|
| 存在する YAML パスを渡すと `Widget` を返し、`name`・`size` をそのまま持つ | `test_load_widget_parses_yaml` |
| 拡張子が `.yaml`・`.yml` 以外のパスは `ValueError` を送出する | `test_load_widget_rejects_bad_extension` |
| ファイルが無ければ `FileNotFoundError` を送出する | `test_load_widget_missing_file` |
```

`docs/guarantees/widget.md`（2つのクラスを扱うので、行ごとに主語を書く）:

```markdown
# widget

| 保証 | 対応テスト |
|---|---|
| `Widget.render()` は `size` に応じてインデントした文字列を返す | `test_widget_render_indents_by_size` |
| `WidgetRegistry.register(widget)` は同名の `Widget` が登録済みなら `KeyError` を送出する | `test_registry_rejects_duplicate_name` |
| `WidgetRegistry.get(name)` は未登録の名前に `None` を返す | `test_registry_get_returns_none_for_unknown` |
```
