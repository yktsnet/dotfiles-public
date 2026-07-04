# CLAUDE.md

@context/conventions.md
@context/structure.md

Claude Code は本ファイルを最優先の指示として実行すること。

## 動作フロー
- 起動時に `issues/` 内の対象 Issue（`status: open`）を確認する。
- 実装開始前に `context/conventions.md` と `context/structure.md` を読み、規約と構造を把握する。
- ローカル環境にて `claude/{id}-{branch-slug}` ブランチ上で作業していることを認識する。
- 実装・検証・PR 作成はグローバルの `pr-workflow` スキル（`~/.claude/skills/pr-workflow/SKILL.md`）の手順に従う。

## コマンド
- Flake 評価チェック: `nix flake check`
- フォーマット: `nix fmt`
- Zsh 構文チェック: `zsh -n zsh/functions/<file>.zsh`

## アーキテクチャの要点
- Nix Flakes で macOS（nix-darwin）〜 ヘッドレス VPS（NixOS）を一元管理する。
- デバイス定義は `devices/`（`gui/` と `headless/`）、ユーザ環境は `home-manager/`（`config/` と `modules/`）。
- Issue 駆動の役割分離ワークフローを支える Zsh マクロは `zsh/functions/`。
- 機密の実値は `secrets-agents/` に分離し、公開リポには載せない（読み書き禁止）。

## 検証手段
- PR 前の Agent 側確認は `nix flake check`（評価エラーの検出）と `zsh -n`（構文チェック）まで。
- 実適用（`nixos-rebuild` / `darwin-rebuild` / `home-manager switch`）は user が各デバイスで実施。手順は PR の `## 検証手順` に記載する。

> 禁止・強制（rebuild 系・flake.lock 編集・secrets 読み書き・git push 等の遮断）は `.claude/settings.json` の deny で管理する。本ファイルには書かない。
