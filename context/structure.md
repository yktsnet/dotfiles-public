# dotfiles-public ディレクトリ構造

どこに何があるか。コードの書き方（規約）は `conventions.md` を参照。
本ファイルは「このリポジトリ自体」の構造を示す。

## トップレベル

```
dotfiles-public/
├── flake.nix          # Flake エントリ（inputs: nixpkgs / home-manager / nix-darwin / disko ほか）
├── flake.lock         # 入力のロック（編集しない）
├── devices/           # デバイス別の NixOS / nix-darwin 構成
│   ├── common/        # Linux 開発機の共通 system.nix / home.nix
│   ├── linux-desktop/
│   ├── macbook/
│   └── secrets.nix / ssh.nix / flake-edit.nix
├── home-manager/      # ユーザ環境
│   ├── config/        # 配置する設定ファイル（Claude Code の共通指示）
│   └── modules/       # 再利用モジュール（zsh/ に Issue 駆動のシェル関数）
├── .claude/
│   ├── settings.json  # 権限（allow/deny）・attribution・フックの配線
│   ├── hooks/         # PreToolUse / SessionStart フック（deny で判定できない遮断・注入）
│   └── skills/        # ワークフロー用スキル（正本。home-manager が ~/.claude/skills へ配置）
├── secrets/           # sops で暗号化した secret（実体は追跡しない）
├── secrets-agents/    # マスク辞書の復号先（example.md のみ追跡するサンプル）
├── context/           # 本リポの Agent 向けコンテキスト（本ファイル群）
└── issues/            # ローカル Issue 管理（done/ に PR 控え）
```

## レイヤー構成

- **Flake 層**: `flake.nix` が全デバイス構成と home-manager を束ねるエントリ。
- **デバイス層**: `devices/`。共通部分は `common/`、デバイスごとの差分は `<device>/` に置き、共通モジュールを import。
- **ユーザ環境層**: `home-manager/`。エージェント関連（Claude Code・メモリ・機密・tmux のセッション管理等）を宣言的に管理。
- **ワークフロー層**: `home-manager/modules/zsh/functions/`。`issue` / `issue-abort` / `issue-finish` 等のマクロ。
- **ハーネス層**: `.claude/`。`settings.json` の deny（前方一致で足りるもの）と `hooks/` の PreToolUse（コマンド構造・編集先の判定が要るもの）で遮断を二段に分ける。`skills/` が正本で、`home-manager/modules/claude.nix` が `~/.claude/` へ配置する。
- **基準と道具**: 判断の基準と、それを実行するスクリプトは、使う skill が持つ（`sops-secrets/scripts/inject.py`、`guarantee-audit/reference/guarantees-index/` 等）。規則の置き場の分け方は README の Design 節。公開の基準は `.claude/skills/README.md`。
- **機密層**: `secrets/` が暗号文、`secrets-agents/` が各機で復号したマスク辞書。どちらも Agent からは読み書きしない。

## issues/

- `{NN}_{slug}.md`: 実装対象 Issue。`status: open` のものを Agent が処理し、完了後も `status: close` で残る。
- `done/`: マージした PR の記録。`issue-finish` が PR のタイトル・URL・本文を Issue と同名のファイルで書き出す。
