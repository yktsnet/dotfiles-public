## マスク辞書の配布機構（secrets-agents.nix）と sops-secrets skill を公開する
id: 15
branch-slug: secrets-agents-dictionary
github_issue:
status: open
type: feat
対象:
- home-manager/modules/secrets-agents.nix (新規)
- .claude/skills/sops-secrets/SKILL.md (新規)
- .claude/skills/sops-secrets/references/linux.md (新規)
- .claude/skills/sops-secrets/references/macos.md (新規)
- devices/gui/macbook/home.nix
- devices/gui/home.nix
- README.md
- README.en.md
内容: Issue 14 で敷いた sops レイヤの上に、マスク辞書（`secrets-agents/`）を全デバイスへ配る機構を載せる。README は「実値はローカルの `secrets-agents/` に隔離する」と書いているが、辞書がローカルにしか無いとデバイスを移った途端に「何を伏せるべきか分からないまま」Issue / PR を書くことになる。暗号文を git 経路に載せ、各機が自分の age 鍵で復号する形を公開する。あわせて、その運用手順である `sops-secrets` skill を公開する。
確認: `nix flake check`（評価エラーの検出）、目視確認（skill 本文に固有の接続情報・実カテゴリ名・実デバイス名が残っていないこと、`references/` 2本の参照リンクが解決すること、README 日英の記述内容が一致すること）。実際の復号確認は user が macbook / linux-desktop で rebuild して行う。

**前提: Issue 14 が close していること。** `devices/secrets.nix` の `hmManagedCategories` による `agents` カテゴリの除外と、sops-nix の module 配線が済んでいないと本 Issue は成立しない。

---

### 保証
- 新たに宣言する保証:
  - `secrets/agents/` 配下の `.age` ファイルは、`secrets-agents.nix` の変更なしに1つずつ復号先へ配置される（ファイルを足すだけで増える）
  - 復号先は `/run/secrets` ではなくリポジトリ内の `secrets-agents/` である。CLAUDE.md の機密マスク規則が参照先をそこに固定しているため
  - 復号されたファイルのパーミッションは `0400`（所有者読み取りのみ）である
  - 復号先ディレクトリは `.gitignore` 済みで、平文の辞書が git に乗らない
  - 同じカテゴリが system 側（`devices/secrets.nix`）と home-manager 側の両方で復号されることはない
- 維持する保証:
  - Issue 14 で宣言した secret の登録規則（カテゴリ自動スキャン・拡張子による format 判定）を変えない
  - 本リポに実際の暗号文（`.age`）をコミットしない方針を変えない
  - `.claude/settings.json` の `secrets/` に対する deny を緩めない

**テスト欠落について（裁可済み・見送る）**: 「復号先が `secrets-agents/` である」「パーミッションが `0400`」「二重復号が起きない」は外部から観測可能な契約だが、`nix flake check` は評価エラーの検出までで実際の復号結果を検証せず、妥当なテスト手段が本リポに無い。裏付けテストを含めない。**「二重復号が起きない」は Issue 14 の `hmManagedCategories` による除外に依存しているので、実装時にその除外が効いていることを目視で確認すること。**

### 背景

マスク辞書は「Issue / PR の地の文で実値の代わりに何を書くか」を引くためのもので、Agent がそれを読めなければマスク規則そのものが機能しない。私物では以前これを平文のまま gitignore していたため、辞書は1台にしか存在せず、別のデバイスで Issue / PR を書くと**何を伏せるべきか分からないまま**書くことになっていた。

解決は、暗号文を git 経路に載せて各機が自分の age 鍵で復号する形にすること。ただし復号先は `/run/secrets` ではいけない。CLAUDE.md の機密マスク規則が参照先をリポジトリ内の固定パスとして書いているためで、system 側の sops ではなく home-manager 側でそこへ復号する必要がある。だから Issue 14 の `devices/secrets.nix` は `agents` カテゴリを除外している（両方で拾うと二重復号になる）。

### skill の一般化をどこまでやるか（裁可済み）

`sops-secrets` skill（89行 + references 2本）は私物の運用手順そのもので、公開にあたって落とす／置き換える必要がある固有情報が多い。

**落とすもの**（辞書 `secrets-agents/` の対象そのもの、または私物の履歴）:

- 既存カテゴリの実名（旧方式で binary 固定になっているカテゴリ名の列挙）→ 「binary 固定にしたいカテゴリ」という一般形にする
- 実デバイス名（`neo` / `het` / `T14` 等）→ `macbook` / `linux-server-a` / `linux-desktop` の役割名にする
- 同期コマンド `to <対象デバイス>` → 本リポで公開している範囲の表現に直す
- クロスビルド委譲の記述（macOS から x86_64 を特定サーバへ投げる）→ 本リポの構成に無い運用なので落とす

