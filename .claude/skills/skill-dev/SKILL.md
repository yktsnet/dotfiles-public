---
name: skill-dev
description: 新しい Claude Code skill を作る・追加する・整備したくなったときの配置ルール。「スキルを作って」「これをスキルにして」「skillを追加したい」等、SKILL.md を新規に書こうとする前に必ず使用する。どこに置くか（dotfiles管理のグローバル vs リポ固有）を先に決める。
---

# skill-dev

SKILL.md を書き始める前に、置き場所を決める。

## 1. 置き場所の判断

- **複数リポで使う・リポに依存しない知識/手順**（既存の `new-issue` `pr-workflow` `jp-writing` 等と同種）
  → `~/dotfiles/.claude/skills/<name>/SKILL.md` に作成する。
  home-manager の activation script (`home-manager/modules/claude.nix`) が rebuild のたびに
  `~/.claude/skills/` へ丸ごとコピーし、それが全リポ共通のグローバル skill になる。
  **`~/.claude/skills/` に直接書いても正本ではなく、次回 rebuild で消える**
  （`block-new-skill-md.sh` フックが直接作成を拒否する）。
  反映には dotfiles 側で rebuild が必要なため、その場のセッションではまだ一覧に出ない場合がある。

- **そのリポ固有の手順・そのリポでしか意味を持たない知識**
  → 該当リポの `.claude/skills/<name>/SKILL.md` に作成する。dotfiles には置かない。

- 迷う場合は「他のリポでこの手順が使われる場面があるか」を基準にする。使われるなら global。

## 2. 作成前の重複確認

- global (`~/dotfiles/.claude/skills/`) と、作業中のリポの `.claude/skills/` の両方を検索し、
  類似 skill が無いか確認する。

## 3. frontmatter・内容の規約

`block-new-skill-md.sh` フックが Write 時に検査する。詳細はフック本体を参照。

- `name` / `description` は必須。
- 既定は `disable-model-invocation: true`（明示呼び出し専用）。
  自動発火（model invocation）させたい skill は、user に確認したうえでこの行を外す。
