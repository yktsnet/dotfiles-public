## .claude/ を稼働側に追従させる（skill・hook・settings）
id: 29
branch-slug: claude-sync
status: close
parent: dotfiles-fe
type: cleanup
対象: .claude/settings.json, .claude/RULES.md（削除）, .claude/hooks/backup-secret-json.sh（削除）, .claude/hooks/block-project-scoped-memory.sh, .claude/hooks/block-live-claude-config-edit.sh, .claude/hooks/tests/block-live-claude-config-edit.test.sh（新規）, .claude/hooks/statusline.sh, .claude/skills/memory-write/SKILL.md（新規）, .claude/skills/README.md, .claude/skills/consolidate-rules/SKILL.md, .claude/skills/pr-workflow/SKILL.md, .claude/skills/sops-secrets/SKILL.md
内容: 公開の基準（`.claude/skills/README.md`）に従い、公開側の `.claude/` を稼働側 `~/dotfiles/.claude/` に追従させる。稼働側で外したものを外し、稼働側で進んだものを取り込み、公開側から参照だけされている `memory-write` を切り出す。
対象外: zsh・home-manager の追従（30）。`gate-memory-write.sh`・`jp-proofread-run.sh`・`nix-tool-install`（公開側が新しいか、差が会社面だけのもの）。sops-secrets の references/
仮定: 公開側にも `Read(secrets/**)` と `Edit(secrets/**)` の deny を足す（フックを外すだけだと、JSON の暗号文を Agent が守りなしに編集できる状態が残るため）。consolidate-rules の「英語版は棚卸しの対象にしない」は公開側にだけ英語版があるので残す
確認: 対象ファイルごとに稼働側との diff を取り、残る差が下の「持ち込まない差」だけになる。`backup-secret-json`・`RULES.md`・`sync-memory-index` の grep が issues/done/ 以外で0件。`jq . .claude/settings.json` が通る。`for t in .claude/hooks/tests/*.test.sh; do bash "$t"; done` が全て通る
人が見るもの: なし

---

### 保証
- 新たに宣言する保証:
  - Agent は `secrets/` 配下を読めず、編集もできない（deny で止まる）
  - `~/.claude/` の配布物への直接編集は、ヒアドキュメントの本文に配布先のパスが書かれているだけなら止めない。リダイレクト先が配布先なら止める
  - `~/.claude/projects/*/memory/` へは Bash 経由でも書き込めない
- 維持する保証: ほかのフックの配線とテストの結果は変わらない
- 廃止する保証: `secrets/**/*.json.age` を Edit / Write する直前に、タイムスタンプ付きのバックアップが残る

### 持ち込まない差（全ファイル共通）
公開の基準のとおり、稼働側を一般化した写しにする。
- `~/dotfiles/...` の絶対パス → 本リポの相対パス
- 会社面: `~/.claude-corp`、`~/github-corp/`、会社アカウントの分岐
- 個人の運用: 稼働側だけにある skill・アプリ（`apps/claude-usage` への使用率の記録など）、ホスト名、`fleet.md`
- 稼働側の settings.json にある個人の値（model・effort・plugin・allow の追加分）

### 外すもの
- `backup-secret-json.sh` とその PreToolUse の配線。sops-secrets の「JSON だけ Read/Edit/Write を許す」例外は、稼働側と同じく `secrets/` は Agent から読み書きしない、にする
- `.claude/RULES.md`

### 稼働側の本文に置き換えるもの
- consolidate-rules: アンカー方式をやめて毎回全件を読む形（フェーズと観点の番号も稼働側に合わせる）
- pr-workflow: 手順8〜11の crit の段取り（手順9で crit を開き直す、指摘の無い Finish Review を PR を出す明示とみなす）
- block-project-scoped-memory: Bash も対象にし、廃止した `sync-memory-index.sh` への言及を消す
- block-live-claude-config-edit: `agents/` を対象に足す、ヒアドキュメントの本文を判定から外す。テストも稼働側から持ち込む（会社面のケースは外す）
- statusline: worktree でも元のリポ名を出す、effort を出す、tmux のペインタイトルから会話のタイトルを出す

### 切り出すもの
- memory-write: 稼働側の `SKILL.md` を一般化して置く。書き場の表にある実値の置き場（`~/dotfiles/secrets-agents/`）とフリートの例は、本リポの `secrets-agents/` と一般的な例に直す。`.claude/skills/README.md` の一覧の「前提」行に足す
