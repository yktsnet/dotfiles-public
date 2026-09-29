[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

AI エージェントとの開発では、ボトルネックは生成から検証と意図伝達に移る。
本リポジトリは、その前提で組んだ個人の開発環境を、Nix 構成・ロール分離の実行機構・skill 群ごとコードとして公開する。
開発の型は、チームのリポジトリへ取り込める形に切り出して [sdlc-kit](https://github.com/yktsnet/sdlc-kit) で配っている。ここはその型を実際に回している環境である。

---

## Principles（導入順序）

通底する前提は**注意し続ける人間を前提にしない**こと。規約は読み手の集中力に依存し、集中力は疲れると落ちる。禁止は文書でなく機構に置き、CI はローカル検証と同じものを二重に回し、壊したことには壊した本人（実行者）が提出前に気づく経路を用意する。

導入は次の順に積む。

1. **作る前に型を決める** — リポの類型・README の種別・モジュールの型を判定し、以降の規定をそこから導く
2. **禁止を文書でなく仕組みに置く** — `settings.json` の deny と PreToolUse フック
3. **読まれる場面ごとに知識を置く** — 毎回効く規則は CLAUDE.md、条件を言える手順と基準は skill
4. **守る保証を先に裁可する** — 保証台帳とテスト（GDD）
5. **決める人と作る人を分ける** — 相談者・実行者・user の三役

順序には依存がある。型が決まらないと何を遮断すべきかが決まらず、遮断が無いまま知識を増やすと事故の速度だけが上がる。保証が固まる前に分業すると、実行者は何を壊してはいけないか分からないまま走る。**最小構成は 1〜3** で、公開の有無やチーム規模に関わらず要る。4〜5 は公開物を持つとき、または複数セッションで並行し始めたときに足す。

---

## Development Lifecycle（2つの駆動文書）

開発を2フェーズに分け、駆動文書を交代させる。立ち上げ期は PLAN.md / JUDGE.md（SDD）、リリース後は保証台帳 `docs/guarantees.md` とテスト（GDD）で回す。フェーズは各リポジトリの CLAUDE.md で宣言する。

考え方は sdlc-kit の [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md) にある。本リポジトリでの運用基準は [guarantee-audit/SKILL.md](.claude/skills/guarantee-audit/SKILL.md) を参照。

---

## Role Separation（ロールの分離）

上記2ワークフローの実行機構。人間、対話型AI、自律型AIエージェントの担当範囲を厳格に定義し、エージェントの編集がレビューを経ないままメインブランチや本番に及ばないようにする。

* **WebChat（設計・対話型AI）**:
  ユーザーと対話しながら、MVP期は仕様策定と設計ファイルの作成を、Issueドリブン期は調査と Issue 設計を行う。実装はしない。
* **AI Agent（実装・自律型AI）**:
  Issue ファイルをインプットとしてコード編集・テスト実装・静的エラー確認・ローカルコミットまでを自律実行し、リモートには触れない。手順は [pr-workflow](.claude/skills/pr-workflow/SKILL.md) に固定してある。`rebuild` 等の破壊的コマンドや機密へのアクセスは `.claude/settings.json` の deny で遮断し、前方一致では判定できないもの（パス付き実行のパッケージ導入、生成物への直接編集）は [`.claude/hooks/`](.claude/hooks/) の PreToolUse フックが受け持つ。
* **User（裁可・検証・人間）**:
  Issue の保証節を裁可し、エージェントのコミットをローカルでレビュー・動作確認し、`issue-finish` で公開（push・PR作成・マージ）を実行する。レビューを通った変更だけがリモートに残る。

ロール間の受け渡しは Zsh マクロで行う:

* **`issue`**: 対象 Issue を選択し、worktree を隔離作成してエージェントを起動。main を汚さず複数 Issue を並列実行できる。
* **`issue-abort`**: 進行中の worktree を作業ブランチごと破棄。
* **`issue-finish`**: レビュー済みブランチの push → PR 作成 → マージ → 後片付けを一括実行。

分離を硬直させないための例外も定義している。障害対応などのリアルタイム ops、user が明示宣言する単発例外、そしてロジックに触れない小規模変更を Issue 化なしで通す軽量経路の3経路である。

このロール分離は1本の Issue の流れを説明したものであり、実際には複数の worktree と相談者セッションが同時に走る。同じモデル・同じ規則で動くセッションは、自分が方向を外したことを自分では検出できない。外部の読み手を用意するのが `M-m`（[session-nudge](.claude/skills/session-nudge/SKILL.md)）で、送信は cross-session messaging で行うが、文案は必ず user が承認してから送る。自動で他セッションへ介入はしない。

詳細は [new-issue](.claude/skills/new-issue/SKILL.md) を参照。

---

## Foundation（自律実行の前提条件）

エージェントの自律実行は、環境・機密・知識の3点を構造的に整えてはじめて成立する。

* **Nix による環境同一性**: 環境差はエージェントの「コマンド未検出」「実行時エラー」を招く。Nix Flakes と Home Manager で macOS / Linux のツールチェーンをコードとして同一化し、CI（`nix flake check`）で継続検証する。導入経路の逸脱（`brew` / `npm -g` / `pip install`）は `.claude/hooks/block-non-nix-install.sh` が遮断する。
* **機密情報の分離**: 公開リポジトリ側のコードや Issue ファイルに本番の IP・ポート・実ホスト名を書かない。実値はローカルの `secrets-agents/` に隔離し、地の文では `<PLACEHOLDER>` を用いる。辞書は平文でローカルに置くのではなく暗号化して git 経由で配り、各デバイスが自分の鍵で復号する。1台にしか無いと、別のデバイスでは何を伏せるべきか分からないまま書くことになるため。
* **暗黙知の skill 化**: 「どのファイルをいつ AI に渡すか」が人間の暗黙知に依存すると、AI 単独で運用を再現できない。「〜するとき」と条件を言える手順は skill 化し、description に起動条件を宣言する。前節のワークフロー自体（`new-issue`・`guarantee-audit` 等）もこの形でコミットされている。置き場の基準は [skill-dev](.claude/skills/skill-dev/SKILL.md) が持つ。
* **規則の棚卸し**: CLAUDE.md も skill も memory も「人が書いた規則を AI が読む」構造であり、規則同士の矛盾を検出する仕組みを持たない。増え続ける規則を放置すると挙動が不安定になるため、[`consolidate-rules`](.claude/skills/consolidate-rules/SKILL.md) が前回の棚卸し地点（`.claude/RULES.md` のアンカー1行）からの差分だけを定期監査する。永続メモリは索引を持たせず、`~/memory/` 直下に1ファイル1事実で置く（`ls` が索引になる粒度に保つ）。

---

## Devices（管理対象）

単一の Flake が macOS と Linux の開発機を束ねる。デバイス名は公開にあたり役割ベースの総称に置き換えている。

| 構成 | OS | 役割 |
|---|---|---|
| `linux-desktop` | NixOS（disko / SSD） | 主開発機。相談者チャットと `issue()` の起動元 |
| `macbook` | macOS（nix-darwin） | home-manager 層を Linux 機と共有する |

OS の差は、Nix 側では `pkgs.stdenv.isDarwin`、シェル側では `home-manager/modules/zsh/functions/os.sh` のシム（`_is_darwin` / `_sed_i` / `_open` / `_linux_only`）に閉じ込める。home-manager モジュールと関数ファイルは両 OS が同一のものを読む。

公開しているのは、エージェントとの開発に関わる層（Claude Code・メモリ・機密・レビュー・tmux のセッション管理）に限る。エディタやデスクトップの設定、サーバー類の構成は含めていない。

---

## Skills

基準と手順は、それを使う skill が持つ。独立したガイドの MD は置かず、skill に寄せきれないもの（複数の skill が読む `repo-standardize/reference/cicd.md`、フックの書き方の `.claude/hooks/README.md`）だけを MD として残す。何を公開するかの基準は [.claude/skills/README.md](.claude/skills/README.md)。

| 領域 | skill | 持つもの |
|---|---|---|
| 型の判定 | [repo-standardize](.claude/skills/repo-standardize/SKILL.md) | リポ類型と検証手段・settings.json・CLAUDE.md と context/・ファイル衛生。CI/CD は [reference/cicd.md](.claude/skills/repo-standardize/reference/cicd.md) |
| | [repo-readme](.claude/skills/repo-readme/SKILL.md) | README の種別判定（Type A / B / C）・下限・コアメッセージ・アウトライン |
| | [module-dev](.claude/skills/module-dev/SKILL.md) | モジュール型リポの型・境界・デモ |
| | [mermaid-diagram](.claude/skills/mermaid-diagram/SKILL.md) | 図を描くかの判断・幅の制約・形と線種 |
| 知識の置き場 | [skill-dev](.claude/skills/skill-dev/SKILL.md) | 置き場の基準・自動発火の絞り方・探索の分け方 |
| | [consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) | 規則同士の矛盾・陳腐化の棚卸し |
| 保証 | [guarantee-audit](.claude/skills/guarantee-audit/SKILL.md) | テスト方針（GDD）・保証台帳の敷設と棚卸し |
| | [mvp-docs](.claude/skills/mvp-docs/SKILL.md) | 立ち上げ期の PLAN.md / JUDGE.md |
| 分業 | [new-issue](.claude/skills/new-issue/SKILL.md) | フェーズ・担当分離・例外の3経路・Issue の設計 |
| | [pr-workflow](.claude/skills/pr-workflow/SKILL.md) | 実行者の実装からローカルコミットまで |
| | [session-nudge](.claude/skills/session-nudge/SKILL.md) | 別セッションを外から客観視する相談 |
| 公開 | [readme-i18n](.claude/skills/readme-i18n/SKILL.md)・[repo-publish](.claude/skills/repo-publish/SKILL.md)・[repo-about](.claude/skills/repo-about/SKILL.md) | 英語版 README・公開手続き・About と topics |
| 前提 | [nix-tool-install](.claude/skills/nix-tool-install/SKILL.md)・[sops-secrets](.claude/skills/sops-secrets/SKILL.md)・[jp-writing](.claude/skills/jp-writing/SKILL.md) | Nix 経由の導入・機密の暗号化・日本語の文章規範 |
