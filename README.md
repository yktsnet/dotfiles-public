[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

AI エージェントとの開発では、ボトルネックはコードの生成から、検証と意図伝達へ移る。
本リポジトリは、その前提で組んだ個人の開発基盤を、Nix 構成・役割分離の実行機構・skill 群ごとコードとして公開する実例である。守らせたい規則は文書に頼まず、環境（Nix・Claude Code の deny とフック・skill）に置いている。
チームのリポジトリへ持ち込める分は [sdlc-kit](https://github.com/yktsnet/sdlc-kit) に切り出しており、ここはその型を実際に回している環境にあたる。

---

## Why

AI がコードを書くようになって、時間がかかるのは書くことではなくなった。残ったのは2つである。

1つは**検証**である。書かれたものを信じてよいか確かめることに時間がかかる。エージェントは自信を持ったまま静かに間違え、放っておけば破壊的な操作や機密の漏洩をそのまま本番へ通す。人が気をつけるという約束は、いずれ形骸化する。

もう1つは**意図伝達**である。依頼に書かれていない条件は、エージェントが推論で埋めて、動くものを仕上げてしまう。動くので、空白があったことに気づきにくい。これまで実装者の頭の中で下されていた判断を、実装の前にコードの外へ書き出して渡す必要がある。

そのため、この基盤は**注意し続ける人間を前提にしない**。環境差の排除・破壊的なコマンドの遮断・機密の隔離はコードと設定で固定し、人間のマージを最後の関門に置く。人間は「何が壊れてはいけないか」だけを決めて文書で裁可し、実装とテストはエージェントに任せる。約束が破られれば機械が検知して止まるので、張り付いて見張らずに済む。人間の仕事は、コードを書くことから約束を裁可することへ移る。

---

## Principles

仕組みは次の順で積む。後の Design の節はこの順に並べてある。

1. **作る前に型を決める** — リポの類型・README の種別・モジュールの型を判定し、以降の規定をそこから導く
2. **禁止は頼まず仕組みに置く** — `settings.json` の deny と PreToolUse フック
3. **読まれる場面ごとに知識を置く** — 毎回効く規則は CLAUDE.md、条件を言える手順と基準は skill
4. **守る約束を先に裁可する** — 保証台帳とテスト（GDD）
5. **決める役と作る役を分ける** — 相談者・実行者・user の三役

順序には依存がある。型が決まらないと、何を遮断すべきかが決まらない。遮断が無いまま知識を増やすと、事故の速度だけが上がる。保証が固まる前に分業すると、実行者は何を壊してはいけないか分からないまま走る。

**最小構成は 1〜3** で、公開の有無やチームの規模に関わらず要る。4〜5 は、公開物を持つとき、または複数のセッションを並行して回し始めたときに足す。

5つの段の下には、どの端末でも同じ道具と規則が効くこと、機密が地の文に出ないことを Foundation として敷いている。

---

## Design

### 作る前に型を決める

新しいリポは、書き始める前に型を判定する。[repo-standardize](.claude/skills/repo-standardize/SKILL.md) がリポの類型と検証手段・`settings.json`・CLAUDE.md の骨組みを、[repo-readme](.claude/skills/repo-readme/SKILL.md) が README の種別（見せる実証型・測る実験型・使わせる利用保証型）を、[module-dev](.claude/skills/module-dev/SKILL.md) がモジュール型リポの境界とデモ方式を決める。

型を先に決めるのは、以降の規則をそこから導けるようにするためである。検証手段が決まれば CI と deny の中身が決まり、README の種別が決まれば必要な節の下限が決まる。

### 禁止は頼まず仕組みに置く

`rebuild` 系・`flake.lock` の編集・`ssh`・機密の対応表の読み書きは deny で塞ぐ。deny は文字列の前方一致しか見ないので、`/tmp/venv/bin/pip install` のようなパス付きの実行や、`~/.claude` を `sed -i` で書き換えるような、行為として判定が要るものは [PreToolUse フック](.claude/hooks/)が受け持つ。

フックの拒否文には、止めた理由と正しい経路を両方書く。エージェントは拒否されると別の手を試し、何を試すかは拒否文で決まるので、書いた経路へそのまま進む。編集直後に1ファイルだけ構文検査する `static-check.sh` も同じ考えで作った。忘れても誰も気づかない確認を、モデルの裁量から外している。

### 読まれる場面ごとに知識を置く

規則は、読まれる場面で置き場を分ける。毎回守らせる規則は CLAUDE.md、「〜するとき」と条件を言える手順と基準は skill、外れてはいけないものは deny とフックに置く。「どのファイルをいつ AI に渡すか」が人の暗黙知に残っていると、AI 単独では運用を再現できない。そのため手順は skill にし、description に起動条件を宣言する。この先の節で扱うワークフロー自体（`new-issue`・`guarantee-audit` 等）も、この形でコミットされている。置き場の基準は [skill-dev](.claude/skills/skill-dev/SKILL.md) が持つ。

skill は、リポごとに答えが変わる**判断**を担うものと、一度決めれば機械的に当てはめられる**定型**を担うものに分かれる。README の書き方・モジュールの切り方・図を描くかは前者、足場・CI・保証台帳・Issue の型は後者である。多数のリポを並行して回す運用では、判断に払うコストがスループットを左右する。定型に落とせるものは定型へ寄せ、判断が要る場面にだけ人の時間を残す。

規則が増えると、規則同士が食い違い始める。CLAUDE.md も skill も永続メモリも「人が書いた規則を AI が読む」構造で、矛盾を自分では検出できない。[consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) が、前回の棚卸し地点（`.claude/RULES.md` のアンカー1行）からの差分だけを定期的に監査し、モデルの世代が変わったときはモデルに特化した規則の陳腐化も見る。永続メモリは索引を持たせず、`~/memory/` 直下に1ファイル1事実で置く（`ls` が索引になる粒度に保つ）。

### 守る約束を先に裁可する

テストは、実行者が壊したことに自分で気づくための装置である。何が壊れてはいけないか（保証）は人間が Issue の保証節で裁可し、それを実行可能な形に書き下ろすテストは実行者が書く。この分業を **Guarantee-Driven Development（GDD）** と呼んでいる。TDD がテストを先に書く規律だとすれば、GDD は約束の裁可を先に行う規律である。

裁可された保証は、各リポの保証台帳 `docs/guarantees.md` に積み上がる。台帳に載せるのは、テストに裏付けられた契約面（公開 API・CLI・外から観測できる振る舞い）の保証だけである。載っていない振る舞いは約束ではなく、予告なく変わりうる。台帳は次のように保守する。

- **敷設**: [guarantee-audit](.claude/skills/guarantee-audit/SKILL.md) が既存テストから保証を抽出し、user の裁可を経て敷く。保証すべきなのにテストが無いものは Gaps 節に分けて記録する
- **追従**: 以後は、Issue の保証節と同じ PR でテストと台帳を更新する。実行者の手順（[pr-workflow](.claude/skills/pr-workflow/SKILL.md)）は、台帳の更新漏れを実装未完了として扱う
- **範囲の一致**: 実行者はコミット前に、ステージした差分のファイル一覧が Issue の `対象` と完全に一致することを確かめる。宣言した範囲の外へ出た変更は、コミットまで届かない
- **一望**: 台帳の正本は各リポに置いたまま、台帳を持つリポへのリンクを定期実行で1枚の索引に束ねる。裁可する側が、全体で何を約束しているかを見渡せる

開発は2つのフェーズに分け、駆動文書を交代させる。方向性が固まっていない立ち上げ期は、PLAN.md（残作業）と JUDGE.md（設計判断）を育てながら直接実装する（[mvp-docs](.claude/skills/mvp-docs/SKILL.md)）。保証台帳が正式運用に上がった時点で Issue 駆動期へ移り、以後は台帳とテストで回す。フェーズは各リポの CLAUDE.md で宣言する。考え方の全体は sdlc-kit の [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md) にある。

### 決める役と作る役を分ける

同じモデルが決めて作ると、方向を外したことに自分では気づけない。そのため役割を3つに分ける。

- **相談者**: user と対話して調査し、Issue を設計する。実装はしない（[new-issue](.claude/skills/new-issue/SKILL.md)）
- **実行者**: Issue を入力に、実装・テスト・静的確認・ローカルコミットまでを進める。リモートには触れない（[pr-workflow](.claude/skills/pr-workflow/SKILL.md)）
- **user**: Issue の保証節を裁可し、コミットをレビューして公開する

```mermaid
flowchart TD
    U([user]) -->|裁可| I[issues/ の Issue]
    C([相談者]) -->|設計| I
    subgraph local [ローカルの worktree]
        I -->|issue| E([実行者])
        E --> L[ローカルコミット]
    end
    L -->|crit でレビュー| R{{user の判断}}
    R -->|issue-abort| X[ブランチごと破棄]
    subgraph remote [GitHub]
        P[PR・マージ]
    end
    R -->|issue-finish| P
```

役割の境目は zsh の関数で渡す。

- **`issue-open`**: 保証節を裁可した Issue を `draft` から `open` に上げる
- **`issue`**: `open` の Issue を選び、worktree を切って実行者を起動する。main のチェックアウトを汚さない
- **`issue-abort`**: 進行中の worktree を作業ブランチごと破棄する
- **`issue-finish`**: レビューを通ったブランチの push → PR 作成 → マージ → 後片付けを一括で行う

実行者はローカルコミットで止まり、リモートへ出る経路は user の `issue-finish` しかない。実行者の変更は、実行者のセッションの中で [crit](https://github.com/tomasz-tomczyk/crit) を開いて行単位でレビューし、指摘はそのセッションへ戻して直させる。worktree は隔離されているので機構上は並列にも回せるが、Issue は1本ずつ実装する。直列であることが、user のレビューと裁可が成り立つ条件だからである。

分離を硬直させないための例外が3つある。事前に Issue を設計できない障害対応、user が明示した単発の例外、そしてロジックにも保証台帳にも触れない小さな変更を Issue にせず通す軽量経路である。

実際には、複数の相談者セッションと worktree が同時に走る。同じモデル・同じ規則で動くセッションは、自分が方向を外したことを自分では検出できない。その外に立つ読み手が、`M-m` で起動する [session-nudge](.claude/skills/session-nudge/SKILL.md) である。別セッションのやり取りを読んで助言を起こし、文案を user が承認してから送る。自動で他セッションへ介入はしない。

---

## Foundation

### 全端末で道具を揃える

macOS と Linux の開発機を1つの Flake で管理する。端末ごとに道具の有無や版が違うと、エージェントはコマンドが見つからない、実行時に失敗する、といった形で止まる。

| 構成 | OS | 役割 |
|---|---|---|
| `linux-desktop` | NixOS（disko / SSD） | 主開発機。相談者チャットと `issue` の起動元 |
| `macbook` | macOS（nix-darwin） | home-manager 層を Linux 機と共有する |

OS の差は、Nix 側では `pkgs.stdenv.isDarwin`、シェル側では `os.sh` のシム（`_is_darwin` / `_sed_i` / `_open` / `_linux_only`）に閉じ込め、それ以外は両 OS が同じファイルを読む。エージェントが `brew` や `npm -g` に手を伸ばすと `block-non-nix-install.sh` が止め、Nix で入れる手順（[nix-tool-install](.claude/skills/nix-tool-install/SKILL.md)）へ案内する。

### 規則を1か所から全セッションへ配る

`.claude/` の settings・hooks・skills と `home-manager/config/claude/common.md` が正本で、`home-manager/modules/claude.nix` が rebuild のたびに `~/.claude` へ実体コピーする。どのリポジトリ、どの端末で Claude Code を開いても、同じ規則が効く。`~/.claude` 側は生成物になるので、そこを直接編集しようとすると `block-live-claude-config-edit.sh` が止め、正本のパスを返す。永続メモリは `memory.nix` で git の経路に乗せ、端末間で揃える。

### 機密を地の文に出さない

Issue・PR・コミットの地の文には、IP・ポート・実ホスト名を書かずに `<PLACEHOLDER>` を使う。実値とプレースホルダの対応表は `secrets-agents/` に置き、エージェントからは読み書きさせない。

対応表が1台にしか無いと、別の端末では何を伏せるべきか分からないまま書くことになる。対応表は sops（age）で暗号化して git で配り、各端末が自分の鍵で復号する（[sops-secrets](.claude/skills/sops-secrets/SKILL.md)）。

---

## Skills

基準と手順は、それを使う skill が持つ。Principles の段ごとに並べる。何を公開するかの基準は [.claude/skills/README.md](.claude/skills/README.md) にある。

| 段 | skill | 持つもの |
|---|---|---|
| 1. 型を決める | [repo-standardize](.claude/skills/repo-standardize/SKILL.md) | リポ類型と検証手段・settings.json・CLAUDE.md と context/・ファイル衛生。CI/CD は [reference/cicd.md](.claude/skills/repo-standardize/reference/cicd.md) |
| | [repo-readme](.claude/skills/repo-readme/SKILL.md) | README の種別判定・下限・コアメッセージ・アウトライン |
| | [module-dev](.claude/skills/module-dev/SKILL.md) | モジュール型リポの型・境界・デモ |
| | [mermaid-diagram](.claude/skills/mermaid-diagram/SKILL.md) | 図を描くかの判断・幅の制約・形と線種 |
| 3. 知識の置き場 | [skill-dev](.claude/skills/skill-dev/SKILL.md) | 置き場の基準・自動発火の絞り方・探索の分け方 |
| | [consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) | 規則同士の矛盾・陳腐化の棚卸し |
| 4. 約束の裁可 | [guarantee-audit](.claude/skills/guarantee-audit/SKILL.md) | テスト方針（GDD）・保証台帳の敷設と棚卸し |
| | [mvp-docs](.claude/skills/mvp-docs/SKILL.md) | 立ち上げ期の PLAN.md / JUDGE.md |
| 5. 分業 | [new-issue](.claude/skills/new-issue/SKILL.md) | フェーズ・担当分離・例外の3経路・Issue の設計 |
| | [pr-workflow](.claude/skills/pr-workflow/SKILL.md) | 実行者の実装からローカルコミットまで |
| | [session-nudge](.claude/skills/session-nudge/SKILL.md) | 別セッションを外から客観視する相談 |
| 公開 | [readme-i18n](.claude/skills/readme-i18n/SKILL.md)・[repo-publish](.claude/skills/repo-publish/SKILL.md)・[repo-about](.claude/skills/repo-about/SKILL.md) | 英語版 README・公開手続き・About と topics |
| Foundation | [nix-tool-install](.claude/skills/nix-tool-install/SKILL.md)・[sops-secrets](.claude/skills/sops-secrets/SKILL.md)・[jp-writing](.claude/skills/jp-writing/SKILL.md) | Nix 経由の導入・機密の暗号化・日本語の文章規範 |

段 2（禁止を仕組みに置く）は skill ではなく、`.claude/settings.json` と [`.claude/hooks/`](.claude/hooks/) が持つ。フックの書き方は [.claude/hooks/README.md](.claude/hooks/README.md) にある。

---

## Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| 構成管理 | Nix Flakes・home-manager | 全端末の道具と設定を1つの宣言から作れる。エージェントが端末差で止まらない |
| macOS | nix-darwin | macOS でも home-manager 層を Linux 機と共有できる |
| ディスク | disko | パーティション構成まで Nix の宣言に含められる |
| 機密 | sops-nix・age | 暗号文のまま git で配り、各端末が自分の鍵で復号できる。平文を端末間で運ばない |
| エージェント | Claude Code | `settings.json` の deny と PreToolUse フックで、禁止を文書ではなく機構として置ける |
| レビュー | crit | 実行者の差分とローカルのページを、user とエージェントが同じ入口からレビューできる |
| 受け渡し | zsh | worktree の作成から公開までを、役割の境目ごとに1コマンドにできる |
| セッション | tmux・tmux-claude-session-manager | 並行する Claude Code のセッションを渡り歩ける |

---

## sdlc-kit

ここで回している型のうち、チームのリポジトリへ持ち込めるものを [sdlc-kit](https://github.com/yktsnet/sdlc-kit) に切り出している。持ち込むのは、人の判断を省かせない、セッションを超えて残す、担当者が替わっても揃う、のどれかに当たるものだけで、作業フロー、立ち上げ期の PLAN.md / JUDGE.md、リリース後の保証台帳、main を守るガードがこれにあたる。

Nix による道具の統一、`~/.claude` の配布、対応表の復号、永続メモリは端末に紐づくので、チームのリポジトリからは効かせられない。これらはこのリポジトリに残る。

---

## Scope

稼働中の dotfiles から、エージェントとの開発に関わる層（Claude Code・メモリ・機密・レビュー・tmux のセッション管理）だけを抜き出している。稼働側の Flake は、ここに載せた2台のほかに headless のサーバーや WSL も束ね、エディタ・デスクトップの設定やフリートの状態確認も持つが、それらは含めていない。抜き出しであって写しではないので、稼働側にあってここに無いものがある。

clone して各自の端末へ適用することは想定しておらず、動かす手順も載せていない。デバイス構成は実機のハードウェアと鍵を前提にしていて、`secrets/` の暗号文も含めていないためである。CI の `nix flake check` は、公開している構成が評価できる状態にあることを確かめている。

---

## Repository Map

| パス | 中身 | 対応する節 |
|---|---|---|
| `.claude/skills/` | 手順と基準。一覧は [Skills](#skills) | Design 全体 |
| `.claude/settings.json`・`.claude/hooks/` | deny とフック | 禁止は頼まず仕組みに置く |
| `home-manager/modules/` | Claude Code の配布・メモリ・機密・tmux・crit。`zsh/` に Issue 駆動の関数 | 決める役と作る役を分ける・規則を1か所から全セッションへ配る |
| `issues/` | このリポジトリ自身の Issue と PR の控え | 決める役と作る役を分ける |
| `flake.nix`・`devices/` | 開発機の NixOS / nix-darwin 構成。共通部分は `devices/common/` | 全端末で道具を揃える |
| `secrets-agents/` | 対応表の復号先（`example.md` はサンプル） | 機密を地の文に出さない |
