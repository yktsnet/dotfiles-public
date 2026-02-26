# NixOS Workspace & Terminal Environment

A NixOS configuration and terminal workspace setup. This repository provides a reproducible computing environment across multiple devices, integrated with a customized terminal-based workflow tailored for LLM-assisted development.

<details>
<summary>🇯🇵 日本語による説明を表示する</summary>

## アーキテクチャの設計
本リポジトリは、複数のデバイス間で共通の環境を構築するためのNixOS設定と、LLMを活用した開発向けのCLI環境です。

### 1. Nix Flakesによる環境の統一
Nix Flakesの宣言的構成により、GUI開発機（T14, DeviceA）から、クラウドVPSやローカルのヘッドレスサーバー（DeviceB）に至るまで、同一の設定ソースからシステムを構築します。これにより、ハードウェア間の設定の差異を抑え、環境の再現性を確保しています。

### 2. ローカルとリモートの操作性の統合
RangerにPython拡張（`commands.py`, `ops_action.py`）を組み込み、HelixやFZFと連携させています。OSC 52エスケープシーケンスを活用してSSH経由でのクリップボード転送を処理することで、ローカルとリモートにおける操作手順を共通化しています。

### 3. LLM向けコンテキストの生成ツール
ソースコードやディレクトリ構造をLLM向けのテキストとして出力するツール（`env_txt_maker.py`）や、Nix-shellを利用してウェブ上のデータを取得する機構（`gsave`）をターミナル上に実装しています。これにより、CLI上でのプロンプト作成作業を補助します。
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

3. (Optional) For remote deployment targeting a VPS:
```bash
sudo nixos-rebuild switch --flake .#<target-host> --target-host <user>@<target-host> --use-remote-sudo
```

## Directory Structure
* `devices/`: NixOS configurations for specific hardware profiles.
    * `gui/`: Desktop environments (e.g., T14, DeviceA).
    * `headless/`: Server configurations (e.g., Hetzner VPS, DeviceB/SSD-boot).
* `home-manager/modules/`: User environment definitions that configure Ranger, Helix, Lazygit, and Tmux.
* `zsh/`: Core shell environment configurations, including FZF integration and custom scripts.
* `apps/lpt/`: Scripts for LLM context aggregation and data extraction.

## Core Features

1. **Multi-Device Configuration**
   Leverages Nix Flakes to manage settings across different hardware. Supports both rich GUI environments (ThinkPad series, DeviceA) and optimized headless server configurations (SSD-boot, remote management, DeviceB).

2. **TUI Tool Integration**
   Extends Ranger with custom Python scripts (`commands.py`, `ops_action.py`) to connect it with Helix, FZF, and Tmux. Includes OSC 52 clipboard support over SSH.

3. **LLM Context Generation Tools**
   Provides CLI tools (`env_txt_maker.py`) to format codebase content into structured text for LLM prompts, and utilizes Nix-shell environments (`gsave`) to fetch external web data.

## Tech Stack
* **System & Package Management:** NixOS, Nix Flakes, Home Manager
* **Terminal Environment:** Zsh, Ranger (Python-extended), Helix, Tmux, Lazygit
* **Automation Scripts:** Python 3.12, Bash
