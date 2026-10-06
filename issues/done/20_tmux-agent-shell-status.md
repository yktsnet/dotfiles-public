## tmux のエージェント表示と M-u ピッカーで、status `shell` を idle として扱う
id: 20
branch-slug: tmux-agent-shell-status
github_issue:
status: close
type: fix
対象:
- home-manager/modules/tmux.nix（L8-18 の `claudeSessionManager`、L144-166 の `agentStatus`）
内容: Claude Code はターンを終えてバックグラウンドのシェルやサブエージェントだけが残っている状態を `claude agents --json` の `status: "shell"` で報告する。user の番なのに、status-right のチップは作業中の色（赤系）になり、M-u ピッカーは未知の状態として灰色の `?` を出す。どちらも `shell` を idle と同じ扱いにする。
対象外: status-right 以外の `claude agents` の利用箇所（L110 付近の nudge ピッカーは status を文字列のまま表示するだけなので触らない）。プラグインの rev 更新。
仮定: status-right のチップには `shell` を区別する印を付けない。既存のコメントが「状態が変わってもチップ幅が動かない」ことを求めているため、区別は M-u ピッカーの表示（`idle+sh`）で行う。
確認: `nix flake check`。あわせて、下の jq 式に `shell` を含むサンプル JSON を流し、`shell` のチップが idle の色で idle と同じ順位に並ぶことを確かめる。

---

### 保証
- 新たに宣言する保証:
  - status-right で、`status: "shell"` のエージェントのチップが idle と同じ色で表示され、並び順も idle と同じ位置（waiting の後、作業中の前）になる
  - M-u ピッカーで、`status: "shell"` のエージェントが緑の `● idle+sh` として表示され、idle と同じ順位に並ぶ
- 維持する保証:
  - waiting・idle・busy の色と並び順は変わらない
  - status を持たないセッション（Remote Control）は、引き続きどちらの表示にも出ない
  - waiting・idle・busy・shell 以外の未知の status は、status-right では作業中の色、M-u では灰色の `?` のままになる

自動テストは無い（tmux の表示を検査する仕組みがこのリポに無い）。上の jq の確認と、user の rebuild 後の目視で確かめる。

### `agentStatus`（L150-166）

`rank` と `chip` の両方で `shell` を idle と同じ分岐に入れる。`else`（作業中扱い）に落とさない。L144 からのコメントに、`shell` が何を表すか（ターンを終え、バックグラウンドの作業だけが残っている状態）を1行足す。

### `claudeSessionManager`（L8-18）

`postInstall` を足し、プラグインの `scripts/agents.sh` の状態判定に `shell` の分岐を入れる。`--replace-fail` は一致しないとビルドが落ちるので、文字列は次のとおりにする（プラグインの rev `ac3470e` の `agents.sh` で一致を確認済み）。

```nix
    # `shell` はターンを終えてバックグラウンドの作業だけが残っている状態で、user の番である。
    # プラグインは知らない状態として灰色の ? にするので、idle と同じ扱いの分岐を足す。
    postInstall = ''
      substituteInPlace $target/scripts/agents.sh \
        --replace-fail 'else if ($3 == "busy")' 'else if ($3 == "shell")   { icon = "\033[32m●\033[0m idle+sh"; rank = 1 } else if ($3 == "busy")'
    '';
```

`idle+sh` は既存のラベル（`waiting` / `idle   ` / `working`）と同じ7文字なので、列はずれない。

## 検証手順（PR 本文用）
- macbook で rebuild したあと、Claude にバックグラウンドのコマンド（例: `sleep 60` を `run_in_background` で）を走らせてターンを終えさせる
- その間、status-right のチップが idle の色になり、M-u に `● idle+sh` と出ることを目視で確かめる
