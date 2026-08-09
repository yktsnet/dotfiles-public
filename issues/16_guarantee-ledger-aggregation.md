## 保証台帳をフリート横断で集約する仕組みを公開する
id: 16
branch-slug: guarantee-ledger-aggregation
github_issue:
status: open
type: feat
対象:
- apps/lpt/link_guarantees.py (新規)
- apps/lpt/tests/test_link_guarantees.py (新規)
- apps/lpt/README.md (新規)
- home-manager/modules/guarantees.nix (新規)
- .github/workflows/ci.yml
- devices/gui/macbook/home.nix
- devices/gui/home.nix
- docs-agents/test-policy.md
- docs-agents/test-policy.en.md
内容: 本リポは Guarantee-Driven Development を README の中核に据え、`docs-agents/test-policy.md` で保証台帳（`docs/guarantees.md`）の書き方を公開しているが、扱いは**1リポの中の1ファイル**に閉じている。実際には台帳は複数リポに散っており、私物側では rebuild のたびに全リポを走査して1箇所へ集約している。この集約機構を公開し、GDD がリポ単位ではなくフリート単位の運用であることを示す。
確認: `pytest apps/lpt/tests/`（後述の保証のうちテスト可能なものを裏付ける）、`nix flake check`（評価エラーの検出）、目視確認（集約先パスが設定可能になっていること、`test-policy` 日英の記述内容が一致すること）。実際の symlink 生成確認は user が macbook / linux-desktop で rebuild して行う。

---

### 保証
- 新たに宣言する保証:
  - 走査対象のディレクトリのうち存在しないものは黙って読み飛ばす（例外で落ちない）
  - 同名のリポジトリが複数の走査対象に存在する場合、優先順位が最も高い1つが接頭辞なしの名前を取り、残りは走査元のディレクトリ名を接頭辞に付けた名前になる（名前の衝突が起きない）
  - 集約先ディレクトリ自身とその親は走査対象から除外される（自己参照・再帰を作らない）
  - 前回実行時から台帳の集合と更新時刻のいずれも変化していない場合、symlink を作り直さず終了する
  - 張るのは相対パスの symlink であり、実体をコピーしない（台帳の正本は各リポに残る）
  - キャッシュファイルが壊れている場合、例外で落ちずに再生成へ進む
  - 集約先ディレクトリと走査対象は環境変数または設定で変更でき、コード内にハードコードされた個人のディレクトリ名を持たない
- 維持する保証:
  - `docs-agents/test-policy.md` が定義する保証台帳の書式・裁可フロー（保証の宣言は user が Issue の保証節で裁可し、テストの実装は Agent が書く）を変えない
  - 既存の home-manager モジュールの activation 順序に影響を与えない
  - 集約は読み取りと symlink 生成のみで、各リポの `docs/guarantees.md` を書き換えない

**テストについて（裁可済み・本 Issue で足す）**: 上記の保証のうち「走査対象が無くても落ちない」「衝突時の命名規則」「自己参照を作らない」「変化が無ければ作り直さない」「相対 symlink を張る」「キャッシュが壊れていても落ちない」は、`tmp_path` に擬似的なリポ構造を作れば入出力が閉じた形で検証できる。**本リポで最初の Python テストとして足す。** GDD を駆動文書に据えたリポにテストが1本も無い状態を、検証可能な保証を持つこの Issue で解消する。

環境変数から受け取る設計（後述）にすることで、テスト側は実際のホームディレクトリに触れずに済む。**この点はテスト容易性が設計を決めている**ので、パスをモジュール定数に戻さないこと。

### 背景

README は開発を2フェーズに分け、Issue ドリブン期の駆動文書を保証台帳（`docs/guarantees.md`）としている。「台帳は何を約束し何を約束していないかだけを記し、各約束は対応するテストが継続検証する」という説明で、`test-policy.md` がその書式と裁可フローを持つ。

ここまでは1リポの中の話として完結している。実際に複数のリポを並行して回すと、台帳は各リポの `docs/guarantees.md` に散らばり、**「今フリート全体で何を約束しているか」を一望する場所が無くなる**。台帳を作った目的（約束を人間が裁可する）に照らすと、裁可する側が全体を見られないのは片手落ちになる。

