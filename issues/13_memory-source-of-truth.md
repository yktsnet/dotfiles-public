## 永続メモリの正本管理（memory.nix）を公開する
id: 13
branch-slug: memory-source-of-truth
github_issue: 41
status: close
type: feat
対象:
- home-manager/modules/memory.nix (新規)
- devices/gui/macbook/home.nix
- devices/gui/home.nix
- .gitignore
- docs-agents/harness-guide.md
- docs-agents/harness-guide.en.md
内容: 本リポは永続メモリについて「索引を再生成する `sync-memory-index.sh`」と「置き場違いを拒否する `block-project-scoped-memory.sh`」の2フックを公開しているが、**正本そのものをどう持つか**の実装が無い。私物側は `~/memory` を dotfiles 配下の実体へのシンボリックリンクにして、複数デバイス間の同期と衝突解決を git 経路に載せている。この module を公開し、harness-guide の該当節から参照させる。
確認: `nix flake check`（評価エラーの検出）、目視確認（`harness-guide.md` 4.5 相当節の記述と module の実装が一致すること、日英の記述内容が一致すること）。実際の symlink 生成確認は user が macbook / linux-desktop で rebuild して行う。

---

### 保証
- 新たに宣言する保証:
  - `~/memory` が存在しないとき、dotfiles 配下の実体への symlink を新規作成する
  - `~/memory` が既に symlink のとき、リンク先を dotfiles 配下の実体へ張り替える
  - `~/memory` が**実体のディレクトリ**として存在するとき、何も削除せず・上書きせず、退避を促すメッセージを標準エラーへ出して activation を継続する
  - dotfiles 配下に実体（`memory/`）が無いとき、警告を出して activation を継続する。activation 全体を失敗させない
- 維持する保証:
  - `sync-memory-index.sh`（SessionStart で `MEMORY.md` を frontmatter から再生成）の挙動を変えない
  - `block-project-scoped-memory.sh`（プロジェクトスコープへの書き込みを拒否し正しい配置先を返す）の挙動を変えない
  - 既存の home-manager モジュールの activation 順序に影響を与えない

**テスト欠落について（裁可済み・見送る）**: 上記4つは activation script の外部から観測可能な契約（特に「実体があるとき何も壊さない」は失うと実害が出る）だが、`nix flake check` は評価エラーの検出までで実行時の分岐を検証せず、activation を対象にした妥当なテスト手段が本リポに無い。裏付けテストを含めない。**「実体があるとき何も削除・上書きしない」は失うと実害が出るため、実装時に分岐を `ln -sfn` へ一本化しないこと**（テストが無い以上、ここはコードの形で守る）。

### `memory/` の実体は公開せず、module は配線する（裁可済み）

私物側の `memory/` の中身は user 個人の事実（`user` / `feedback` / `project` / `reference` の4型）であり、**公開しない**。したがって本リポで module を imports に足すと、実体が無い状態で rebuild され、毎回「実体が無い」旨の警告が出る。

**裁可の結果、module を公開し imports にも足す。** 実体が無い環境では警告が出るが activation は継続する（module 側でそう作ってある）。利用者は自分の `memory/` を作れば警告が消える。`.gitignore` に `memory/` を足し、実体が誤ってコミットされないようにする。

警告文は私物前提の文面（「dotfiles を pull してから再実行すること」）になっているので、公開版では「`memory/` を作るか、この module を imports から外すこと」と読める文面に直す。

### 背景

`docs-agents/harness-guide.md` の永続メモリの節には既に次の3点が書いてある。

- 正本は `~/memory/`。1ファイル1事実で型ごとにサブディレクトリを分ける
- 索引 `~/memory/MEMORY.md` は生成物であって手書きしない
- 生成（`sync-memory-index.sh`）と遮断（`block-project-scoped-memory.sh`）は別の対策で、両方要る

書かれていないのは「`~/memory/` という**場所**をどう用意するか」である。私物では複数デバイスで同じメモリを共有する必要があり、`~/memory` を実体で持つとデバイスごとに別々のメモリが育つ。そこで dotfiles リポの中に実体を置き、`~/memory` はそこへの symlink にしてある。結果として、メモリの同期と衝突解決は git がそのまま担う（フック類は `$HOME/memory` を参照したままでよい）。

### 仕様

#### home-manager/modules/memory.nix（新規）

コピー元: `~/dotfiles/home-manager/modules/memory.nix`（18行）。

`home.activation` の `lib.hm.dag.entryAfter [ "writeBoundary" ]` で symlink を張る。**`home.file` を使わない。** 理由は既存実体・既存リンクと衝突したときに activation 全体が落ちるためで、同じ理由で `claude.nix` も activation script を使っている。この判断はコメントとして残っているので、移植時に落とさないこと。

分岐は4通り（実体が無い / すでに symlink / 実体が存在 / 何も無い）。**「実体が存在する」ケースで削除も上書きもしない**のが要点で、ここを `ln -sfn` に一本化しない。

公開にあたり、警告文2つを本リポの文脈に合わせて書き換える。

- 実体が無い場合: 私物は「dotfiles を pull してから再実行すること」。公開版は「`memory/` を作るか、この module を imports から外すこと」相当に直す
- 実体が存在する場合: 「内容を退避・統合してから削除すること」は公開版でもそのままでよい

#### devices/gui/macbook/home.nix / devices/gui/home.nix / .gitignore

`imports` に `memory.nix` を足す。**`claude.nix` を imports している場所に合わせる**（メモリは Claude のハーネスに属するため）。現状 `claude.nix` は `devices/gui/macbook/home.nix` と `devices/gui/home.nix` の2箇所にあり、`devices/headless/home.nix` には無い。headless には足さない。

`.gitignore` に `memory/` を足す。

#### docs-agents/harness-guide.md / harness-guide.en.md

永続メモリの節（`~/memory/` が正本であることと2フックを説明している箇所）に、**正本の置き方**を1段落足す。既存の記述順（正本 → 索引は生成物 → 置き場違いの遮断 → 生成と遮断は両方要る）を崩さず、正本の説明の直後に入れる。

含めること。

- `~/memory` は実体ではなく dotfiles 配下へのシンボリックリンクである。実体をリポの中に置くことで、複数デバイス間の同期と衝突解決を git に任せる
- 張るのは `home-manager/modules/memory.nix` の activation script。既存実体があるときは壊さず退避を促して止まる
- フック類は `$HOME/memory` を参照したままでよい（symlink なので参照先の変更が要らない）

3〜4文に収める。この節は既に長い。

### 実装順序

1. `home-manager/modules/memory.nix`（警告文の書き換え込み）
2. `devices/gui/macbook/home.nix` / `devices/gui/home.nix` の imports と `.gitignore`
3. `nix flake check`
4. `docs-agents/harness-guide.md` → `harness-guide.en.md`
