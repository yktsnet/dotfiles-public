# Declarative Multi-Node Workspace & AI-Native Terminal IDE

A production-grade NixOS configuration and terminal workspace architecture. This repository provides a highly deterministic computing environment that scales from stateless network-booted edge nodes to full GUI development machines, integrated with a custom-built, AI-centric terminal IDE.

<details>
<summary>🇯🇵 日本語による説明を表示する</summary>

## アーキテクチャの設計思想
本リポジトリは、ハードウェアの境界を越えたインフラの抽象化と、AIベースの開発サイクルに最適化されたCLIワークフローの統合実装テンプレート。

### 1. 決定論的デプロイによる環境差異の完全な排除
Nix Flakesの宣言的構成により、極端に異なるハードウェアプロファイル間の環境差異を完全に吸収。GUI開発機（ThinkPad T14）からクラウド上のヘッドレスVPS、高度なステート管理が要求されるディスクレスのネットブートノードに至るまで、単一の情報源からシステムを構築し、設定のドリフト（乖離）を許容しない完全な再現性を担保。

### 2. ローカルとリモートの境界を消失させる統合操作系
RangerをPython拡張（`commands.py`, `ops_action.py`）によって単なるファイルマネージャから「実行ハブ」へと再定義し、Helix（LSPエディタ）やFZFと密結合。OSC 52エスケープシーケンスを活用してSSH越しのクリップボード転送を透過的に処理することで、ローカルとリモートの操作上の境界を排除し、コンテキストスイッチによる思考の中断を防ぐ。

### 3. LLMとの協業コストを極小化する動的コンテキスト生成
コードベースの状態をLLMが解釈可能な構造化テキストとして動的にシリアライズするコンテキスト生成ツール（`env_txt_maker.py`）や、Nix-shellを利用してウェブ上のデータをスクレイピングする機構（`gsave`）をターミナル上にネイティブ実装。これにより、GUIブラウザへの不要な画面遷移を削ぎ落とし、CLI上で完結するAI駆動開発サイクルを実現。
</details>

## Getting Started

This repository is designed to be cloned directly to `~/dotfiles` to ensure path consistency across internal scripts and configurations.

### Prerequisites
* NixOS installed
* Nix Flakes enabled

### Installation

1. Clone the repository to the required path:
```bash
git clone [https://github.com/yktsnet/dotfiles-public.git](https://github.com/yktsnet/dotfiles-public.git) ~/dotfiles
cd ~/dotfiles
```

2. Deploy the configuration for your specific host (e.g., t14 or het):
```bash
sudo nixos-rebuild switch --flake .#<host>
```

3. (Optional) For remote deployment targeting a VPS or Edge node:
```bash
sudo nixos-rebuild switch --flake .#<target-host> --target-host <user>@<target-host> --use-remote-sudo
```

## Directory Structure
* `devices/`: Declarative NixOS configurations handling hardware-specific abstractions (T14, headless Hetzner VPS, netboot configurations).
* `home-manager/modules/`: User environment definitions that bind Ranger, Helix, Lazygit, and Tmux into a cohesive IDE orchestration layer.
* `zsh/`: Core shell environment embedding FZF workflows, custom path history tracking, and OSC 52 dynamic routing.
* `apps/lpt/`: AI-augmented toolkit for automated LLM context aggregation and ephemeral data extraction.

## Core Architectural Value

1. **Stateless & Multi-Node Provisioning**
   Leverages Nix Flakes to achieve absolute determinism across drastically different hardware profiles. The configuration abstracts hardware complexities to deploy a unified logical environment from a single source of truth.

2. **TUI Orchestration as an IDE**
   Extends Ranger with custom Python bindings (`commands.py`, `ops_action.py`) to transform the file manager into a central execution hub tightly coupled with Helix, FZF, and Tmux. Includes transparent OSC 52 clipboard routing over SSH.

3. **Dynamic LLM Context Pipeline**
   Integrates custom CLI tools (`env_txt_maker.py`) to automatically serialize entire codebase states into structured contexts for LLM ingestion, and utilizes ephemeral Nix-shell environments (`gsave`) to dynamically process external web data.

## Tech Stack
* **Infrastructure as Code:** NixOS, Nix Flakes, Home Manager
* **Terminal IDE Nexus:** Zsh, Ranger (Python-extended), Helix, Tmux, Lazygit
* **Automation & Context Pipeline:** Python 3.12 (Playwright, Pandas), Bash