私物では home-manager の activation script が rebuild のたびに走査スクリプトを呼び、複数の走査対象を優先順位付きで見て、見つかった台帳への symlink を1つのディレクトリに張っている。実体をコピーせず symlink にしているのは、正本を各リポに残したまま一望できるようにするため。

### 集約先と走査対象は環境変数で受け取る（裁可済み）

移植元のスクリプトは、走査対象4つと集約先とキャッシュファイルのパスを**モジュール先頭の定数にハードコードしている**。中身は user 個人のディレクトリ構成（公開・非公開・clone 用の3ディレクトリとホーム直下）であり、そのままでは公開物にならない。

案は2つ。

1. **環境変数で受け取り、既定値を汎用にする。** `GUARANTEES_TARGET_DIR` / `GUARANTEES_SEARCH_DIRS`（`:` 区切り、順序がそのまま優先順位）/ `GUARANTEES_CACHE_FILE` を読み、未設定なら汎用の既定へ落とす。`apps/zsh/fleet_monitor.py` が `FLEET=...` を環境変数で受けている形と揃う
2. **設定ファイル（`.example` 付き）に切り出す。** `digest.yml.example` と同じ流儀

**1 を採る。** 走査対象は数個のパスに過ぎず、設定ファイルを1つ増やすほどの構造ではない。`fleet_monitor.py` と受け取り方が揃うことも利点になる。加えて、本 Issue でテストを足す判断（前節）がこの設計を要求する — テストが実際のホームディレクトリに触れずに済むのは、パスを注入できるからである。

#### 置き場所

私物では `apps/lpt/core/` 配下にあるが、`lpt` の他のスクリプト（バックアップ・リモート同期・ブラウザ経由の抽出）は固有の接続情報を含むため公開しない。**このスクリプト1本だけを `apps/lpt/link_guarantees.py` に置く**（`core/` の階層は作らない。1本しか無い階層を作らない）。

`apps/zsh/` に入れない理由は、あちらが「フリート監視と digest」の置き場として `apps/zsh/README.md` で説明されており、性格が違うため。新しいディレクトリには `README.md` を1本置く（`apps/zsh/README.md` と同じ体裁、既存の文体に合わせる）。

### 仕様

#### apps/lpt/link_guarantees.py（新規）

コピー元: `~/dotfiles/apps/lpt/core/link_guarantees.py`（131行）。

処理の骨格は次のとおりで、これを変えない。

1. 走査対象を優先順位付きで順に見て、各ディレクトリ直下のリポジトリの `docs/guarantees.md` を集める。ドット始まりのディレクトリは除外する
2. リポジトリ名で束ね、同名が複数あれば優先順位で解決する。最上位が接頭辞なし、残りは走査元のディレクトリ名（ホーム直下の場合は `home`）を接頭辞に付ける
3. 前回の状態（リンク名 → パスと mtime）をキャッシュから読み、集合と mtime のどちらも変わっていなければ何もせずに終了する
4. 変化があれば集約先の symlink を全て消してから張り直し、状態をキャッシュへ書く

前節に従い、パス3つを環境変数から受け取る形に変える。`GUARANTEES_SEARCH_DIRS` は `:` 区切りで、**列挙の順序がそのまま優先順位になる**ことをコメントで明示すること（この順序が衝突解決の唯一の根拠であり、読んだだけでは分からない）。

symlink は相対パスで張る（`os.path.relpath`）。集約先ごと別の場所へ移しても壊れないようにするためで、この判断はコメントとして残っているので落とさないこと。

集約先の走査除外（`TARGET_DIR` 自身とその親）は残す。集約先を走査対象の下に置く設定にされたとき、自分が張った symlink を拾って再帰する。

#### apps/lpt/tests/test_link_guarantees.py（新規）

`tmp_path` に擬似的なディレクトリ構造（走査対象を2〜3個、その下にリポジトリを模したディレクトリ、一部に `docs/guarantees.md`）を作り、環境変数3つをそこへ向けて `main()` を呼ぶ。**実際のホームディレクトリに触れない。**

最低限カバーすること。

