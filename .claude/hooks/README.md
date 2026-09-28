# hooks

`settings.json` の `deny` は文字列の前方一致しか見ない。`Bash(pip install *)` を置いても、`/tmp/venv/bin/pip install x` や `make setup && pip install x` は一致しない。**禁止したい対象が文字列ではなく行為であるとき**にフックで判定する。

各フックが何を塞ぐかは、そのファイルの冒頭コメントが正本である。一覧表は持たない。登録（matcher とタイムアウト）は `../settings.json`。`home-manager/modules/claude.nix` が `~/.claude` へ配る。

## 書くときの型

**判定はコマンド位置で行う。** 引用符の中身を先に落とし（コミットメッセージに `pip install` と書いただけで発火させない）、照合を行頭か `;` `|` `&` `` ` `` `$(` の直後に限る。パス付き実行と `sudo` / `env` の前置も吸収する。`block-non-nix-install.sh` が実例。

**拒否メッセージを分岐器として書く。** Agent は拒否されると別の手を試し、何を試すかは拒否文で決まる。`permissionDecisionReason` には理由と代替手順の両方を入れる。壁を立てるだけなら `deny` で足りる。フックの利得は、拒否と同時に正しい経路へ寄せられる点にある（`block-live-claude-config-edit.sh` は編集先を正本のパスへ書き換えて返す）。

回帰テストは `tests/` に置く。ペイロードを実際に流して、塞ぐべきものが通らず、読み取りを誤爆しないことを確かめる。
