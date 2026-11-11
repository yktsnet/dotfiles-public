この下の区切り線から先が `docs/guarantees/` のサンプル（ダミーの `packages/example/` を対象とした汎用化サンプル）。入口の `README.md` と、約束の対象ごとのファイル2つからなる。実在のリポではパッケージ名・関数名・テスト名をそのリポのものに置き換える。

## サンプルから読み取るべきポイント

- **README は台帳を初めて開いた人が決まりを読み取れるように書く**。目的・分け方・書き方・運用を数行ずつ置き、ファイルの一覧と、テストの無い約束があれば Gaps を続ける。末尾に About は置かず、対象範囲は冒頭に書く。書き足す人が README だけを読んで、どのファイルに何を足すかを決められる状態にする。
- **ファイルは約束の対象ごと**。テストファイルの単位でも Issue の単位でもない。サンプルでは `load_widget` と `Widget`/`WidgetRegistry` が別の対象で、テストが1つのファイルにあっても対象ごとに分ける。
- **対象のファイルは H1 と表だけ**。表の外に宣言の本文を書かない。表の1行が約束の全文で、要約ではない。約束が10行以上のファイルは、`##` の見出しで内容のまとまりに分け、見出しごとに表を置く（1つの見出しに3行以上。10行未満なら見出しを置かない）（下の `registry` の見本）。ファイルは分けない。
- **1行に約束を1つ**。「A し、B し、C する」と書きたくなったら行を分ける。
- 主語は行ごとに書く。ファイルが単一の関数だけを扱うなら省いてよい（サンプルの `loader.md`）。
- **Gaps は本体と明確に区別**し、なぜ未保証と判断したかが分かる粒度で書く。空になったら節ごと削除する（「無し」と書き残さない）。
- 見出しは英語（`# Guarantee Ledger`・`## Files`・`## Gaps`）、対象のファイルの H1 は対象の名前。

---

`docs/guarantees/README.md`:

```markdown
# Guarantee Ledger

このリポが外へ約束している振る舞いと、それを守るテストの一覧である。約束が破れればテストが落ちるので、
ここに書いたことは気づかないうちに実装とずれていかない。**ここに載っていない振る舞いは約束ではなく、予告なく変わりうる。**
対象は `packages/example/` の公開関数・クラスとその送出例外で、アンダースコア始まりの関数・メソッドと `app/` 配下（未着手）は対象外である。地位は `docs/design-decisions.md` と同格。

- 目的: いま何を約束しているかを1か所で読む。変更の前に、壊してはいけない約束をここから引く。テストの無い約束を Gaps に残す
- 分け方: 約束の対象（モジュール・公開 API の群・CLI のコマンド）ごとに1ファイル。テストファイルや Issue の単位では分けない。新しい対象を作ったときだけファイルを足す
- 書き方: 各ファイルに「保証｜対応テスト」の表を1つ置き、1行に約束を1つ、宣言文で書く。出典・経緯・設計の理由は書かない（`docs/design-decisions.md` が持つ）。UI の見た目と、手で確かめる操作は載せない。約束が10行以上のファイルは、内容のまとまりで `##` の見出しを立て、見出しごとに3行以上の表を置く（ファイルは分けない）
- 引き方: 変更の前に、その対象のファイルを開いて守る約束を読む。テストが落ちたら、テストの名前で台帳を検索すると、破れた約束の行が見つかる
- 運用: 変更の前にこの README を読み、変更が触れるファイルから「維持する保証」を引く。約束を足す・変える・消すときは、承認を受けた保証節の文のまま、該当するファイルの表に行を足す・直す・消し、対応テストも同じ変更で直す。Issue や作業ごとにファイルや節を起こさない。テストの無い約束は Gaps に書き、テストを足したら移す。乖離は `guarantee-audit` で棚卸しする

## Files

| 約束の対象 |
|---|
| [loader](loader.md) |
| [widget](widget.md) |

## Gaps

- `load_widget` は相対パスを渡した場合の解決基準（呼び出し元の cwd 基準か、モジュール基準か）が未保証
- `WidgetRegistry` のスレッドセーフ性（並行 `register` 呼び出し時の挙動）が未保証
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

約束が10行以上のファイルの見本（見出しごとに表を置く。行は一部だけ載せている。実物では1つの見出しに3行以上が入る）。`docs/guarantees/registry.md`:

```markdown
# registry

## 登録

| 保証 | 対応テスト |
|---|---|
| `WidgetRegistry.register(widget)` は同名の `Widget` が登録済みなら `KeyError` を送出する | `test_registry_rejects_duplicate_name` |

## 照会

| 保証 | 対応テスト |
|---|---|
| `WidgetRegistry.get(name)` は未登録の名前に `None` を返す | `test_registry_get_returns_none_for_unknown` |
```