- 走査対象に存在しないパスが混ざっていても例外にならず、存在する分だけ拾う
- 同名リポが2つの走査対象にあるとき、`GUARANTEES_SEARCH_DIRS` で先に書いた方が接頭辞なしの名前を取り、後の方に走査元ディレクトリ名の接頭辞が付く
- 集約先を走査対象の下に置いても、自分が張った symlink を拾って再帰しない
- 2回連続で呼んだとき、2回目は symlink を張り直さない（1回目のリンクの inode / mtime が変わらないこと、または出力で判定）
- 台帳の内容を書き換えたあとに呼ぶと張り直す
- 張られるのが相対 symlink であること（`os.readlink` の結果が絶対パスでない）
- キャッシュファイルが壊れた JSON でも例外にならず再生成へ進む

`conftest.py` は要らない範囲に収める。フィクスチャが要るなら同一ファイル内に置く。

#### .github/workflows/ci.yml

既存の `nix-check` / `zsh-check` と並ぶ形で `python-check` ジョブを1つ足す。`actions/setup-python` で 3.11 を入れ、`pip install pytest` して `pytest apps/lpt/tests/` を走らせる。既存2ジョブの書式（ステップ名の付け方・アクションのバージョン指定）に合わせること。

`apps/zsh/*.py` はテストを持たないため対象に含めない。**ジョブの対象を `apps/lpt/tests/` に限定する**（`pytest` を引数なしで走らせるとテストの無いディレクトリまで収集しに行く）。

#### apps/lpt/README.md（新規）

`apps/zsh/README.md` と同じ体裁で、次を書く。既存の文体（ですます調を使わない簡潔な地の文）に合わせること。

- このディレクトリが何の置き場か（フリート横断で台帳を集約する道具）
- 環境変数3つの意味と既定値。特に `GUARANTEES_SEARCH_DIRS` は順序が優先順位であること
- 実体をコピーせず symlink を張る理由（正本は各リポに残す）
- 実行例（環境変数を渡してローカルで実行する形。`apps/zsh/README.md` の `FLEET=...` の例と同じ書式）

#### home-manager/modules/guarantees.nix（新規）

コピー元: `~/dotfiles/home-manager/modules/guarantees.nix`（10行）。

`home.activation` の `lib.hm.dag.entryAfter [ "writeBoundary" ]` でスクリプトを呼ぶ。**スクリプトが存在しない場合は何もしない**分岐を残す（`memory.nix` と同じく、activation 全体を落とさないため）。

私物版はスクリプトのパスを `$HOME/dotfiles/apps/lpt/core/link_guarantees.py` で組み立てている。置き場所の変更（`core/` を挟まない）に合わせること。

環境変数は module 側で渡さず、未設定時の既定に任せる。利用者が変えたい場合は module を上書きする形にし、**この module に option を生やさない**（10行の module に設定層を足すと、スクリプト側の環境変数と二重管理になる）。

#### devices/gui/macbook/home.nix / devices/gui/home.nix

`imports` に `guarantees.nix` を足す。`claude.nix` を imports している2箇所に合わせる。`devices/headless/home.nix` には足さない。

#### docs-agents/test-policy.md / test-policy.en.md

保証台帳の節に、フリート横断の集約について1段落足す。含めること。

- 台帳は各リポの `docs/guarantees.md` が正本で、この配置は変えない
- 複数リポを並行して回すと「今フリート全体で何を約束しているか」を一望する場所が無くなる。裁可する側が全体を見られないのは台帳の目的に反する
- rebuild のたびに走査して symlink を1箇所へ集める。実体はコピーせず、正本は各リポに残る
- 同名リポが複数の走査対象にある場合は優先順位で解決し、下位には接頭辞を付ける

**手順やコマンドを書かない。** それは `apps/lpt/README.md` が持つ。ここは「なぜ集約が要るか」だけを扱う。

### 実装順序

1. `apps/lpt/link_guarantees.py`（パスの環境変数化）
2. `apps/lpt/tests/test_link_guarantees.py` を書き、`pytest apps/lpt/tests/` が通ることを確認
3. ハードコードされたディレクトリ名が残っていないことを grep で確認
4. `.github/workflows/ci.yml` に `python-check` ジョブ
5. `apps/lpt/README.md`
6. `home-manager/modules/guarantees.nix`
7. `devices/gui/macbook/home.nix` / `devices/gui/home.nix` の imports と `nix flake check`
8. `docs-agents/test-policy.md` → `test-policy.en.md`

対象9ファイルは `new-issue` の目安（7本）を超える。1セッションで完走できない場合は、**1〜4（スクリプトとテスト）で一度止めて報告すること。** 5以降は別セッションでも成立する。