**残すもの**（この skill の価値の中心。削ると単なる sops のチュートリアルになる）:

- **復号を前提にしない順序**の節。`inject` は暗号化に成功すると元の平文を自分で消すため、同期先への配布を先に終わらせないと後から取り戻せない。「念のため」ではなく必須の順序であること
- Agent に `sops --decrypt` を許可していないこと、値が必要になった時点で詰むので**最初から復号が要らない順序**で進めること、途中で詰まったら回避せず user に渡すこと
- 値をコマンド文字列に直接埋め込まず `@<ファイルパス>` でファイル参照にすること
- `.json.age` だけ Read/Edit/Write を許可している理由（常に暗号文であること）と、その直前に `backup-secret-json.sh` が働くこと。この安全網は Issue 09 で公開済みなので、参照が繋がる
- 新デバイス追加時の順序（鍵登録 → 既存 secret 再暗号化 → ビルド）と、誤ると復号できないまま home-manager が壊れること
- Home Manager から secret を参照するとき `/run/secrets/...` を文字列で直書きしない（`mkOutOfStoreSymlink` + `osConfig.sops.secrets."<KEY>".path` を使う）

`references/linux.md` / `references/macos.md` は OS ごとの手順とエラー別対処。**RAM ディスクの作り方（macOS は `/dev/shm` が無いので `hdiutil` で作る）は残す。** 平文をディスクバックの領域に置かない原則の実装なので、これが無いと安全規則が宙に浮く。

frontmatter の `allowed-tools` は `inject.py` のパスを含む。本リポでも `apps/zsh/inject.py` は公開済み（Issue 08）なので、パス表記を本リポの形に直したうえで残す。

`disable-model-invocation` は**付けない**（裁可済み）。この skill の description は「secret を触るとき・sops 関連エラーの対処時に必ず使用する」であり、自動発火してこそ事故を防ぐ性格のもの。Issue 12 の `skill-dev` / `module-dev` と同じく `block-new-skill-md.sh` に拒否されるため、Write → Edit の順で作ること。

### 仕様

#### home-manager/modules/secrets-agents.nix（新規）

コピー元: `~/dotfiles/home-manager/modules/secrets-agents.nix`（32行）。

`secrets/agents/` を走査し、`.age` ごとに `sops.secrets` のエントリを組み立てる。`format = "binary"`、`mode = "0400"`、`path` はリポジトリ内の辞書ディレクトリ。

冒頭のコメントが**この module の存在理由そのもの**（なぜ `/run/secrets` ではないのか、以前どう壊れていたのか、なぜ system 側で除外しているのか）を説明している。移植時に落とさないこと。ただし私物のデバイス名（`neo` / `sv6`）は役割名に置き換える。

`secrets/agents/` が存在しない場合の扱いを決める必要がある。Issue 14 と同じく、**空でも評価が通ること**を確認すること。

#### .claude/skills/sops-secrets/ 一式（新規3ファイル）

上記の方針で移植する。frontmatter の扱いは前節のとおり（自動発火のまま、Write → Edit）。

#### devices/gui/macbook/home.nix / devices/gui/home.nix

`imports` に `secrets-agents.nix` を足す。`claude.nix` を imports している2箇所に合わせる（マスク規則は Claude のハーネスに属するため）。`devices/headless/home.nix` には足さない。

#### README.md / README.en.md

Foundation の「機密情報の分離」の項に1〜2文足す。現状は「実値はローカルの `secrets-agents/` に隔離し、地の文では `<PLACEHOLDER>` を用いる」で終わっている。

含めること。

- 辞書は平文でローカルに置くのではなく、暗号化して git 経路に載せ、各デバイスが自分の鍵で復号する
- 辞書が1台にしか無いと、別のデバイスでは「何を伏せるべきか分からないまま」書くことになる。マスク規則を機能させるには辞書自体が全機に届いている必要がある

**箇条書き1項目の中に収める。** Foundation は4項目の並びで密度が揃っているので、ここだけ長くしない。

### 実装順序

1. `home-manager/modules/secrets-agents.nix`（空スキャン経路の確認込み）
2. `devices/gui/macbook/home.nix` / `devices/gui/home.nix` の imports
3. `nix flake check`
4. `.claude/skills/sops-secrets/SKILL.md`（一般化を適用）
5. `references/linux.md` / `references/macos.md`
6. skill 本文を grep して、固有のデバイス名・カテゴリ名・パスが残っていないことを確認
7. `README.md` → `README.en.md`
