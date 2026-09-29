[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

AI エージェントに開発を任せる個人の開発環境を、守らせたい規則ごと Nix 構成として公開したものです。
チームのリポジトリへ持ち込める分は [sdlc-kit](https://github.com/yktsnet/sdlc-kit) に切り出していて、ここはその型を実際に回している環境にあたります。

---

## From Writing to Checking

エージェントに書かせる量が増えるにつれて、自分の仕事は書くことから確かめることへ移っていった。確かめるものが増えると、確かめ方が日によって揺れる。疲れた日は見落とし、急ぐ日は手順を飛ばす。エージェントも同じで、前のセッションで守れた規則を次のセッションでは読み落とす。

そこで、守らせたいことを、頼んで守ってもらう文書から、外れようのない環境の側へ少しずつ移してきた。人にもエージェントにも、覚えていることを求めない。

---

## Rules Live in the Environment

規則は置き場で分けています。毎回守らせる規則は CLAUDE.md、「〜するとき」と条件を言える手順と基準は skill、外れてはいけないものは `settings.json` の deny とフックに置きます。そのうえで、どのリポジトリ、どの端末で開いても同じものが効くように、全部を Nix で配ります。

### One Toolchain on Every Machine

macOS と Linux の開発機を1つの Flake で管理しています。端末ごとに道具の有無や版が違うと、エージェントは「コマンドが無い」「動きが違う」で止まり、止まった理由の調査に人の時間を取られます。

| 構成 | OS | 役割 |
|---|---|---|
| `linux-desktop` | NixOS（disko / SSD） | 主開発機。相談者チャットと `issue` の起動元 |
| `macbook` | macOS（nix-darwin） | home-manager 層を Linux 機と共有する |

OS の差は、Nix 側では `pkgs.stdenv.isDarwin`、シェル側では `os.sh` のシム（`_is_darwin` / `_sed_i` / `_open` / `_linux_only`）に閉じ込め、それ以外は両 OS が同じファイルを読みます。エージェントが `brew` や `npm -g` に手を伸ばすと `block-non-nix-install.sh` が止め、Nix で入れる手順（[nix-tool-install](.claude/skills/nix-tool-install/SKILL.md)）へ案内します。

### Blocks Are Mechanisms, Not Requests

`rebuild` 系・`flake.lock` の編集・`ssh`・機密の対応表の読み書きは deny で塞いでいます。deny は文字列の前方一致しか見ないので、`/tmp/venv/bin/pip install` のようなパス付きの実行や、`~/.claude` を `sed -i` で書き換えるような、行為として判定が要るものは [PreToolUse フック](.claude/hooks/)で扱います。

フックの拒否文には、止めた理由と正しい経路を両方書きます。エージェントは拒否されると別の手を試すので、拒否文に書いた経路へそのまま進みます。編集直後に1ファイルだけ構文検査する `static-check.sh` も同じ考えで、忘れても誰も気づかない確認を、モデルの裁量から外しています。

### One Source for Every Session

`.claude/` の settings・hooks・skills と `home-manager/config/claude/common.md` が正本で、`home-manager/modules/claude.nix` が rebuild のたびに `~/.claude` へ実体コピーします。`~/.claude` 側は生成物になるので、そこを直接編集しようとすると `block-live-claude-config-edit.sh` が止め、正本のパスを返します。

規則が増えると、規則同士が食い違い始めます。[consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) が前回の棚卸し地点（`.claude/RULES.md` のアンカー1行）からの差分だけを監査します。永続メモリは `~/memory/` 直下に1ファイル1事実で置き、`memory.nix` で git の経路に乗せて端末間で揃えます。

### Deciding and Building Are Separate

同じモデルが決めて作ると、方向を外したことに自分では気づけません。役割を3つに分けています。

- **相談者**: user と対話して仕様と Issue を設計する。実装はしない（[new-issue](.claude/skills/new-issue/SKILL.md)）
- **実行者**: Issue を入力に、実装・テスト・ローカルコミットまでを進める。リモートには触れない（[pr-workflow](.claude/skills/pr-workflow/SKILL.md)）
- **user**: Issue の保証節を裁可し、コミットをレビューして公開する

受け渡しは zsh の関数で行います。`issue` が worktree を切って実行者を起動し、`issue-finish` がレビュー済みのブランチを push から PR・マージ・後片付けまで進め、`issue-abort` は worktree をブランチごと捨てます。worktree ごとに隔離されるので、複数の Issue を並行して走らせられます。実行者の変更は [crit](https://github.com/tomasz-tomczyk/crit) で行単位にレビューします。

並行するセッションの外に立つ読み手として [session-nudge](.claude/skills/session-nudge/SKILL.md) があり、別セッションへの助言を、文案を user が承認してから送ります。障害対応のような即時の作業、user が明示した単発の例外、ロジックに触れない小さな変更は、Issue を立てずに通します。

### Secrets Stay Out of the Prose

Issue・PR・コミットの地の文には、IP・ポート・実ホスト名を書かずに `<PLACEHOLDER>` を使います。実値とプレースホルダの対応表は `secrets-agents/` に置き、エージェントからは読み書きさせません。

対応表が1台にしか無いと、別の端末では何を伏せるべきか分からないまま書くことになります。対応表は sops（age）で暗号化して git で配り、各端末が自分の鍵で復号します（[sops-secrets](.claude/skills/sops-secrets/SKILL.md)）。

---

## What Ships to sdlc-kit

ここで回している型のうち、チームのリポジトリへ持ち込めるものを [sdlc-kit](https://github.com/yktsnet/sdlc-kit) に切り出しています。持ち込むのは、人の判断を省かせない、セッションを超えて残す、担当者が替わっても揃う、のどれかに当たるものだけです。作業フロー、立ち上げ期の PLAN.md / JUDGE.md、リリース後の保証台帳、main を守るガードがこれにあたります。開発を2つの駆動文書で回す考え方は sdlc-kit の [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md) にあります。

Nix による道具の統一、`~/.claude` の配布、対応表の復号、永続メモリは端末に紐づくので、チームのリポジトリからは効かせられません。これらはこのリポジトリに残ります。

---

## What Is Not Here

稼働中の dotfiles から、エージェントとの開発に関わる層（Claude Code・メモリ・機密・レビュー・tmux のセッション管理）だけを抜き出しています。エディタやデスクトップの設定、サーバー類の構成は含めていません。抜き出しであって写しではないので、稼働側にあってここに無いものがあります。何を公開するかの基準は [.claude/skills/README.md](.claude/skills/README.md) にあります。

clone して各自の端末へ適用することは想定していません。デバイス構成は実機のハードウェアと鍵を前提にしていて、`secrets/` の暗号文も含めていません。CI の `nix flake check` は、公開している構成が評価できる状態にあることを確かめています。

---

## Repository Map

| パス | 中身 | 対応する節 |
|---|---|---|
| `flake.nix`・`devices/` | 開発機の NixOS / nix-darwin 構成。共通部分は `devices/common/` | One Toolchain |
| `home-manager/modules/` | Claude Code の配布・メモリ・機密・tmux・crit。`zsh/` に Issue 駆動の関数 | One Source・Deciding and Building |
| `.claude/settings.json`・`.claude/hooks/` | deny とフック | Blocks Are Mechanisms |
| `.claude/skills/` | 手順と基準。一覧は [.claude/skills/README.md](.claude/skills/README.md) | 全節 |
| `secrets-agents/` | 対応表の復号先（`example.md` はサンプル） | Secrets |
| `issues/` | このリポジトリ自身の Issue と PR の控え | Deciding and Building |
