## PR記録: feat: 書いた日本語の校正を、Stop フックが会話の外で subagent に回す
issue: 27 (27_jp-proofread-hooks.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/86

## 変更内容
- `.claude/agents/jp-proofreader.md`: 日本語 .md の表現だけを校正する役。稼働側の定義を写した（モデルは ID 固定、Write・Glob・Grep を持たせない理由のコメント付き）
- `.claude/hooks/jp-proofread-stop.sh`: Stop で、会話が書き換えた日本語の .md の変わった行の範囲だけを、会話の外で校正に回す
- `.claude/hooks/jp-proofread-run.sh`: 校正役のヘッドレス実行の本体。config dir は `CLAUDE_CONFIG_DIR` があればそれを、無ければ `~/.claude` を使う形に一般化した
- `.claude/hooks/jp-proofread-notice.sh`: UserPromptSubmit で、校正の結果を次のターンに渡す
- `.claude/settings.json`: Stop と UserPromptSubmit に登録（timeout・statusMessage は稼働側と同じ）
- `aiagent.sh`: `_aiagent_wt_clean` が、その worktree を対象に走っている校正の印を見て、終わるまで待つ（上限180秒、超えたら畳まずに知らせる）
- テスト: `jp-proofread-{stop,run,notice}.test.sh` に加え、`i` の待ちを固定する `aiagent-wt-clean.test.sh` を足した。run のテストは、校正の結果の中身（成功時・失敗時）も照合する

## 保証
- 変わった行の範囲だけが会話の外で校正に回る。日本語が無ければ起動しない → `jp-proofread-stop.test.sh`
- 校正の結果は次の user のターンで渡る → `jp-proofread-run.test.sh`（結果の中身）、`jp-proofread-notice.test.sh`（渡し方）
- `i` は校正が走り終わるまで worktree を畳まない（上限を過ぎたら畳まずに知らせる） → `aiagent-wt-clean.test.sh`
- 既存のフックの判定は不変 → `route-browser-to-crit.test.sh`

## 静的確認結果
- `.claude/hooks/tests/*.test.sh` 5本すべて通過、`zsh -n aiagent.sh` 通過、`nix flake check` 通過、`jq . .claude/settings.json` 通過
- 追加したファイルに会社名・会社の config dir・ホスト名は無い
- 稼働側との `diff`: 差は config dir の分岐の一般化（run）、除外パスから `.claude-corp` を外した1行（stop）、それに合わせた run のテストのみ

## 検証手順
rebuild のあと、日本語の .md を書き換えた会話で、次のターンに校正の結果が届くことを確かめる（実機）。登録は `$CLAUDE_PROJECT_DIR/.claude/hooks/...` を指すので、このリポ以外の会話でも動くかも併せて見る。

## 検収
| 確認 | 判定 |
|---|---|
| テスト5本、`zsh -n`、`nix flake check`、`jq` | 合 |
| 会社名・会社の config dir・ホスト名が無い | 合 |
| agent とフック3本が稼働側と一致（差は一般化した箇所だけ） | 合 |

| 保証 | 判定 |
|---|---|
| 変わった行の範囲だけが校正に回る。日本語が無ければ起動しない | 合 |
| 校正の結果は、次のターンで会話に渡る | 合 |
| `i` は校正が走り終わるまで worktree を畳まない | 合 |
| 既存のフックの判定は変わらない | 合 |

範囲の外: `aiagent-wt-clean.test.sh` を Issue の対象に足した（user が承認）。

---

## 書いた日本語の校正を、フックが会話の外で subagent に回す
id: 27
branch-slug: jp-proofread-hooks
status: close
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
