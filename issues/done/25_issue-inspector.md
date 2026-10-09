## 実行者の判定を検収役へ移し、user の確認を使い心地と実機に絞る
id: 25
branch-slug: issue-inspector
status: close
type: feat
対象:
- .claude/agents/issue-inspector.md（新規）
- .claude/agents/screen-operator.md（新規）
- .claude/skills/pr-workflow/SKILL.md
- .claude/skills/local-issue/SKILL.md（「運用の前提」の user の担当・実行者の境界）
- .claude/skills/local-issue/reference/issue-template.md（`確認` と `人が見るもの`）
- home-manager/modules/claude.nix（`.claude/agents/` を `~/.claude/agents/` へ配る）
- docs/issue-workflow.md（「実行者のセッションでやること」）
内容: 実行者は自分の書いたテストと確認で自分の実装を判定し、user は実行者のセッションで動作確認をしている。作った者は自分の意図どおりに読むので、約束から外れたところが見えない。稼働側では、判定を検収役の subagent に移し、user の確認を使い心地と、エージェントが実行できない確認（rebuild・deploy・実機）に絞った。分ける軸は書いて渡せるかで、挙動は書いて渡せるので AI が確かめ、使い心地は AI が意図や感覚を持ちにくく、人が言葉にしても渡しきれないので人に残す。公開側の skill と文書を、稼働側のこの形に合わせる（`.claude/skills/README.md`「点検のしかた」）。
対象外: README.md・README.en.md・CLAUDE.md・skill-dev・`.claude/skills/README.md`（26 で扱う）。稼働側の変更。zsh 関数 `i` の挙動。
仮定: 公開側の `claude.nix` は `.claude/agents/` を配っていないので、稼働側と同じく配る行を足す。2つの agent の定義は稼働側から写し、ホスト名・固有のパス・会社の事情が混ざっていれば一般化する（`.claude/skills/README.md`「公開の基準」）。
確認: `nix-instantiate --parse home-manager/modules/claude.nix` が通る。`nix flake check` が通る。対象の skill と agent が稼働側（`~/dotfiles/.claude/`）と一致するか、差が一般化した箇所だけであることを `diff` で示す。`grep -rn 動作確認 .claude/skills docs` に、user に挙動の照合を頼む記述が残っていない。新しい2つの agent にホスト名・会社名・固有のパスが無い。
人が見るもの: rebuild のあとに `~/.claude/agents/` に2つの定義が届いていること（実機）。

---

### 保証
- 新たに宣言する保証: rebuild のあと、`.claude/agents/` の定義が `~/.claude/agents/` に実体コピーで置かれる（skills・hooks と同じ扱い）
- 維持する保証: `~/.claude` 配下の settings・CLAUDE.md・skills・hooks の配り方は変わらない

### .claude/agents/issue-inspector.md・screen-operator.md
稼働側の同名ファイルを写す。

- `issue-inspector`：Issue ファイルと worktree のパスだけを受け取り、`確認` の項目・保証節のテスト・範囲（`対象`・`対象外`・`仮定`）を自分で動かして判定する。rebuild・deploy・実機が要る項目は「判定できない」として、user が何をすれば確かめられるかを返す。書き込みはしない
- `screen-operator`：ヘッドレスのブラウザで渡された道順を操作し、見えたものと画面写真を返す。合否は判定しない。user に見せるのは呼んだ側が `crit-live` で行う

### .claude/skills/pr-workflow/SKILL.md
稼働側に合わせる。差分は description・前提の段落・手順4（画面に出る変更は `screen-operator` で確かめる）・手順8（crit の前に `issue-inspector` に検収させる。渡すのは Issue と worktree のパスだけ）・手順9（`Inspection:` に検収の表、`Verify:` に user に残る確認だけ）・手順10（直したら検収を受け直す）・手順11（PR 本文に `## 検収`）。

### .claude/skills/local-issue/SKILL.md・reference/issue-template.md
稼働側に合わせる。user の担当を「保証節の裁可・使い心地の判断・デプロイ・サービス再起動・実機での確認・マージ」にし、Issue の型の `確認` を検収役の基準として書き直し、`人が見るもの` の欄を足す。

### home-manager/modules/claude.nix
activation script で、`agents` を `settings.json`・`skills`・`hooks` と同じく消してから実体コピーする。稼働側の `claude.nix` と同じ形にする。

### docs/issue-workflow.md
「実行者のセッションでやること」を、検収 → crit → `Inspection:` と `Verify:` を見る（挙動は照合しない）→ 直す → PR、の順に書き直す。稼働側の同じ節に合わせる。
