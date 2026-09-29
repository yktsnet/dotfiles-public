[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

本リポジトリは、AI エージェントに開発を任せる個人の開発環境で、守らせたい規則を文書ではなく環境（Nix・Claude Code の deny とフック・skill）に置く形を、構成ごと公開する実例である。
チームのリポジトリへ持ち込める分は [sdlc-kit](https://github.com/yktsnet/sdlc-kit) に切り出しており、ここはその型を実際に回している環境にあたる。

---

## Verification over Generation

AI がコードを書くようになって、時間がかかるのは書くことではなく、書かれたものを信じられるか確かめることに変わった。エージェントは自信を持ったまま静かに間違え、放っておけば破壊的な操作や機密の漏洩をそのまま本番へ通す。人が気をつけるという約束は、いずれ形骸化する。

そのため、環境差の排除・破壊的なコマンドの遮断・機密の隔離はコードと設定で固定し、人間のマージを最後の関門に置いた。「何が壊れてはいけないか」だけは人間が決めて文書で承認し、実装とテストはエージェントに任せる。約束が破られれば機械が検知して止まるので、張り付いて見張らずに済む。

---

## Rules Live in the Environment

規則は置き場で分けている。毎回守らせる規則は CLAUDE.md、「〜するとき」と条件を言える手順と基準は skill、外れてはいけないものは `settings.json` の deny とフックに置く。そのうえで、どのリポジトリ、どの端末で開いても同じものが効くよう、全部を Nix で配る。

### 全端末で道具を揃える

macOS と Linux の開発機を1つの Flake で管理する。端末ごとに道具の有無や版が違うと、エージェントはコマンドが見つからない、実行時に失敗する、といった形で止まる。

| 構成 | OS | 役割 |
|---|---|---|
| `linux-desktop` | NixOS（disko / SSD） | 主開発機。相談者チャットと `issue` の起動元 |
| `macbook` | macOS（nix-darwin） | home-manager 層を Linux 機と共有する |

OS の差は、Nix 側では `pkgs.stdenv.isDarwin`、シェル側では `os.sh` のシム（`_is_darwin` / `_sed_i` / `_open` / `_linux_only`）に閉じ込め、それ以外は両 OS が同じファイルを読む。エージェントが `brew` や `npm -g` に手を伸ばすと `block-non-nix-install.sh` が止め、Nix で入れる手順（[nix-tool-install](.claude/skills/nix-tool-install/SKILL.md)）へ案内する。

### 禁止は頼まず仕組みに置く

`rebuild` 系・`flake.lock` の編集・`ssh`・機密の対応表の読み書きは deny で塞ぐ。deny は文字列の前方一致しか見ないので、`/tmp/venv/bin/pip install` のようなパス付きの実行や、`~/.claude` を `sed -i` で書き換えるような、行為として判定が要るものは [PreToolUse フック](.claude/hooks/)が受け持つ。

フックの拒否文には、止めた理由と正しい経路を両方書く。エージェントは拒否されると別の手を試し、何を試すかは拒否文で決まるので、書いた経路へそのまま進む。編集直後に1ファイルだけ構文検査する `static-check.sh` も同じ考えで作った。忘れても誰も気づかない確認を、モデルの裁量から外している。

### 規則を1か所から全セッションへ配る

`.claude/` の settings・hooks・skills と `home-manager/config/claude/common.md` が正本で、`home-manager/modules/claude.nix` が rebuild のたびに `~/.claude` へ実体コピーする。`~/.claude` 側は生成物になるので、そこを直接編集しようとすると `block-live-claude-config-edit.sh` が止め、正本のパスを返す。

規則が増えると、規則同士が食い違い始める。[consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) が、前回の棚卸し地点（`.claude/RULES.md` のアンカー1行）からの差分だけを監査する。永続メモリは `~/memory/` 直下に1ファイル1事実で置き、`memory.nix` で git の経路に乗せて端末間で揃える。

### 決める役と作る役を分ける

同じモデルが決めて作ると、方向を外したことに自分では気づけない。そのため役割を3つに分ける。

- **相談者**: user と対話して仕様と Issue を設計する。実装はしない（[new-issue](.claude/skills/new-issue/SKILL.md)）
- **実行者**: Issue を入力に、実装・テスト・ローカルコミットまでを進める。リモートには触れない（[pr-workflow](.claude/skills/pr-workflow/SKILL.md)）
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

実行者はローカルコミットで止まり、リモートへ出る経路は user の `issue-finish` しかない。`issue` は worktree を切って実行者を起動するので、複数の Issue を並行して走らせられる。実行者の変更は [crit](https://github.com/tomasz-tomczyk/crit) で行単位にレビューする。

並行するセッションの外に立つ読み手として [session-nudge](.claude/skills/session-nudge/SKILL.md) があり、別セッションへの助言は、文案を user が承認してから送る。障害対応のような即時の作業、user が明示した単発の例外、ロジックに触れない小さな変更は、Issue を立てずに通す。

### 機密を地の文に出さない

Issue・PR・コミットの地の文には、IP・ポート・実ホスト名を書かずに `<PLACEHOLDER>` を使う。実値とプレースホルダの対応表は `secrets-agents/` に置き、エージェントからは読み書きさせない。

対応表が1台にしか無いと、別の端末では何を伏せるべきか分からないまま書くことになる。対応表は sops（age）で暗号化して git で配り、各端末が自分の鍵で復号する（[sops-secrets](.claude/skills/sops-secrets/SKILL.md)）。

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

## What Ships to sdlc-kit

ここで回している型のうち、チームのリポジトリへ持ち込めるものを [sdlc-kit](https://github.com/yktsnet/sdlc-kit) に切り出している。持ち込むのは、人の判断を省かせない、セッションを超えて残す、担当者が替わっても揃う、のどれかに当たるものだけで、作業フロー、立ち上げ期の PLAN.md / JUDGE.md、リリース後の保証台帳、main を守るガードがこれにあたる。開発を2つの駆動文書で回す考え方は sdlc-kit の [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md) にある。

Nix による道具の統一、`~/.claude` の配布、対応表の復号、永続メモリは端末に紐づくので、チームのリポジトリからは効かせられない。これらはこのリポジトリに残る。

---

## What Is Not Here

稼働中の dotfiles から、エージェントとの開発に関わる層（Claude Code・メモリ・機密・レビュー・tmux のセッション管理）だけを抜き出している。エディタやデスクトップの設定、サーバー類の構成は含めていない。抜き出しであって写しではないので、稼働側にあってここに無いものがある。何を公開するかの基準は [.claude/skills/README.md](.claude/skills/README.md) に置いた。

clone して各自の端末へ適用することは想定しておらず、動かす手順も載せていない。デバイス構成は実機のハードウェアと鍵を前提にしていて、`secrets/` の暗号文も含めていないためである。CI の `nix flake check` は、公開している構成が評価できる状態にあることを確かめている。

---

## Repository Map

| パス | 中身 | 対応する節 |
|---|---|---|
| `flake.nix`・`devices/` | 開発機の NixOS / nix-darwin 構成。共通部分は `devices/common/` | 全端末で道具を揃える |
| `home-manager/modules/` | Claude Code の配布・メモリ・機密・tmux・crit。`zsh/` に Issue 駆動の関数 | 規則を1か所から全セッションへ配る・決める役と作る役を分ける |
| `.claude/settings.json`・`.claude/hooks/` | deny とフック | 禁止は頼まず仕組みに置く |
| `.claude/skills/` | 手順と基準。一覧は [.claude/skills/README.md](.claude/skills/README.md) | Rules Live in the Environment 全体 |
| `secrets-agents/` | 対応表の復号先（`example.md` はサンプル） | 機密を地の文に出さない |
| `issues/` | このリポジトリ自身の Issue と PR の控え | 決める役と作る役を分ける |
