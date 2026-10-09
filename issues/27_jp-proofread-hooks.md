## 書いた日本語の校正を、フックが会話の外で subagent に回す
id: 27
branch-slug: jp-proofread-hooks
status: open
type: feat
対象:
- .claude/agents/jp-proofreader.md（新規）
- .claude/hooks/jp-proofread-stop.sh（新規）
- .claude/hooks/jp-proofread-run.sh（新規）
- .claude/hooks/jp-proofread-notice.sh（新規）
- .claude/hooks/tests/jp-proofread-stop.test.sh・jp-proofread-run.test.sh・jp-proofread-notice.test.sh（新規、3本）
- .claude/hooks/tests/aiagent-wt-clean.test.sh（新規。`i` の待ちを固定する）
- .claude/settings.json（Stop と UserPromptSubmit への登録）
- home-manager/modules/zsh/functions/aiagent.sh（worktree を畳む前に校正の終わりを待つ）
内容: 稼働側では、会話で書き換えた日本語の文書を、Stop フックが会話の外で校正の subagent（`jp-proofreader`）に渡している。書き手と別の文脈で規範を当てるためで、Agent ツールで呼ばせないのは、起動と完了のたびに会話側のモデルのターンを起こさないためである。結果は次に user が話しかけたターンで notice フックが渡す。subagent を skill で頼まずに、フックという仕組みで回している実例で、公開側には無い。稼働側に合わせて公開する（`.claude/skills/README.md`「点検のしかた」）。
対象外: README.md・README.en.md（29 で扱う）。`no-branch-in-checkout`・`gate-memory-write` とモデルの ID（28 で扱う）。jp-writing の規範の中身。
仮定: 対象が目安の7本を超えるが、フックとテストが対になっていて、確認もテストの実行の1種類なので分けない。`jp-proofread-run.sh` は会社のリポに応じて config dir を切り替える分岐を持つが、公開側では `CLAUDE_CONFIG_DIR` が設定されていればそれを、無ければ既定を使う形に一般化する。`jp-proofread-stop.sh` の対象外のパスから、会社の config dir を外す。
確認: `for t in .claude/hooks/tests/*.test.sh; do bash "$t"; done` がすべて通る。`zsh -n home-manager/modules/zsh/functions/aiagent.sh` が通る。`nix flake check` が通る。`jq . .claude/settings.json` が通る。追加したファイルに、会社名・会社の config dir・ホスト名が無い。agent と3つのフックが稼働側と一致するか、差が一般化した箇所だけであることを `diff` で示す。
人が見るもの: rebuild のあと、日本語の .md を書き換えた会話で、次のターンに校正の結果が届くこと（実機）。

---

### 保証
- 新たに宣言する保証:
  - 会話で書き換えた日本語の .md は、Stop のたびに、変わった行の範囲だけが会話の外で校正に回る。変わった行に日本語が無ければ起動しない
  - 校正の結果は、次に user が話しかけたターンで会話に渡る
  - `i` は、その worktree の校正が走り終わるまで worktree を畳まない（上限を過ぎたら畳まずに知らせる）
- 維持する保証: 既存のフックの判定（`route-browser-to-crit` ほか）は変わらない

### .claude/agents/jp-proofreader.md
稼働側の定義を写す。モデルは ID（`claude-sonnet-5-5`）で固定したまま、Write・Glob・Grep を持たせない理由のコメントも残す。

### .claude/hooks/jp-proofread-*.sh とテスト
稼働側の3本とテスト3本を写し、上の「仮定」のとおり会社の分岐を一般化する。テストが会社の分岐を前提にしていれば、一般化した形に合わせて直す。

### .claude/settings.json
Stop に `jp-proofread-stop.sh`、UserPromptSubmit に `jp-proofread-notice.sh` を、稼働側と同じ timeout と statusMessage で登録する。

### home-manager/modules/zsh/functions/aiagent.sh
worktree を畳んでよいかの判定の前に、稼働側と同じく、その worktree を対象に走っている校正の印を見て、終わるまで待つ。
